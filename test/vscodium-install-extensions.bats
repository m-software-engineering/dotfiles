#!/usr/bin/env bats
# shellcheck disable=SC2154

# Creates an isolated manifest and fake VSCodium CLI for each test.
setup() {
  PROJECT_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  INSTALLER="${PROJECT_ROOT}/scripts/scripts/vscodium-install-extensions.sh"
  TEST_ROOT="${BATS_TEST_TMPDIR}/fixture"
  BIN_DIR="${TEST_ROOT}/bin"
  EXTENSIONS_FILE="${TEST_ROOT}/extensions.txt"
  CODIUM_STATE="${TEST_ROOT}/installed.txt"
  CODIUM_CALL_LOG="${TEST_ROOT}/codium.log"
  mkdir -p "${BIN_DIR}"
  : >"${CODIUM_STATE}"
  : >"${CODIUM_CALL_LOG}"

  cat >"${BIN_DIR}/codium" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  --list-extensions)
    if [[ "${CODIUM_LIST_FAILURE:-false}" == "true" ]]; then
      exit 2
    fi
    cat "${CODIUM_STATE}"
    ;;
  --install-extension)
    extension_id="${2:-}"
    printf '%s\n' "${extension_id}" >>"${CODIUM_CALL_LOG}"
    if [[ "${extension_id}" == "${CODIUM_FAIL_EXTENSION:-}" ]]; then
      exit 3
    fi
    printf '%s\n' "${extension_id}" >>"${CODIUM_STATE}"
    if [[ -n "${CODIUM_TRANSITIVE_EXTENSION:-}" ]]; then
      printf '%s\n' "${CODIUM_TRANSITIVE_EXTENSION}" >>"${CODIUM_STATE}"
    fi
    ;;
  *)
    exit 4
    ;;
esac
EOF
  chmod +x "${BIN_DIR}/codium"

  export EXTENSIONS_FILE CODIUM_STATE CODIUM_CALL_LOG
}

# Runs the extension installer against the isolated fake VSCodium CLI.
run_installer() {
  PATH="${BIN_DIR}:/usr/bin:/bin" run /bin/bash "${INSTALLER}"
}

function installs_only_missing_extensions_and_is_idempotent { #@test
  printf 'publisher.installed\n' >"${CODIUM_STATE}"
  cat >"${EXTENSIONS_FILE}" <<'EOF'
publisher.installed
publisher.missing
EOF

  run_installer

  [ "${status}" -eq 0 ]
  [[ "${output}" == *"Extension summary: installed=1 skipped=1 failed=0"* ]]
  [ "$(cat "${CODIUM_CALL_LOG}")" = "publisher.missing" ]

  run_installer

  [ "${status}" -eq 0 ]
  [[ "${output}" == *"Extension summary: installed=0 skipped=2 failed=0"* ]]
  [ "$(wc -l <"${CODIUM_CALL_LOG}" | tr -d ' ')" -eq 1 ]
}

function normalizes_comments_whitespace_crlf_and_duplicates { #@test
  printf '  # comment\r\n\r\n  publisher.extension  \r\npublisher.extension\n' >"${EXTENSIONS_FILE}"

  run_installer

  [ "${status}" -eq 0 ]
  [[ "${output}" == *"Extension summary: installed=1 skipped=1 failed=0"* ]]
  [ "$(cat "${CODIUM_CALL_LOG}")" = "publisher.extension" ]
}

function refreshes_installed_state_after_transitive_dependency_installation { #@test
  cat >"${EXTENSIONS_FILE}" <<'EOF'
publisher.parent
publisher.dependency
EOF
  export CODIUM_TRANSITIVE_EXTENSION="publisher.dependency"

  run_installer

  [ "${status}" -eq 0 ]
  [[ "${output}" == *"Extension summary: installed=1 skipped=1 failed=0"* ]]
  [ "$(cat "${CODIUM_CALL_LOG}")" = "publisher.parent" ]
}

function reports_invalid_and_failed_entries_after_attempting_the_manifest { #@test
  cat >"${EXTENSIONS_FILE}" <<'EOF'
not-an-extension-id
publisher.fails
publisher.succeeds
EOF
  export CODIUM_FAIL_EXTENSION="publisher.fails"

  run_installer

  [ "${status}" -eq 1 ]
  [[ "${output}" == *"Invalid extension identifier: not-an-extension-id"* ]]
  [[ "${output}" == *"Failed to install: publisher.fails"* ]]
  [[ "${output}" == *"Extension summary: installed=1 skipped=0 failed=2"* ]]
  [[ "$(cat "${CODIUM_CALL_LOG}")" == $'publisher.fails\npublisher.succeeds' ]]
}

function fails_when_the_manifest_is_missing { #@test
  run_installer

  [ "${status}" -eq 1 ]
  [[ "${output}" == *"Extensions file not found: ${EXTENSIONS_FILE}"* ]]
}

function fails_when_codium_is_missing { #@test
  printf 'publisher.extension\n' >"${EXTENSIONS_FILE}"

  PATH="/usr/bin:/bin" run /bin/bash "${INSTALLER}"

  [ "${status}" -eq 1 ]
  [[ "${output}" == *"'codium' command not found"* ]]
}

function fails_when_installed_extensions_cannot_be_listed { #@test
  printf 'publisher.extension\n' >"${EXTENSIONS_FILE}"
  export CODIUM_LIST_FAILURE="true"

  run_installer

  [ "${status}" -eq 1 ]
  [[ "${output}" == *"Unable to list installed VSCodium extensions."* ]]
  [ ! -s "${CODIUM_CALL_LOG}" ]
}
