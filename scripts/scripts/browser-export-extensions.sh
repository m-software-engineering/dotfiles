#!/usr/bin/env bash
set -euo pipefail

# scripts/browser-export-extensions.sh
#
# Exports Chromium-family browser extension IDs + Web Store URLs into your dotfiles repo.
# Output:
#   browser/extensions-ids.txt
#   browser/extensions-urls.txt
#   browser/extensions-export.log

DOTFILES_DIR="${DOTFILES_DIR:-"$HOME/dotfiles"}"
BROWSER_DIR="$DOTFILES_DIR/browser"
OUT_IDS="$BROWSER_DIR/extensions-ids.txt"
OUT_URLS="$BROWSER_DIR/extensions-urls.txt"
OUT_LOG="$BROWSER_DIR/extensions-export.log"

# Chromium-family profile root on macOS. Defaults to Helium.
BROWSER_PROFILE_ROOT="${BROWSER_PROFILE_ROOT:-${CHROME_PROFILE_ROOT:-"$HOME/Library/Application Support/net.imput.helium"}}"

mkdir -p "$BROWSER_DIR"

log() { printf '%s\n' "$*" | tee -a "$OUT_LOG" >/dev/null; }

# Determine which Chromium-family profiles exist (Default, Profile 1, Profile 2, ...)
discover_profiles() {
  local root="$1"
  if [ ! -d "$root" ]; then
    return 0
  fi
  # Profiles have Preferences file; extension dirs live under Extensions/
  find "$root" -maxdepth 1 -type d \( -name "Default" -o -name "Profile *" \) -print 2>/dev/null
}

extract_ext_ids_from_profile() {
  local profile_dir="$1"
  local ext_dir="$profile_dir/Extensions"
  [ -d "$ext_dir" ] || return 0

  # Each first-level folder name under Extensions/ is the extension ID.
  find "$ext_dir" -maxdepth 1 -mindepth 1 -type d -print 2>/dev/null \
    | awk -F/ '{print $NF}' \
    | grep -E '^[a-p]{32}$' || true
}

: > "$OUT_LOG"
log "Browser extension export started: $(date)"
log "DOTFILES_DIR: $DOTFILES_DIR"
log "BROWSER_PROFILE_ROOT: $BROWSER_PROFILE_ROOT"

profiles=()
while IFS= read -r p; do
  profiles+=("$p")
done < <(discover_profiles "$BROWSER_PROFILE_ROOT")

if [ "${#profiles[@]}" -eq 0 ]; then
  log "No Chromium browser profiles found under: $BROWSER_PROFILE_ROOT"
  log "If your profile root is different, set BROWSER_PROFILE_ROOT."
  exit 1
fi

tmp_ids="$(mktemp)"
trap 'rm -f "$tmp_ids"' EXIT

for prof in "${profiles[@]}"; do
  log "Scanning profile: $prof"
  extract_ext_ids_from_profile "$prof" >> "$tmp_ids"
done

sort -u "$tmp_ids" > "$OUT_IDS"
awk '{print "https://chromewebstore.google.com/detail/" $1}' "$OUT_IDS" > "$OUT_URLS"

count_ids="$(wc -l < "$OUT_IDS" | tr -d ' ')"
log "Export complete."
log "Found $count_ids extension IDs."
log "Wrote:"
log "  - $OUT_IDS"
log "  - $OUT_URLS"
log "Browser extension export finished: $(date)"
