#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-"$HOME/dotfiles"}"
EXTENSIONS_FILE="${EXTENSIONS_FILE:-"$DOTFILES_DIR/vscodium/vscodium-extensions.txt"}"

# Trims surrounding whitespace and a trailing carriage return from a manifest line.
trim_extension_line() {
  local line="${1%$'\r'}"
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  printf '%s\n' "${line}"
}

# Returns success when the value is a syntactically valid extension identifier.
is_valid_extension_id() {
  local extension_id="${1}"
  [[ "${extension_id}" =~ ^[[:alnum:]][[:alnum:]-]*\.[[:alnum:]][[:alnum:]._-]*$ ]]
}

# Returns success when an extension identifier is present in a newline-delimited list.
extension_is_installed() {
  local extension_id="${1}"
  local installed_extensions="${2}"
  grep -Fqix -- "${extension_id}" <<<"${installed_extensions}"
}

# Installs missing manifest entries and reports all invalid or failed entries together.
install_extensions() {
  local installed_extensions
  if ! installed_extensions="$(codium --list-extensions)"; then
    printf 'Unable to list installed VSCodium extensions.\n' >&2
    return 1
  fi

  local installed_count=0
  local skipped_count=0
  local failed_count=0
  local failed_extensions=""
  local manifest_line
  local extension_id

  while IFS= read -r manifest_line || [[ -n "${manifest_line}" ]]; do
    extension_id="$(trim_extension_line "${manifest_line}")"
    [[ -n "${extension_id}" ]] || continue
    [[ "${extension_id}" == \#* ]] && continue

    if ! is_valid_extension_id "${extension_id}"; then
      printf 'Invalid extension identifier: %s\n' "${extension_id}" >&2
      failed_count=$((failed_count + 1))
      failed_extensions="${failed_extensions}${failed_extensions:+, }${extension_id}"
      continue
    fi

    if extension_is_installed "${extension_id}" "${installed_extensions}"; then
      printf 'Already installed: %s\n' "${extension_id}"
      skipped_count=$((skipped_count + 1))
      continue
    fi

    printf 'Installing: %s\n' "${extension_id}"
    if codium --install-extension "${extension_id}"; then
      installed_count=$((installed_count + 1))
      installed_extensions="${installed_extensions}${installed_extensions:+$'\n'}${extension_id}"
    else
      printf 'Failed to install: %s\n' "${extension_id}" >&2
      failed_count=$((failed_count + 1))
      failed_extensions="${failed_extensions}${failed_extensions:+, }${extension_id}"
    fi
  done <"${EXTENSIONS_FILE}"

  printf 'Extension summary: installed=%d skipped=%d failed=%d\n' \
    "${installed_count}" "${skipped_count}" "${failed_count}"

  if [[ "${failed_count}" -gt 0 ]]; then
    printf 'Unresolved extensions: %s\n' "${failed_extensions}" >&2
    return 1
  fi
}

# Validates prerequisites and synchronizes required VSCodium extensions.
main() {
  if [[ ! -f "${EXTENSIONS_FILE}" ]]; then
    printf 'Extensions file not found: %s\n' "${EXTENSIONS_FILE}" >&2
    printf 'Ensure the file exists or set EXTENSIONS_FILE to the correct path.\n' >&2
    return 1
  fi

  if ! command -v codium >/dev/null 2>&1; then
    printf "'codium' command not found. Install VSCodium and ensure 'codium' is in PATH.\n" >&2
    return 1
  fi

  install_extensions
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
