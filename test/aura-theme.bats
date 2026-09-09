#!/usr/bin/env bats
# shellcheck disable=SC2154

# Resolves repository paths for Aura Dark palette checks.
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
}

# Verifies that every visual config uses the canonical Aura Dark tokens.
function configs_share_aura_dark_palette { #@test
  for path in \
    "${WEZTERM_CONFIG}" \
    "${TMUX_CONFIG}" \
    "${ZSHRC}" \
    "${NVIM_COLORSCHEME}"; do
    grep -Fq '#15141b' "${path}"
    grep -Fq '#edecee' "${path}"
    grep -Fq '#a277ff' "${path}"
    grep -Fq '#61ffca' "${path}"
  done

  grep -Fq 'config.color_scheme = "Aura Dark"' "${WEZTERM_CONFIG}"
  grep -Fq '"workbench.colorTheme": "Aura Dark"' "${VSCODIUM_SETTINGS}"
  grep -Fqix 'daltonmenezes.aura-theme' "${VSCODIUM_EXTENSIONS}"
  grep -Fq 'aura-dark' "${NVIM_COLORSCHEME}"
  grep -Fq 'ddipnaombfnagpagnpdkdinoekfhfjoh' "${BROWSER_EXTENSIONS}"
  grep -Fq 'syntax-theme = ansi' "${GITCONFIG}"
  grep -Fq '#a277ff' "${GITCONFIG}"
  grep -Fq '#61ffca' "${GITCONFIG}"
  grep -Fq 'ZSH_THEME=""' "${ZSHRC}"
  grep -Fq '38;2;162;119;255' "${ZSHRC}"
}

# Verifies WezTerm still parses after the Aura scheme was added.
function wezterm_accepts_aura_dark_scheme { #@test
  if ! command -v wezterm >/dev/null 2>&1; then
    skip "wezterm is not installed"
  fi

  run wezterm --config-file "${WEZTERM_CONFIG}" show-keys --lua
  [ "${status}" -eq 0 ]
}
