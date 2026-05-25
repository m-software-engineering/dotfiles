#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: scripts/scripts/macos-set-default-apps.sh [--dry-run]

Sets macOS default handlers with duti:
  - Helium for web URLs and HTML files
  - Microsoft Edge for PDFs
  - WezTerm for shell scripts and Unix executables
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if [ "$DRY_RUN" -eq 0 ] && ! command -v duti >/dev/null 2>&1; then
  echo "'duti' command not found. Install it with: brew install duti" >&2
  exit 1
fi

run_duti() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf 'duti'
    printf ' %q' "$@"
    printf '\n'
  else
    duti "$@"
  fi
}

set_url_handler() {
  local bundle_id="$1"
  local scheme="$2"
  run_duti -s "$bundle_id" "$scheme"
}

set_type_handler() {
  local bundle_id="$1"
  local type_id="$2"
  local role="$3"
  run_duti -s "$bundle_id" "$type_id" "$role"
}

HELIUM_BUNDLE_ID="net.imput.helium"
EDGE_BUNDLE_ID="com.microsoft.edgemac"
WEZTERM_BUNDLE_ID="com.github.wez.wezterm"

set_url_handler "$HELIUM_BUNDLE_ID" "http"
set_url_handler "$HELIUM_BUNDLE_ID" "https"
set_type_handler "$HELIUM_BUNDLE_ID" "public.html" "viewer"
set_type_handler "$HELIUM_BUNDLE_ID" "public.xhtml" "viewer"

set_type_handler "$EDGE_BUNDLE_ID" "com.adobe.pdf" "viewer"
set_type_handler "$EDGE_BUNDLE_ID" ".pdf" "viewer"

set_type_handler "$WEZTERM_BUNDLE_ID" "public.unix-executable" "shell"
set_type_handler "$WEZTERM_BUNDLE_ID" ".command" "editor"
set_type_handler "$WEZTERM_BUNDLE_ID" ".sh" "editor"
set_type_handler "$WEZTERM_BUNDLE_ID" ".zsh" "editor"
set_type_handler "$WEZTERM_BUNDLE_ID" ".bash" "editor"
set_type_handler "$WEZTERM_BUNDLE_ID" ".fish" "editor"
set_type_handler "$WEZTERM_BUNDLE_ID" ".tool" "editor"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry run complete. No defaults were changed."
else
  echo "Default app handlers updated."
fi
