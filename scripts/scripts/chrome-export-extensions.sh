# scripts/chrome-export-extensions.sh
#!/usr/bin/env bash
set -euo pipefail

# Exports Chrome extension IDs + Web Store URLs into your dotfiles repo.
# Output:
#   chrome/extensions-ids.txt
#   chrome/extensions-urls.txt
#   chrome/extensions-export.log

DOTFILES_DIR="${DOTFILES_DIR:-"$HOME/dotfiles"}"
CHROME_DIR="$DOTFILES_DIR/chrome"
OUT_IDS="$CHROME_DIR/extensions-ids.txt"
OUT_URLS="$CHROME_DIR/extensions-urls.txt"
OUT_LOG="$CHROME_DIR/extensions-export.log"

# Chrome profile roots (macOS)
CHROME_PROFILE_ROOT="${CHROME_PROFILE_ROOT:-"$HOME/Library/Application Support/Google/Chrome"}"

mkdir -p "$CHROME_DIR"

log() { printf '%s\n' "$*" | tee -a "$OUT_LOG" >/dev/null; }

# Determine which Chrome profiles exist (Default, Profile 1, Profile 2, ...)
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
log "Chrome extension export started: $(date)"
log "DOTFILES_DIR: $DOTFILES_DIR"
log "CHROME_PROFILE_ROOT: $CHROME_PROFILE_ROOT"

profiles=()
while IFS= read -r p; do
  profiles+=("$p")
done < <(discover_profiles "$CHROME_PROFILE_ROOT")

if [ "${#profiles[@]}" -eq 0 ]; then
  log "No Chrome profiles found under: $CHROME_PROFILE_ROOT"
  log "If your profile root is different, set CHROME_PROFILE_ROOT."
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
log "Chrome extension export finished: $(date)"