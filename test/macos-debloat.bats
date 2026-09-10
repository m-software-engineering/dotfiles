#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2154

setup() {
  PROJECT_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  DEBLOAT_SCRIPT="${PROJECT_ROOT}/scripts/scripts/macos-debloat.sh"
  local physical_tmpdir
  physical_tmpdir="$(cd -P "${BATS_TEST_TMPDIR}" && pwd -P)"
  TEST_HOME="${physical_tmpdir}/home"
  TEST_LOG="${BATS_TEST_TMPDIR}/macos-debloat.log"
  DELETE_MARKER="${BATS_TEST_TMPDIR}/delete-command-called"
  mkdir -p "${TEST_HOME}"
}

run_empty_trash() {
  local home="$1"

  run env \
    DEBLOAT_SCRIPT="${DEBLOAT_SCRIPT}" \
    TEST_HOME="${home}" \
    TEST_LOG="${TEST_LOG}" \
    /bin/bash -c '
      source "${DEBLOAT_SCRIPT}"
      DRY_RUN=0
      LOG_FILE="${TEST_LOG}"
      empty_trash "${TEST_HOME}"
    '
}

run_invalid_home_with_delete_spies() {
  local home="$1"

  run env \
    DEBLOAT_SCRIPT="${DEBLOAT_SCRIPT}" \
    TEST_HOME="${home}" \
    TEST_LOG="${TEST_LOG}" \
    DELETE_MARKER="${DELETE_MARKER}" \
    /bin/bash -c '
      source "${DEBLOAT_SCRIPT}"
      DRY_RUN=0
      LOG_FILE="${TEST_LOG}"
      rm() { : >"${DELETE_MARKER}"; }
      find() { : >"${DELETE_MARKER}"; }
      empty_trash "${TEST_HOME}"
    '
}

function sourcing_the_script_does_not_run_main { #@test
  run env DEBLOAT_SCRIPT="${DEBLOAT_SCRIPT}" /bin/bash -c '
    source "${DEBLOAT_SCRIPT}" &&
    declare -F empty_trash >/dev/null &&
    printf "sourced\n"
  '

  [ "${status}" -eq 0 ]
  [ "${output}" = "sourced" ]
}

function sourcing_the_script_preserves_the_callers_shell_state { #@test
  run env DEBLOAT_SCRIPT="${DEBLOAT_SCRIPT}" /bin/bash --noprofile --norc -c '
    set +e +u +o pipefail
    IFS=:
    trap "exit 0" EXIT
    before_flags="$-"
    before_ifs="${IFS}"
    before_trap="$(trap -p EXIT)"

    source "${DEBLOAT_SCRIPT}"

    after_flags="$-"
    after_ifs="${IFS}"
    after_trap="$(trap -p EXIT)"
    set +e +u +o pipefail
    trap - EXIT

    [[ "${after_flags}" == "${before_flags}" ]] &&
    [[ "${after_ifs}" == "${before_ifs}" ]] &&
    [[ "${after_trap}" == "${before_trap}" ]]
  '

  [ "${status}" -eq 0 ]
}

function sourcing_the_script_preserves_the_callers_variables { #@test
  run env DEBLOAT_SCRIPT="${DEBLOAT_SCRIPT}" /bin/bash --noprofile --norc -c '
    LOG_FILE="caller-log"
    DRY_RUN="caller-dry-run"
    NEED_SUDO="caller-sudo"
    ACTION_EMPTY_TRASH="caller-action"

    source "${DEBLOAT_SCRIPT}" &&
    [[ "${LOG_FILE}" == "caller-log" ]] &&
    [[ "${DRY_RUN}" == "caller-dry-run" ]] &&
    [[ "${NEED_SUDO}" == "caller-sudo" ]] &&
    [[ "${ACTION_EMPTY_TRASH}" == "caller-action" ]]
  '

  [ "${status}" -eq 0 ]
}

function empty_trash_rejects_an_empty_home_without_deleting { #@test
  run_invalid_home_with_delete_spies ""

  [ "${status}" -ne 0 ]
  [ ! -e "${DELETE_MARKER}" ]
}

function empty_trash_rejects_root_home_without_deleting { #@test
  run_invalid_home_with_delete_spies "/"

  [ "${status}" -ne 0 ]
  [ ! -e "${DELETE_MARKER}" ]
}

function empty_trash_rejects_root_aliases_without_deleting { #@test
  local root_alias
  for root_alias in "//" "/." "/.."; do
    run_invalid_home_with_delete_spies "${root_alias}"

    if [[ "${status}" -eq 0 ]]; then
      printf 'accepted root alias: %s\n' "${root_alias}" >&3
      return 1
    fi
    [ ! -e "${DELETE_MARKER}" ]
  done
}

function empty_trash_rejects_a_relative_home_without_deleting { #@test
  run_invalid_home_with_delete_spies "test"

  [ "${status}" -ne 0 ]
  [ ! -e "${DELETE_MARKER}" ]
}

function empty_trash_rejects_a_symlinked_home_without_deleting { #@test
  local real_home="${BATS_TEST_TMPDIR}/real-home"
  local home_link="${BATS_TEST_TMPDIR}/home-link"
  mkdir -p "${real_home}/.Trash"
  touch "${real_home}/.Trash/keep-me"
  ln -s "${real_home}" "${home_link}"

  run_empty_trash "${home_link}"

  [ "${status}" -ne 0 ]
  [ -L "${home_link}" ]
  [ -e "${real_home}/.Trash/keep-me" ]
}

function empty_trash_rejects_privileged_execution_without_deleting { #@test
  mkdir -p "${TEST_HOME}/.Trash"
  touch "${TEST_HOME}/.Trash/keep-me"

  run env \
    DEBLOAT_SCRIPT="${DEBLOAT_SCRIPT}" \
    TEST_HOME="${TEST_HOME}" \
    TEST_LOG="${TEST_LOG}" \
    /bin/bash -c '
      source "${DEBLOAT_SCRIPT}"
      DRY_RUN=0
      LOG_FILE="${TEST_LOG}"
      is_privileged() { return 0; }
      empty_trash "${TEST_HOME}"
    '

  [ "${status}" -ne 0 ]
  [ -e "${TEST_HOME}/.Trash/keep-me" ]
}

function empty_trash_deletes_visible_and_hidden_children_but_preserves_trash { #@test
  mkdir -p \
    "${TEST_HOME}/.Trash/visible-directory" \
    "${TEST_HOME}/.Trash/.hidden-directory"
  touch \
    "${TEST_HOME}/.Trash/visible-file" \
    "${TEST_HOME}/.Trash/.hidden-file" \
    "${TEST_HOME}/.Trash/visible-directory/nested-file" \
    "${TEST_HOME}/.Trash/.hidden-directory/nested-file"

  run_empty_trash "${TEST_HOME}"

  [ "${status}" -eq 0 ]
  [ -d "${TEST_HOME}/.Trash" ]
  [ ! -e "${TEST_HOME}/.Trash/visible-file" ]
  [ ! -e "${TEST_HOME}/.Trash/.hidden-file" ]
  [ ! -e "${TEST_HOME}/.Trash/visible-directory" ]
  [ ! -e "${TEST_HOME}/.Trash/.hidden-directory" ]
}

function empty_trash_does_not_follow_a_rebound_trash_path_during_deletion { #@test
  local outside_dir="${BATS_TEST_TMPDIR}/outside"
  local moved_trash="${TEST_HOME}/.Trash-opened"
  local fake_bin="${BATS_TEST_TMPDIR}/bin"
  local rebind_marker="${BATS_TEST_TMPDIR}/trash-rebound"
  mkdir -p "${TEST_HOME}/.Trash" "${outside_dir}" "${fake_bin}"
  touch "${TEST_HOME}/.Trash/keep-me" "${outside_dir}/keep-me"
  # Rebind only when find dispatches rm, after it has enumerated the child.
  cat >"${fake_bin}/rm" <<'EOF'
#!/bin/bash
set -eu
if [[ ! -e "${REBIND_MARKER}" ]]; then
  /bin/mv "${TEST_HOME}/.Trash" "${MOVED_TRASH}"
  /bin/ln -s "${OUTSIDE_DIR}" "${TEST_HOME}/.Trash"
  : >"${REBIND_MARKER}"
fi
exec /bin/rm "$@"
EOF
  chmod +x "${fake_bin}/rm"

  run env \
    DEBLOAT_SCRIPT="${DEBLOAT_SCRIPT}" \
    TEST_HOME="${TEST_HOME}" \
    TEST_LOG="${TEST_LOG}" \
    MOVED_TRASH="${moved_trash}" \
    OUTSIDE_DIR="${outside_dir}" \
    REBIND_MARKER="${rebind_marker}" \
    PATH="${fake_bin}:${PATH}" \
    /bin/bash -c '
      source "${DEBLOAT_SCRIPT}"
      DRY_RUN=0
      LOG_FILE="${TEST_LOG}"
      empty_trash "${TEST_HOME}"
    '

  [ "${status}" -eq 0 ]
  [ -e "${rebind_marker}" ]
  [ -L "${TEST_HOME}/.Trash" ]
  [ -e "${outside_dir}/keep-me" ]
  [ ! -e "${moved_trash}/keep-me" ]
}

function empty_trash_rejects_a_symlinked_trash_without_deleting { #@test
  local trash_target="${BATS_TEST_TMPDIR}/trash-target"
  mkdir -p "${trash_target}"
  touch "${trash_target}/keep-me"
  ln -s "${trash_target}" "${TEST_HOME}/.Trash"

  run_empty_trash "${TEST_HOME}"

  [ "${status}" -ne 0 ]
  [ -L "${TEST_HOME}/.Trash" ]
  [ -e "${trash_target}/keep-me" ]
}
