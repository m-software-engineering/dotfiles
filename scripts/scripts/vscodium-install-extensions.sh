#!/usr/bin/env bash
set -euo pipefail

# Installs VSCodium extensions listed in:
#   <dotfiles>/vscodium/vscodium-extensions.txt

DOTFILES_DIR="${DOTFILES_DIR:-"$HOME/dotfiles"}"
EXTENSIONS_FILE="${EXTENSIONS_FILE:-"$DOTFILES_DIR/vscodium/vscodium-extensions.txt"}"

if [ ! -f "$EXTENSIONS_FILE" ]; then
  echo "Extensions file not found: $EXTENSIONS_FILE"
  echo "Ensure the file exists or set EXTENSIONS_FILE to the correct path."
  exit 1
fi

if ! command -v codium >/dev/null 2>&1; then
  echo "'codium' command not found. Install VSCodium and ensure 'codium' is in PATH."
  exit 1
fi

while IFS= read -r extension || [ -n "$extension" ]; do
  [ -n "$extension" ] || continue
  [[ "$extension" =~ ^[[:space:]]*# ]] && continue
  codium --install-extension "$extension" --force
done < "$EXTENSIONS_FILE"
