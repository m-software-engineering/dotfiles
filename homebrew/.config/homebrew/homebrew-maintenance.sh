#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0
BREWFILE="${BREWFILE:-${HOME}/.config/homebrew/Brewfile}"
LOG_DIR="${LOG_DIR:-${HOME}/Library/Logs/m-software-engineering}"
LOCK_DIR="${LOCK_DIR:-${TMPDIR:-/tmp}/mse-homebrew-maintenance.lock}"

## Print CLI usage for the Homebrew maintenance script.
usage() {
	cat <<EOF
Usage: homebrew-maintenance.sh [options]

Update Homebrew, upgrade installed formulae and casks, then clean old artifacts.

Options:
  --dry-run        Print intended commands without applying changes
  --brewfile PATH  Use a specific Brewfile instead of ~/.config/homebrew/Brewfile
  -h, --help       Show this help message
EOF
}

## Print a consistent progress message.
log() {
	printf '==> %s\n' "$1"
}

## Print a shell-escaped command for dry-run output.
print_command() {
	printf '[DRY]'

	local arg
	for arg in "$@"; do
		printf ' %q' "${arg}"
	done

	printf '\n'
}

## Run a command, or print it shell-escaped when dry-run mode is enabled.
run_cmd() {
	if [[ "${DRY_RUN}" -eq 1 ]]; then
		print_command "$@"
		return 0
	fi

	"$@"
}

## Exit early when the host is not macOS.
require_macos() {
	if [[ "$(uname -s)" != "Darwin" ]]; then
		printf 'This script is macOS-only.\n' >&2
		exit 1
	fi
}

## Exit early when Homebrew is not available on PATH.
require_homebrew() {
	if ! command -v brew >/dev/null 2>&1; then
		printf 'Homebrew is required but brew was not found on PATH.\n' >&2
		exit 1
	fi
}

## Exit early when the configured Brewfile does not exist.
require_brewfile() {
	if [[ ! -f "${BREWFILE}" ]]; then
		printf 'Brewfile not found: %s\n' "${BREWFILE}" >&2
		exit 1
	fi
}

## Parse supported CLI flags into script-level options.
parse_args() {
	while [[ "$#" -gt 0 ]]; do
		case "$1" in
		--dry-run)
			DRY_RUN=1
			shift
			;;
		--brewfile)
			if [[ "$#" -lt 2 ]]; then
				printf 'Missing value for --brewfile.\n' >&2
				usage >&2
				exit 1
			fi

			BREWFILE="$2"
			shift 2
			;;
		-h | --help)
			usage
			exit 0
			;;
		*)
			printf 'Unknown option: %s\n' "$1" >&2
			usage >&2
			exit 1
			;;
		esac
	done
}

## Configure Homebrew for deterministic non-interactive scheduled runs.
configure_homebrew_environment() {
	export HOMEBREW_NO_ANALYTICS=1
	export HOMEBREW_NO_ENV_HINTS=1
}

## Mirror script output to a timestamped log file and the current stdout.
setup_logging() {
	mkdir -p "${LOG_DIR}"

	local log_file="${LOG_DIR}/homebrew-maintenance.log"
	exec > >(
		while IFS= read -r line; do
			printf '[%s] %s\n' "$(/bin/date '+%Y-%m-%dT%H:%M:%S%z')" "${line}" | /usr/bin/tee -a "${log_file}"
		done
	) 2>&1

	log "Logging to ${log_file}."
}

## Remove this process's lock directory when the script exits.
release_lock() {
	if [[ ! -d "${LOCK_DIR}" ]]; then
		return 0
	fi

	local lock_pid=""
	if [[ -f "${LOCK_DIR}/pid" ]]; then
		lock_pid="$(<"${LOCK_DIR}/pid")"
	fi

	if [[ "${lock_pid}" == "$$" ]]; then
		rm -rf "${LOCK_DIR}"
	fi
}

## Acquire an atomic lock so overlapping launchd runs do not race Homebrew.
acquire_lock() {
	while true; do
		if mkdir "${LOCK_DIR}" 2>/dev/null; then
			printf '%s\n' "$$" >"${LOCK_DIR}/pid"
			trap release_lock EXIT
			trap 'release_lock; exit 130' INT
			trap 'release_lock; exit 143' TERM
			return 0
		fi

		local existing_pid=""
		if [[ -f "${LOCK_DIR}/pid" ]]; then
			existing_pid="$(<"${LOCK_DIR}/pid")"
		fi

		if [[ "${existing_pid}" =~ ^[0-9]+$ ]] && kill -0 "${existing_pid}" 2>/dev/null; then
			log "Another Homebrew maintenance run is active with PID ${existing_pid}; exiting."
			exit 0
		fi

		log "Removing stale lock at ${LOCK_DIR}."
		rm -rf "${LOCK_DIR}"
	done
}

## Update Homebrew, upgrade all known packages, and prune older cached artifacts.
run_homebrew_maintenance() {
	log "Using Brewfile: ${BREWFILE}."

	run_cmd brew update
	export HOMEBREW_NO_AUTO_UPDATE=1
	run_cmd brew bundle install --file "${BREWFILE}" --upgrade
	run_cmd brew upgrade --formula --no-ask
	run_cmd brew upgrade --cask --greedy --no-ask
	run_cmd brew cleanup --prune=14

	log "Homebrew maintenance finished."
}

## Coordinate validation, logging, locking, and the maintenance workflow.
main() {
	parse_args "$@"
	require_macos
	require_homebrew
	require_brewfile
	setup_logging
	configure_homebrew_environment
	acquire_lock
	run_homebrew_maintenance
}

main "$@"
