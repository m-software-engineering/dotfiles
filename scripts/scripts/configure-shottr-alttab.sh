#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0
CHECK_ARCHIVE=0

SHOTTR_DOMAIN="cc.ffitch.shottr"
SHOTTR_AREA_KEY="KeyboardShortcuts_area"
# Command-S. Carbon cmdKey is 256; kVK_ANSI_S is 1.
# KeyboardShortcuts stores this JSON for Shottr's area-capture hotkey.
SHOTTR_AREA_VALUE='{"carbonKeyCode":1,"carbonModifiers":256}'

ALTTAB_DOMAIN="com.lwouis.alt-tab-macos"

usage() {
	cat << 'EOF'
Usage: configure-shottr-alttab.sh [--dry-run] [--check-archive]

Set Shottr area capture to Command-S and make AltTab the Command-Tab switcher.

Options:
  --dry-run        Print the intended preference writes without applying them
  --check-archive  Verify the AltTab shortcut archive and exit
  -h, --help       Show this help message
EOF
}

log() {
	printf '==> %s\n' "$1"
}

parse_args() {
	while [[ "$#" -gt 0 ]]; do
		case "$1" in
		--dry-run)
			DRY_RUN=1
			shift
			;;
		--check-archive)
			CHECK_ARCHIVE=1
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

require_macos() {
	if [[ "$(uname -s)" != "Darwin" ]]; then
		printf 'This script is macOS-only.\n' >&2
		exit 1
	fi
}

apply_shottr_shortcut() {
	log "Setting Shottr area capture to Command-S."
	if [[ "${DRY_RUN}" -eq 1 ]]; then
		printf '[DRY] defaults write %s %s -string %s\n' \
			"${SHOTTR_DOMAIN}" "${SHOTTR_AREA_KEY}" "${SHOTTR_AREA_VALUE}"
		return 0
	fi

	if ! defaults write "${SHOTTR_DOMAIN}" "${SHOTTR_AREA_KEY}" -string "${SHOTTR_AREA_VALUE}"; then
		log "Unable to write Shottr preferences. Grant Shottr preference access if macOS prompts, then rerun."
		return 1
	fi
}

alttab_swift() {
	cat << 'EOF'
import Foundation

@objc(SRShortcut)
final class SRShortcut: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool { true }

    let keyCode: UInt16
    let modifierFlags: UInt
    let characters: String?
    let charactersIgnoringModifiers: String?

    init(keyCode: UInt16, modifierFlags: UInt, characters: String?, ignoring: String?) {
        self.keyCode = keyCode
        self.modifierFlags = modifierFlags
        self.characters = characters
        self.charactersIgnoringModifiers = ignoring
    }

    required init?(coder: NSCoder) {
        keyCode = (coder.decodeObject(of: NSNumber.self, forKey: "keyCode") ?? 0).uint16Value
        modifierFlags = (coder.decodeObject(of: NSNumber.self, forKey: "modifierFlags") ?? 0).uintValue
        characters = coder.decodeObject(of: NSString.self, forKey: "characters") as String?
        charactersIgnoringModifiers = coder.decodeObject(of: NSString.self, forKey: "charactersIgnoringModifiers") as String?
    }

    func encode(with coder: NSCoder) {
        coder.encode("1" as NSString, forKey: "version")
        coder.encode(NSNumber(value: keyCode), forKey: "keyCode")
        coder.encode(NSNumber(value: modifierFlags), forKey: "modifierFlags")
        if let characters {
            coder.encode(characters as NSString, forKey: "characters")
        }
        if let charactersIgnoringModifiers {
            coder.encode(charactersIgnoringModifiers as NSString, forKey: "charactersIgnoringModifiers")
        }
    }
}

func archive(_ shortcut: SRShortcut) throws -> Data {
    try NSKeyedArchiver.archivedData(withRootObject: shortcut, requiringSecureCoding: true)
}

func storage(string: String, shortcut: SRShortcut) throws -> [String: Any] {
    ["string": string, "secureData": try archive(shortcut)]
}

func shortcut(from data: Data) throws -> SRShortcut {
    guard let shortcut = try NSKeyedUnarchiver.unarchivedObject(ofClass: SRShortcut.self, from: data) else {
        throw NSError(domain: "configure-shottr-alttab", code: 1)
    }
    return shortcut
}

let commandOnly = SRShortcut(keyCode: UInt16.max, modifierFlags: 1 << 20, characters: "⌘", ignoring: "")
let tab = SRShortcut(keyCode: 48, modifierFlags: 0, characters: "⇥", ignoring: "⇥")
let hold = try storage(string: "⌘", shortcut: commandOnly)
let next = try storage(string: "⇥", shortcut: tab)
let mode = CommandLine.arguments.dropFirst().first ?? "check"

if mode == "check" {
    let decodedHold = try shortcut(from: hold["secureData"] as! Data)
    let decodedNext = try shortcut(from: next["secureData"] as! Data)
    guard decodedHold.keyCode == UInt16.max, decodedHold.modifierFlags == (1 << 20) else {
        fputs("hold shortcut archive mismatch\n", stderr)
        exit(1)
    }
    guard decodedNext.keyCode == 48, decodedNext.modifierFlags == 0 else {
        fputs("tab shortcut archive mismatch\n", stderr)
        exit(1)
    }
    guard (hold["secureData"] as! Data).contains(Data("SRShortcut".utf8)) else {
        fputs("archive is not an SRShortcut\n", stderr)
        exit(1)
    }
    print("alttab-archive-ok")
    exit(0)
}

let domain = "com.lwouis.alt-tab-macos" as CFString
CFPreferencesSetAppValue("holdShortcut" as CFString, hold as CFPropertyList, domain)
CFPreferencesSetAppValue("nextWindowShortcut" as CFString, next as CFPropertyList, domain)
CFPreferencesSetAppValue("startAtLogin" as CFString, "true" as CFString, domain)
if !CFPreferencesAppSynchronize(domain) {
    fputs("unable to synchronize AltTab preferences\n", stderr)
    exit(1)
}
print("alttab-preferences-written")
EOF
}

apply_alttab_shortcut() {
	log "Setting AltTab to hold Command and press Tab."
	if [[ "${DRY_RUN}" -eq 1 ]]; then
		printf '[DRY] %s holdShortcut string=⌘ keyCode=65535 modifiers=1048576\n' "${ALTTAB_DOMAIN}"
		printf '[DRY] %s nextWindowShortcut string=⇥ keyCode=48 modifiers=0\n' "${ALTTAB_DOMAIN}"
		printf '[DRY] %s startAtLogin true\n' "${ALTTAB_DOMAIN}"
		return 0
	fi

	if ! command -v swift > /dev/null 2>&1; then
		log "swift not found. Skipping AltTab shortcut write."
		return 1
	fi

	local swift_file
	swift_file="$(mktemp "${TMPDIR:-/tmp}/configure-alttab.XXXXXX.swift")"
	alttab_swift > "${swift_file}"
	if ! swift "${swift_file}" apply; then
		rm -f "${swift_file}"
		log "Unable to write AltTab preferences."
		return 1
	fi
	rm -f "${swift_file}"

	if [[ -d "/Applications/AltTab.app" ]]; then
		killall AltTab > /dev/null 2>&1 || true
		open -g -a "/Applications/AltTab.app" || true
		log "AltTab relaunched. Grant Accessibility if macOS asks, or Command-Tab stays with the system switcher."
	fi
}

check_alttab_archive() {
	if ! command -v swift > /dev/null 2>&1; then
		printf 'swift not found\n' >&2
		exit 1
	fi
	local swift_file
	swift_file="$(mktemp "${TMPDIR:-/tmp}/configure-alttab.XXXXXX.swift")"
	alttab_swift > "${swift_file}"
	swift "${swift_file}" check
	local status=$?
	rm -f "${swift_file}"
	exit "${status}"
}

main() {
	parse_args "$@"
	require_macos
	if [[ "${CHECK_ARCHIVE}" -eq 1 ]]; then
		check_alttab_archive
	fi
	local failed=0
	apply_shottr_shortcut || failed=1
	apply_alttab_shortcut || failed=1
	if [[ "${failed}" -ne 0 ]]; then
		log "Shottr or AltTab shortcut setup did not fully apply."
		exit 1
	fi
	log "Shottr and AltTab shortcuts configured."
}

main "$@"
