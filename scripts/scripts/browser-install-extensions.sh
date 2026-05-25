#!/usr/bin/env bash
set -euo pipefail

# scripts/browser-install-extensions.sh
#
# Opens Chrome Web Store pages for each extension URL found in:
#   <dotfiles>/browser/extensions-urls.txt
#
# This is as automatic as Chromium-family browsers allow without enterprise policies.
# The browser will still typically require one manual add/install click per extension.

DOTFILES_DIR="${DOTFILES_DIR:-"$HOME/dotfiles"}"
URLS_FILE="${URLS_FILE:-"$DOTFILES_DIR/browser/extensions-urls.txt"}"
BROWSER_APP="${BROWSER_APP:-"/Applications/Helium.app"}"

if [ ! -f "$URLS_FILE" ]; then
  echo "URLs file not found: $URLS_FILE"
  echo "Run: scripts/scripts/browser-export-extensions.sh"
  exit 1
fi

read -r -p "This will open Chrome Web Store pages for all extensions in: $URLS_FILE. Continue? [y/N] " ans
ans="${ans:-N}"
case "$ans" in
  y|Y) ;;
  *) echo "Aborted."; exit 0 ;;
esac

if command -v open >/dev/null 2>&1; then
  :
else
  echo "'open' command not found (this script is for macOS)."
  exit 1
fi

# Prefer Helium or BROWSER_APP when available; fallback to the default browser.
if [ -d "$BROWSER_APP" ]; then
  while IFS= read -r url; do
    [ -n "$url" ] || continue
    open -a "$BROWSER_APP" "$url"
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

echo "Done. Install each extension from the opened Chrome Web Store pages."
