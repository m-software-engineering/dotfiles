#!/usr/bin/env bats
# shellcheck disable=SC2154

# Resolves repository paths for Catppuccin Latte palette checks.
setup() {
  PROJECT_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  WEZTERM_CONFIG="${PROJECT_ROOT}/wezterm/.config/wezterm/wezterm.lua"
  TMUX_CONFIG="${PROJECT_ROOT}/tmux/.config/tmux/tmux.conf"
  ZSHRC="${PROJECT_ROOT}/zsh/.zshrc"
  GITCONFIG="${PROJECT_ROOT}/git/.gitconfig"
  VSCODIUM_SETTINGS="${PROJECT_ROOT}/vscodium/Library/Application Support/VSCodium/User/settings.json"
  VSCODIUM_EXTENSIONS="${PROJECT_ROOT}/vscodium/vscodium-extensions.txt"
  NVIM_COLORSCHEME="${PROJECT_ROOT}/nvim/.config/nvim/lua/plugins/colorscheme.lua"
  BROWSER_EXTENSIONS="${PROJECT_ROOT}/browser/extensions-ids.txt"
  MACOS_APPEARANCE="${PROJECT_ROOT}/scripts/scripts/macos-performance-beauty.sh"
  BREWFILE="${PROJECT_ROOT}/homebrew/.config/homebrew/Brewfile"
  WINDOW_TOOLS="${PROJECT_ROOT}/scripts/scripts/configure-shottr-alttab.sh"
}

# Verifies that every visual config uses the canonical Catppuccin Latte tokens.
function configs_share_catppuccin_latte_palette { #@test
  for path in \
    "${WEZTERM_CONFIG}" \
    "${TMUX_CONFIG}" \
    "${ZSHRC}" \
    "${NVIM_COLORSCHEME}"; do
    grep -Fq '#eff1f5' "${path}"
    grep -Fq '#4c4f69' "${path}"
    grep -Fq '#8839ef' "${path}"
    grep -Fq '#40a02b' "${path}"
  done

  grep -Fq 'config.color_scheme = "Catppuccin Latte"' "${WEZTERM_CONFIG}"
  grep -Fq '"workbench.colorTheme": "Catppuccin Latte"' "${VSCODIUM_SETTINGS}"
  grep -Fq '"workbench.preferredLightColorTheme": "Catppuccin Latte"' "${VSCODIUM_SETTINGS}"
  grep -Fqix 'Catppuccin.catppuccin-vsc' "${VSCODIUM_EXTENSIONS}"
  grep -Fq 'catppuccin-latte' "${NVIM_COLORSCHEME}"
  grep -Fq 'jhjnalhegpceacdhbplhnakmkdliaddd' "${BROWSER_EXTENSIONS}"
  grep -Fq 'syntax-theme = ansi' "${GITCONFIG}"
  grep -Fq 'light = true' "${GITCONFIG}"
  ! grep -Fq 'dark = true' "${GITCONFIG}"
  grep -Fq '#8839ef' "${GITCONFIG}"
  grep -Fq '#40a02b' "${GITCONFIG}"
  grep -Fq 'ZSH_THEME=""' "${ZSHRC}"
  grep -Fq '38;2;136;57;239' "${ZSHRC}"
  ! grep -RFq 'Aura Dark' "${PROJECT_ROOT}/wezterm" "${PROJECT_ROOT}/nvim" "${PROJECT_ROOT}/vscodium" "${PROJECT_ROOT}/README.md"
}

# Verifies WezTerm still parses after the Latte scheme was added.
function wezterm_accepts_catppuccin_latte_scheme { #@test
  if ! command -v wezterm >/dev/null 2>&1; then
    skip "wezterm is not installed"
  fi

  run wezterm --config-file "${WEZTERM_CONFIG}" show-keys --lua
  [ "${status}" -eq 0 ]
}

# Verifies the macOS profile defaults to light appearance.
function macos_profile_defaults_to_light_appearance { #@test
  grep -Fq 'delete_key_if_present NSGlobalDomain AppleInterfaceStyle' "${MACOS_APPEARANCE}"
  grep -Fq 'AppleInterfaceStyleSwitchesAutomatically false' "${MACOS_APPEARANCE}"
  ! grep -Fq 'AppleInterfaceStyle Dark' "${MACOS_APPEARANCE}"
}

# Verifies Shottr and AltTab are installed and their shortcuts are declared.
function brewfile_installs_shottr_and_alttab { #@test
  grep -Fq 'cask "shottr"' "${BREWFILE}"
  grep -Fq 'Screenshot measurement and annotation tool' "${BREWFILE}"
  grep -Fq 'cask "alt-tab"' "${BREWFILE}"
  grep -Fq 'Enable Windows-like alt-tab' "${BREWFILE}"
  grep -Fq 'KeyboardShortcuts_area' "${WINDOW_TOOLS}"
  grep -Fq '{"carbonKeyCode":1,"carbonModifiers":256}' "${WINDOW_TOOLS}"
  grep -Fq 'com.lwouis.alt-tab-macos' "${WINDOW_TOOLS}"
}
