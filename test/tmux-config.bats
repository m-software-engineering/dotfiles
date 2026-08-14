#!/usr/bin/env bats
# shellcheck disable=SC2154

# Resolves the repository and tmux configuration paths.
setup() {
  PROJECT_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  TMUX_CONFIG="${PROJECT_ROOT}/tmux/.config/tmux/tmux.conf"
  WEZTERM_CONFIG="${PROJECT_ROOT}/wezterm/.config/wezterm/wezterm.lua"
  ZSHRC="${PROJECT_ROOT}/zsh/.zshrc"
  TMUX_SOCKET="dotfiles-tmux-config-test"
}

# Tears down the isolated tmux server used to parse the config.
teardown() {
  if command -v tmux >/dev/null 2>&1; then
    tmux -L "${TMUX_SOCKET}" kill-server >/dev/null 2>&1 || true
  fi
}

# Verifies prefix, current-path splits, and that Ctrl-d is not rebound.
function tmux_uses_ctrl_space_prefix_and_bar_dash_splits { #@test
  grep -Fqx 'set -g prefix C-Space' "${TMUX_CONFIG}"
  grep -Fqx 'bind | split-window -h -c "#{pane_current_path}"' "${TMUX_CONFIG}"
  grep -Fqx 'bind - split-window -v -c "#{pane_current_path}"' "${TMUX_CONFIG}"
  ! grep -E 'bind(-key)?[[:space:]].*C-d' "${TMUX_CONFIG}"

  if command -v tmux >/dev/null 2>&1; then
    run tmux -L "${TMUX_SOCKET}" -f "${TMUX_CONFIG}" start-server \; list-keys
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"C-Space"* ]]
    [[ "${output}" == *"split-window -h"* ]]
    [[ "${output}" == *"split-window -v"* ]]
  fi
}

# Verifies WezTerm forwards Ctrl+Space and zsh ignores a single EOF.
function wezterm_and_zsh_protect_tmux_prefix_and_eof { #@test
  grep -Fq 'key = "Space"' "${WEZTERM_CONFIG}"
  grep -Fq 'mods = "CTRL"' "${WEZTERM_CONFIG}"
  grep -Fqx 'setopt IGNORE_EOF' "${ZSHRC}"
}
