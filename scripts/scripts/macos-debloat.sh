#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# macos-debloat.sh
# Interactive, transparent, idempotent macOS cleanup for macOS 26+
#
# Behavior:
# - Prompts user for DRY-RUN first (recommended).
# - After DRY-RUN, asks whether to APPLY.
# - Requests sudo password only if needed (Time Machine snapshots, DNS flush, Spotlight reindex, system logs).
# - Avoids risky/low-value actions: no .lproj deletion inside apps, no "purge" memory, no blanket ~/Library/Caches wipe.
#
# Idempotency:
# - Safe to rerun. Deleting already-missing targets is a no-op.
# - Time Machine thinning/deleting is safe to rerun (may do nothing if no snapshots).
#
# Notes:
# - Some actions may require "Full Disk Access" for Terminal.
# - Default choices are conservative; user can opt in to more aggressive options interactively.

LOG_FILE="/tmp/macos-debloat.$(date +%Y%m%d-%H%M%S).log"
DRY_RUN=1
NEED_SUDO=0

# ---------- helpers ----------
log() { printf "%s %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE" >/dev/null; }
warn() { log "WARN: $*"; }
die() { log "ERROR: $*"; exit 1; }

need_cmd() { command -v "$1" >/dev/null 2>&1; }
is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }

human_df() { df -h / | tail -n 1 | awk '{print "Disk: used=" $3 " free=" $4 " (" $5 " used)"}'; }

# y/N prompt
ask_yn() {
  local prompt="$1"
  local default_no="${2:-1}" # 1 => default No, 0 => default Yes
  local ans=""
  while true; do
    if [[ "$default_no" -eq 1 ]]; then
      read -r -p "$prompt [y/N]: " ans
      ans="${ans:-N}"
    else
      read -r -p "$prompt [Y/n]: " ans
      ans="${ans:-Y}"
    fi
    case "${ans,,}" in
      y|yes) return 0 ;;
      n|no) return 1 ;;
      *) echo "Please answer y or n." ;;
    esac
  done
}

# Determine target user/home even if script is run via sudo
get_target_user_and_home() {
  local user home
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    user="$SUDO_USER"
  else
    user="$(id -un)"
  fi

  if need_cmd dscl; then
    home="$(dscl . -read "/Users/$user" NFSHomeDirectory 2>/dev/null | awk '{print $2}' || true)"
  fi
  if [[ -z "${home:-}" ]]; then
    home="$HOME"
  fi

  echo "$user|$home"
}

# If we need sudo, ask once and keep-alive during run
ensure_sudo() {
  if [[ "$NEED_SUDO" -eq 0 ]]; then
    return 0
  fi
  log "Requesting sudo privileges for selected actions..."
  if [[ "$DRY_RUN" -eq 1 ]]; then
    # In dry-run we still may want to validate sudo works if user chose sudo actions,
    # but do not force it. Ask politely.
    if ask_yn "Some selected actions require sudo. Do you want to authenticate sudo now to confirm it will work?" 1; then
      sudo -v
      keep_sudo_alive &
      SUDO_KEEPALIVE_PID=$!
    else
      warn "Skipping sudo authentication in dry-run. Apply run may ask for sudo."
    fi
  else
    sudo -v
    keep_sudo_alive &
    SUDO_KEEPALIVE_PID=$!
  fi
}

keep_sudo_alive() {
  while true; do
    sudo -n true >/dev/null 2>&1 || exit 0
    sleep 60
  done
}

cleanup_keepalive() {
  if [[ -n "${SUDO_KEEPALIVE_PID:-}" ]]; then
    kill "$SUDO_KEEPALIVE_PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup_keepalive EXIT

# Safe rm -rf wrapper (idempotent)
rm_rf() {
  local path="$1"
  # allow globs: caller should expand; protect if empty
  if [[ -z "$path" ]]; then
    return 0
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[DRY] rm -rf -- \"$path\""
    return 0
  fi
  # If glob didn't match, it may remain literal; handle gracefully
  if [[ "$path" == *"*"* || "$path" == *"?"* || "$path" == *"["* ]]; then
    # let shell expand earlier; if here, it's literal; no-op
    log "Skipping non-expanded glob: $path"
    return 0
  fi
  if [[ ! -e "$path" ]]; then
    return 0
  fi
  log "rm -rf -- \"$path\""
  rm -rf -- "$path"
}

find_delete_files_older_than_days() {
  local base="$1"
  local days="$2"
  if [[ ! -d "$base" ]]; then
    return 0
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[DRY] Would delete files older than $days days in: $base"
    find "$base" -type f -mtime +"$days" -print | sed 's/^/[DRY] would delete: /' | tee -a "$LOG_FILE" >/dev/null || true
  else
    log "Deleting files older than $days days in: $base"
    find "$base" -type f -mtime +"$days" -delete
  fi
}

find_delete_top_level_dirs_older_than_days() {
  local base="$1"
  local days="$2"
  if [[ ! -d "$base" ]]; then
    return 0
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[DRY] Would delete top-level dirs older than $days days in: $base"
    find "$base" -mindepth 1 -maxdepth 1 -type d -mtime +"$days" -print | sed 's/^/[DRY] would delete dir: /' | tee -a "$LOG_FILE" >/dev/null || true
  else
    log "Deleting top-level dirs older than $days days in: $base"
    find "$base" -mindepth 1 -maxdepth 1 -type d -mtime +"$days" -print0 | xargs -0 -I {} rm -rf -- "{}" || true
  fi
}

# ---------- actions ----------
ACTION_EMPTY_TRASH=0
ACTION_USER_LOGS=1
ACTION_SYSTEM_LOGS=0
ACTION_USER_CACHES_TARGETED=1
ACTION_IOS_BACKUPS=1

ACTION_BREW_CLEANUP=0
ACTION_DEV_CLEAN=0
ACTION_PKG_CACHES=0

ACTION_TM_THIN=0
TM_THIN_GB=15
ACTION_TM_DELETE_ALL=0

ACTION_DNS_FLUSH=0
ACTION_SPOTLIGHT_REINDEX=0

cleanup_user_logs() {
  local home="$1"
  find_delete_files_older_than_days "$home/Library/Logs" 30
}

cleanup_system_logs() {
  # conservative: only /Library/Logs, not /var/log, and may be SIP-restricted
  find_delete_files_older_than_days "/Library/Logs" 30
}

cleanup_ios_backups() {
  local home="$1"
  local backup_dir="$home/Library/Application Support/MobileSync/Backup"
  log "iOS backups: removing backup folders older than 180 days (top-level only)."
  find_delete_top_level_dirs_older_than_days "$backup_dir" 180
}

cleanup_user_caches_targeted() {
  local home="$1"
  log "User caches: targeted cleanup of common safe caches (no blanket wipe)."
  rm_rf "$home/Library/Caches/com.apple.Safari/WebKitCache"
  rm_rf "$home/Library/Caches/com.apple.Safari/fsCachedData"
  rm_rf "$home/Library/Caches/com.apple.WebKit.Networking"
  rm_rf "$home/Library/Caches/Homebrew"
}

empty_trash() {
  local home="$1"
  log "Emptying user Trash..."
  # Use glob carefully; if empty, zsh-like nullglob isn't default in bash; handle by checking directory
  local trash="$home/.Trash"
  if [[ ! -d "$trash" ]]; then
    return 0
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[DRY] Would delete contents of: $trash"
    ls -A "$trash" 2>/dev/null | sed 's/^/[DRY] would delete: /' | tee -a "$LOG_FILE" >/dev/null || true
  else
    # delete contents, not the folder
    rm -rf -- "$trash"/* 2>/dev/null || true
    rm -rf -- "$trash"/.* 2>/dev/null || true
  fi
}

homebrew_cleanup() {
  need_cmd brew || { warn "Homebrew not found; skipping."; return 0; }
  log "Homebrew: cleanup (--prune=all)."
  if [[ "$DRY_RUN" -eq 1 ]]; then
    # brew supports -n for dry run
    brew cleanup --prune=all -n 2>/dev/null | tee -a "$LOG_FILE" >/dev/null || true
  else
    brew cleanup --prune=all || true
  fi
}

dev_cleanup() {
  local home="$1"
  log "Dev cleanup: removing common large Xcode/dev folders (safe to recreate)."
  rm_rf "$home/Library/Developer/Xcode/DerivedData"
  rm_rf "$home/Library/Developer/Xcode/Archives"
  rm_rf "$home/Library/Developer/Xcode/iOS DeviceSupport"
  rm_rf "$home/Library/Developer/CoreSimulator/Caches"
  rm_rf "$home/Library/Caches/com.apple.dt.Xcode"
  rm_rf "$home/Library/Caches/org.swift.swiftpm"
  rm_rf "$home/Library/Caches/CocoaPods"
}

pkg_cache_cleanup() {
  local home="$1"
  log "Package manager caches cleanup (can force redownloads later)."

  if need_cmd npm; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "[DRY] npm cache clean --force"
    else
      npm cache clean --force >/dev/null 2>&1 || true
    fi
  fi
  if need_cmd yarn; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "[DRY] yarn cache clean"
    else
      yarn cache clean >/dev/null 2>&1 || true
    fi
  fi
  if need_cmd pnpm; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "[DRY] pnpm store prune"
    else
      pnpm store prune >/dev/null 2>&1 || true
    fi
  fi

  rm_rf "$home/Library/Caches/pip"
  rm_rf "$home/.cargo/registry/cache"
  rm_rf "$home/.cargo/git/db"
  rm_rf "$home/.gradle/caches"

  # Maven cache can be huge but deleting it is disruptive; ask separately.
  if ask_yn "Do you want to delete Maven local repository (~/.m2/repository)? This can free a lot of space but forces redownloads." 1; then
    rm_rf "$home/.m2/repository"
  else
    log "Keeping Maven cache."
  fi
}

tm_thin_snapshots() {
  # tmutil needs sudo for some operations
  local bytes=$(( TM_THIN_GB * 1000 * 1000 * 1000 ))
  log "Time Machine local snapshots: thinning by approx ${TM_THIN_GB}GB (often reduces 'System Data')."
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[DRY] tmutil listlocalsnapshots /"
    log "[DRY] sudo tmutil thinlocalsnapshots / $bytes 4"
  else
    tmutil listlocalsnapshots / || true
    sudo tmutil thinlocalsnapshots / "$bytes" 4 || true
  fi
}

tm_delete_all_snapshots() {
  log "Time Machine local snapshots: deleting ALL local snapshots (aggressive)."
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[DRY] tmutil listlocalsnapshotdates"
    log "[DRY] sudo tmutil deletelocalsnapshots <date> (for each date)"
    return 0
  fi

  local dates
  dates="$(tmutil listlocalsnapshotdates 2>/dev/null | grep "-" || true)"
  if [[ -z "$dates" ]]; then
    log "No local snapshots found."
    return 0
  fi
  while IFS= read -r d; do
    [[ -n "$d" ]] || continue
    sudo tmutil deletelocalsnapshots "$d" || true
  done <<< "$dates"
}

dns_flush() {
  log "Flushing DNS cache..."
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[DRY] sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
  else
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder
  fi
}

spotlight_reindex() {
  log "Spotlight reindex..."
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[DRY] sudo mdutil -a -i off; sudo mdutil -a -i on; sudo mdutil -aE"
  else
    sudo mdutil -a -i off || true
    sudo mdutil -a -i on || true
    sudo mdutil -aE || true
  fi
}

# ---------- interactive configuration ----------
show_plan() {
  log "Planned actions:"
  echo "  - User logs (>30 days):            $([[ $ACTION_USER_LOGS -eq 1 ]] && echo YES || echo NO)"
  echo "  - System logs (/Library/Logs):     $([[ $ACTION_SYSTEM_LOGS -eq 1 ]] && echo YES || echo NO)"
  echo "  - Targeted user caches:            $([[ $ACTION_USER_CACHES_TARGETED -eq 1 ]] && echo YES || echo NO)"
  echo "  - iOS backups (>180 days):         $([[ $ACTION_IOS_BACKUPS -eq 1 ]] && echo YES || echo NO)"
  echo "  - Empty Trash:                     $([[ $ACTION_EMPTY_TRASH -eq 1 ]] && echo YES || echo NO)"
  echo "  - Homebrew cleanup:                $([[ $ACTION_BREW_CLEANUP -eq 1 ]] && echo YES || echo NO)"
  echo "  - Dev cleanup (Xcode etc.):        $([[ $ACTION_DEV_CLEAN -eq 1 ]] && echo YES || echo NO)"
  echo "  - Package manager caches:          $([[ $ACTION_PKG_CACHES -eq 1 ]] && echo YES || echo NO)"
  echo "  - Time Machine thin snapshots:     $([[ $ACTION_TM_THIN -eq 1 ]] && echo YES || echo NO) (GB=$TM_THIN_GB)"
  echo "  - Time Machine delete ALL:         $([[ $ACTION_TM_DELETE_ALL -eq 1 ]] && echo YES || echo NO)"
  echo "  - DNS flush:                       $([[ $ACTION_DNS_FLUSH -eq 1 ]] && echo YES || echo NO)"
  echo "  - Spotlight reindex:               $([[ $ACTION_SPOTLIGHT_REINDEX -eq 1 ]] && echo YES || echo NO)"
}

interactive_setup() {
  echo "macOS Debloat / Cleanup (interactive)"
  echo "Log file: $LOG_FILE"
  echo

  if ask_yn "Do you want to start with a dry-run (shows what would be deleted, without deleting)?" 0; then
    DRY_RUN=1
  else
    DRY_RUN=0
  fi

  echo
  echo "Choose what to clean. Default choices are conservative."
  echo

  # Core set (safe defaults)
  if ask_yn "Delete user log files older than 30 days (~/Library/Logs)?" 0; then ACTION_USER_LOGS=1; else ACTION_USER_LOGS=0; fi
  if ask_yn "Delete old iOS backup folders older than 180 days (MobileSync/Backup)?" 0; then ACTION_IOS_BACKUPS=1; else ACTION_IOS_BACKUPS=0; fi
  if ask_yn "Clean targeted safe caches (Safari/WebKit + common caches)?" 0; then ACTION_USER_CACHES_TARGETED=1; else ACTION_USER_CACHES_TARGETED=0; fi
  if ask_yn "Empty Trash?" 1; then ACTION_EMPTY_TRASH=1; else ACTION_EMPTY_TRASH=0; fi

  echo
  echo "Optional (can free more space):"
  if ask_yn "Run Homebrew cleanup (brew cleanup --prune=all)?" 1; then ACTION_BREW_CLEANUP=1; else ACTION_BREW_CLEANUP=0; fi
  if ask_yn "Clean development artifacts (Xcode DerivedData/Archives/Simulator caches)?" 1; then ACTION_DEV_CLEAN=1; else ACTION_DEV_CLEAN=0; fi
  if ask_yn "Clean package manager caches (npm/yarn/pnpm/pip/cargo/gradle)?" 1; then ACTION_PKG_CACHES=1; else ACTION_PKG_CACHES=0; fi

  echo
  echo "System Data / Time Machine snapshots (often helps when 'System Data' is large):"
  if ask_yn "Thin local Time Machine snapshots (recommended before deleting all)?" 1; then
    ACTION_TM_THIN=1
    read -r -p "How many GB to try to free by thinning snapshots? (default 15): " TM_THIN_GB_IN
    TM_THIN_GB_IN="${TM_THIN_GB_IN:-15}"
    if [[ "$TM_THIN_GB_IN" =~ ^[0-9]+$ ]]; then
      TM_THIN_GB="$TM_THIN_GB_IN"
    else
      warn "Invalid number; using default 15 GB."
      TM_THIN_GB=15
    fi
  else
    ACTION_TM_THIN=0
  fi

  if ask_yn "Delete ALL local Time Machine snapshots? (aggressive, use only if you know you want this)" 1; then
    ACTION_TM_DELETE_ALL=1
  else
    ACTION_TM_DELETE_ALL=0
  fi

  echo
  echo "Troubleshooting (not necessary for debloat; optional):"
  if ask_yn "Flush DNS cache?" 1; then ACTION_DNS_FLUSH=1; else ACTION_DNS_FLUSH=0; fi
  if ask_yn "Reindex Spotlight? (can take time and increase disk activity temporarily)" 1; then ACTION_SPOTLIGHT_REINDEX=1; else ACTION_SPOTLIGHT_REINDEX=0; fi

  echo
  echo "Advanced:"
  if ask_yn "Also delete old system log files in /Library/Logs (may be restricted by SIP)?" 1; then ACTION_SYSTEM_LOGS=1; else ACTION_SYSTEM_LOGS=0; fi
}

determine_if_sudo_needed() {
  NEED_SUDO=0
  if [[ $ACTION_SYSTEM_LOGS -eq 1 ]]; then NEED_SUDO=1; fi
  if [[ $ACTION_TM_THIN -eq 1 || $ACTION_TM_DELETE_ALL -eq 1 ]]; then NEED_SUDO=1; fi
  if [[ $ACTION_DNS_FLUSH -eq 1 || $ACTION_SPOTLIGHT_REINDEX -eq 1 ]]; then NEED_SUDO=1; fi
}

run_plan() {
  local home="$1"

  log "Running plan..."
  log "$(human_df)"

  if [[ $ACTION_USER_LOGS -eq 1 ]]; then cleanup_user_logs "$home"; fi
  if [[ $ACTION_SYSTEM_LOGS -eq 1 ]]; then cleanup_system_logs; fi
  if [[ $ACTION_IOS_BACKUPS -eq 1 ]]; then cleanup_ios_backups "$home"; fi
  if [[ $ACTION_USER_CACHES_TARGETED -eq 1 ]]; then cleanup_user_caches_targeted "$home"; fi
  if [[ $ACTION_BREW_CLEANUP -eq 1 ]]; then homebrew_cleanup; fi
  if [[ $ACTION_DEV_CLEAN -eq 1 ]]; then dev_cleanup "$home"; fi
  if [[ $ACTION_PKG_CACHES -eq 1 ]]; then pkg_cache_cleanup "$home"; fi
  if [[ $ACTION_TM_THIN -eq 1 && $TM_THIN_GB -gt 0 ]]; then tm_thin_snapshots; fi
  if [[ $ACTION_TM_DELETE_ALL -eq 1 ]]; then tm_delete_all_snapshots; fi
  if [[ $ACTION_EMPTY_TRASH -eq 1 ]]; then empty_trash "$home"; fi
  if [[ $ACTION_DNS_FLUSH -eq 1 ]]; then dns_flush; fi
  if [[ $ACTION_SPOTLIGHT_REINDEX -eq 1 ]]; then spotlight_reindex; fi

  log "$(human_df)"
  log "Completed."
  log "Log: $LOG_FILE"
}

# ---------- main ----------
main() {
  is_macos || die "This script is for macOS only."

  interactive_setup

  local info user home
  info="$(get_target_user_and_home)"
  user="${info%%|*}"
  home="${info##*|}"

  echo
  echo "Target user: $user"
  echo "Target home: $home"
  echo

  show_plan
  echo

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "You are about to run a DRY-RUN (no deletions)."
  else
    echo "You are about to APPLY changes (files will be deleted)."
  fi

  if ! ask_yn "Continue?" 0; then
    echo "Aborted."
    exit 0
  fi

  determine_if_sudo_needed
  ensure_sudo

  run_plan "$home"

  if [[ $DRY_RUN -eq 1 ]]; then
    echo
    if ask_yn "Dry-run complete. Do you want to APPLY the same plan now (perform deletions)?" 1; then
      DRY_RUN=0
      determine_if_sudo_needed
      ensure_sudo
      run_plan "$home"
    else
      echo "Finished after dry-run. No changes applied."
    fi
  fi
}

main "$@"