#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0
RESTART_AGENTS=1

## Print CLI usage for the macOS tuning script.
usage() {
	cat <<EOF
Usage: macos-performance-beauty.sh [options]

Apply conservative macOS performance and appearance defaults.

Options:
  --dry-run     Print intended changes without applying them
  --no-restart  Do not restart Dock, Finder, SystemUIServer, or cfprefsd
  -h, --help    Show this help message
EOF
}

## Print a consistent progress message.
log() {
	printf '==> %s\n' "$1"
}

## Run a command, or print it shell-escaped when dry-run mode is enabled.
run_cmd() {
	if [[ "${DRY_RUN}" -eq 1 ]]; then
		printf '[DRY] %q' "$1"
		shift
		local arg
		for arg in "$@"; do
			printf ' %q' "${arg}"
		done
		printf '\n'
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

## Parse supported CLI flags into script-level options.
parse_args() {
	while [[ "$#" -gt 0 ]]; do
		case "$1" in
		--dry-run)
			DRY_RUN=1
			shift
			;;
		--no-restart)
			RESTART_AGENTS=0
			shift
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

## Write a boolean macOS defaults value.
write_bool() {
	local domain="${1}"
	local key="${2}"
	local value="${3}"

	run_cmd defaults write "${domain}" "${key}" -bool "${value}"
}

## Write an integer macOS defaults value.
write_int() {
	local domain="${1}"
	local key="${2}"
	local value="${3}"

	run_cmd defaults write "${domain}" "${key}" -int "${value}"
}

## Write a floating-point macOS defaults value.
write_float() {
	local domain="${1}"
	local key="${2}"
	local value="${3}"

	run_cmd defaults write "${domain}" "${key}" -float "${value}"
}

## Write a string macOS defaults value.
write_string() {
	local domain="${1}"
	local key="${2}"
	local value="${3}"

	run_cmd defaults write "${domain}" "${key}" -string "${value}"
}

## Delete an optional preference key without failing when it is absent.
delete_key_if_present() {
	local domain="${1}"
	local key="${2}"

	if defaults read "${domain}" "${key}" >/dev/null 2>&1; then
		run_cmd defaults delete "${domain}" "${key}"
	elif [[ "${DRY_RUN}" -eq 1 ]]; then
		printf '[DRY] skip missing key: %s %s\n' "${domain}" "${key}"
	fi
}

## Configure global visual polish and low-latency interface behavior.
apply_global_interface_defaults() {
	log "Applying global interface defaults."

	write_string NSGlobalDomain AppleInterfaceStyle Dark
	write_int NSGlobalDomain AppleAccentColor 4
	write_string NSGlobalDomain AppleHighlightColor "0.698039 0.843137 1.000000 Blue"
	write_string NSGlobalDomain AppleShowScrollBars WhenScrolling
	write_float NSGlobalDomain NSWindowResizeTime 0.001
	write_bool NSGlobalDomain NSAutomaticWindowAnimationsEnabled false
	write_bool NSGlobalDomain NSAutomaticCapitalizationEnabled true
	write_bool NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled true
	write_bool NSGlobalDomain NSDocumentSaveNewDocumentsToCloud false
	write_bool NSGlobalDomain AppleMiniaturizeOnDoubleClick false
	write_string NSGlobalDomain AppleActionOnDoubleClick Maximize
	write_bool NSGlobalDomain com.apple.springing.enabled true
	write_float NSGlobalDomain com.apple.springing.delay 0.5
}

## Configure a compact, responsive Dock and faster Mission Control animation.
apply_dock_defaults() {
	log "Applying Dock and Mission Control defaults."

	write_bool com.apple.dock autohide true
	write_float com.apple.dock autohide-delay 0
	write_float com.apple.dock autohide-time-modifier 0.22
	write_float com.apple.dock expose-animation-duration 0.12
	write_bool com.apple.dock magnification true
	write_int com.apple.dock tilesize 46
	write_int com.apple.dock largesize 120
	write_string com.apple.dock mineffect scale
	write_bool com.apple.dock minimize-to-application true
	write_bool com.apple.dock show-recents false
	write_bool com.apple.dock mru-spaces false
}

## Configure Finder for predictable, developer-friendly file browsing.
apply_finder_defaults() {
	log "Applying Finder defaults."

	write_bool com.apple.finder AppleShowAllExtensions true
	write_bool NSGlobalDomain AppleShowAllExtensions true
	write_bool com.apple.finder ShowPathbar true
	write_bool com.apple.finder ShowStatusBar true
	write_bool com.apple.finder FXEnableExtensionChangeWarning false
	write_string com.apple.finder FXPreferredViewStyle Nlsv
	write_bool com.apple.finder _FXShowPosixPathInTitle true
	write_string com.apple.finder FXDefaultSearchScope SCcf
	write_bool com.apple.finder WarnOnEmptyTrash true
	write_bool com.apple.desktopservices DSDontWriteNetworkStores true
	write_bool com.apple.desktopservices DSDontWriteUSBStores true
}

## Configure Stage Manager and window tiling defaults from the chosen profile.
apply_window_manager_defaults() {
	log "Applying window management defaults."

	write_bool com.apple.WindowManager GloballyEnabled true
	write_bool com.apple.WindowManager GloballyEnabledEver true
	write_int com.apple.WindowManager AppWindowGroupingBehavior 1
	write_bool com.apple.WindowManager EnableTiledWindowMargins false
	write_bool com.apple.WindowManager HideDesktop false
	write_bool com.apple.WindowManager StandardHideDesktopIcons true
	write_bool com.apple.WindowManager StandardHideWidgets false
	write_bool com.apple.WindowManager StageManagerHideWidgets false
}

## Configure portable trackpad gestures, including essential three-finger drag.
apply_trackpad_defaults() {
	log "Applying trackpad defaults."

	local domain
	for domain in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
		write_bool "${domain}" TrackpadRightClick true
		write_bool "${domain}" TrackpadScroll true
		write_bool "${domain}" TrackpadHorizScroll true
		write_bool "${domain}" TrackpadMomentumScroll true
		write_bool "${domain}" TrackpadPinch true
		write_bool "${domain}" TrackpadRotate true
		write_bool "${domain}" Dragging false
		write_bool "${domain}" DragLock false
		write_int "${domain}" TrackpadThreeFingerDrag 1
		write_int "${domain}" TrackpadThreeFingerTapGesture 2
		write_int "${domain}" TrackpadThreeFingerHorizSwipeGesture 0
		write_int "${domain}" TrackpadThreeFingerVertSwipeGesture 0
		write_int "${domain}" TrackpadFourFingerHorizSwipeGesture 2
		write_int "${domain}" TrackpadFourFingerVertSwipeGesture 2
		write_int "${domain}" TrackpadFourFingerPinchGesture 2
		write_int "${domain}" TrackpadFiveFingerPinchGesture 2
		write_int "${domain}" TrackpadTwoFingerDoubleTapGesture 1
		write_int "${domain}" TrackpadTwoFingerFromRightEdgeSwipeGesture 3
	done

	write_bool NSGlobalDomain com.apple.swipescrolldirection true
	write_bool NSGlobalDomain com.apple.trackpad.forceClick false
	write_float NSGlobalDomain com.apple.trackpad.scaling 1.5
}

## Configure screenshot output without forcing a machine-specific folder.
apply_screenshot_defaults() {
	log "Applying screenshot defaults."

	write_string com.apple.screencapture type png
	write_bool com.apple.screencapture disable-shadow false
	delete_key_if_present com.apple.screencapture location
}

## Restart UI agents that cache the preferences touched by this script.
restart_ui_agents() {
	if [[ "${RESTART_AGENTS}" -eq 0 ]]; then
		log "Skipping UI agent restarts."
		return 0
	fi

	log "Restarting UI agents so settings take effect."
	run_cmd killall cfprefsd || true
	run_cmd killall Dock || true
	run_cmd killall Finder || true
	run_cmd killall SystemUIServer || true
}

## Orchestrate argument parsing, preference writes, and UI refreshes.
main() {
	parse_args "$@"
	require_macos

	apply_global_interface_defaults
	apply_dock_defaults
	apply_finder_defaults
	apply_window_manager_defaults
	apply_trackpad_defaults
	apply_screenshot_defaults
	restart_ui_agents

	log "macOS performance and appearance defaults complete."
}

main "$@"
