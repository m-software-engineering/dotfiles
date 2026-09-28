#!/usr/bin/env bats
# shellcheck disable=SC2154

setup() {
  PROJECT_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  MACOS_APPEARANCE="${PROJECT_ROOT}/scripts/scripts/macos-performance-beauty.sh"
  WINDOW_TOOLS="${PROJECT_ROOT}/scripts/scripts/configure-shottr-alttab.sh"
}

# Light mode is the absence of AppleInterfaceStyle. Writing "Light" is ignored.
function macos_profile_defaults_to_light_appearance { #@test
  grep -Fq 'delete_key_if_present NSGlobalDomain AppleInterfaceStyle' "${MACOS_APPEARANCE}"
  grep -Fq 'AppleInterfaceStyleSwitchesAutomatically false' "${MACOS_APPEARANCE}"
  ! grep -Fq 'AppleInterfaceStyle Dark' "${MACOS_APPEARANCE}"
}

# Shottr and AltTab ignore a plain shortcut string and fall back to their defaults.
function shottr_and_alttab_shortcuts_use_the_formats_those_apps_keep { #@test
  grep -Fq 'KeyboardShortcuts_area' "${WINDOW_TOOLS}"
  grep -Fq '{"carbonKeyCode":1,"carbonModifiers":256}' "${WINDOW_TOOLS}"
  grep -Fq 'com.lwouis.alt-tab-macos' "${WINDOW_TOOLS}"
  grep -Fq 'SRShortcut' "${WINDOW_TOOLS}"
}
