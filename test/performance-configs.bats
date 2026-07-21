#!/usr/bin/env bats
# shellcheck disable=SC2154

# Resolves the repository and performance-sensitive configuration paths.
setup() {
  PROJECT_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  WEZTERM_CONFIG="${PROJECT_ROOT}/wezterm/.config/wezterm/wezterm.lua"
  CODEX_CONFIG="${PROJECT_ROOT}/codex/.codex/config.toml"
}

# Verifies that WezTerm balances polished rendering with bounded compositor work.
function wezterm_uses_balanced_visual_performance_profile { #@test
  grep -Fqx 'config.webgpu_power_preference = "LowPower"' "${WEZTERM_CONFIG}"
  grep -Fqx 'config.max_fps = 60' "${WEZTERM_CONFIG}"
  grep -Fqx 'config.animation_fps = 30' "${WEZTERM_CONFIG}"
  grep -Fqx 'config.cursor_blink_rate = 700' "${WEZTERM_CONFIG}"
  grep -Fqx 'config.window_background_opacity = 0.92' "${WEZTERM_CONFIG}"
  grep -Fqx 'config.macos_window_background_blur = 12' "${WEZTERM_CONFIG}"

  if command -v wezterm >/dev/null 2>&1; then
    run wezterm --config-file "${WEZTERM_CONFIG}" show-keys --lua
    [ "${status}" -eq 0 ]
  fi
}

# Verifies that Codex keeps TUI motion while avoiding activity-title redraws.
function codex_uses_animated_tui_with_stable_title { #@test
  grep -Fqx 'animations = true' "${CODEX_CONFIG}"
  grep -Fqx 'terminal_title = ["project-name"]' "${CODEX_CONFIG}"
}
