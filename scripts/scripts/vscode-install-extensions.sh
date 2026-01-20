#!/usr/bin/env bash
set -euo pipefail

# Installs VS Code extensions listed in:
#   <dotfiles>/vscode/vscode-extensions.txt

DOTFILES_DIR="${DOTFILES_DIR:-"$HOME/dotfiles"}"
EXTENSIONS_FILE="${EXTENSIONS_FILE:-"$DOTFILES_DIR/vscode/vscode-extensions.txt"}"

if [ ! -f "$EXTENSIONS_FILE" ]; then
  echo "Extensions file not found: $EXTENSIONS_FILE"
  echo "Ensure the file exists or set EXTENSIONS_FILE to the correct path."
  exit 1
fi

if ! command -v code >/dev/null 2>&1; then
  echo "'code' command not found. Install VS Code and enable 'code' in PATH."
  exit 1
fi

while IFS= read -r extension || [ -n "$extension" ]; do
  [ -n "$extension" ] || continue
  code --install-extension "$extension" --force
done < "$EXTENSIONS_FILE"
