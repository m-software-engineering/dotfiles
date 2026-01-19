# scripts/chrome-install-extensions.sh
#!/usr/bin/env bash
set -euo pipefail

# Opens Chrome Web Store pages for each extension ID found in:
#   <dotfiles>/chrome/extensions-urls.txt
#
# This is as "automatic" as Chrome allows without enterprise policies.
# Chrome will still typically require a click ("Add to Chrome") per extension.

DOTFILES_DIR="${DOTFILES_DIR:-"$HOME/dotfiles"}"
URLS_FILE="${URLS_FILE:-"$DOTFILES_DIR/chrome/extensions-urls.txt"}"

if [ ! -f "$URLS_FILE" ]; then
  echo "URLs file not found: $URLS_FILE"
  echo "Run: scripts/chrome-export-extensions.sh"
  exit 1
fi

read -r -p "This will open Chrome Web Store pages for all extensions in: $URLS_FILE. Continue? [y/N] " ans
ans="${ans:-N}"
case "$ans" in
  y|Y) ;;
  *) echo "Aborted."; exit 0 ;;
esac

# Prefer Google Chrome bundle if installed; fallback to default browser.
OPEN_CMD="open"
if command -v open >/dev/null 2>&1; then
  :
else
  echo "'open' command not found (this script is for macOS)."
  exit 1
fi

# Try to open explicitly in Chrome if available.
CHROME_APP="/Applications/Google Chrome.app"
if [ -d "$CHROME_APP" ]; then
  # -a targets app; works with URLs
  while IFS= read -r url; do
    [ -n "$url" ] || continue
    open -a "$CHROME_APP" "$url"
    # Small delay to avoid overwhelming the system
    sleep 0.15
  done < "$URLS_FILE"
else
  while IFS= read -r url; do
    [ -n "$url" ] || continue
    open "$url"
    sleep 0.15
  done < "$URLS_FILE"
fi

echo "Done. Install each extension via 'Add to Chrome' on the opened pages."