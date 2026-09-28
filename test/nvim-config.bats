#!/usr/bin/env bats
# shellcheck disable=SC2154

setup() {
  PROJECT_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  NVIM_INIT="${PROJECT_ROOT}/nvim/.config/nvim/init.lua"
  NVIM_LAZY="${PROJECT_ROOT}/nvim/.config/nvim/lua/config/lazy.lua"
  NVIM_COLORSCHEME="${PROJECT_ROOT}/nvim/.config/nvim/lua/plugins/colorscheme.lua"
  NVIM_UI="${PROJECT_ROOT}/nvim/.config/nvim/lua/plugins/ui.lua"
}

# Verifies packaged Lua config files parse without bootstrapping plugins.
function nvim_lua_config_files_parse { #@test
  if ! command -v nvim >/dev/null 2>&1; then
    skip "nvim is not installed"
  fi

  local lua_file
  for lua_file in \
    "${NVIM_INIT}" \
    "${NVIM_LAZY}" \
    "${NVIM_COLORSCHEME}" \
    "${NVIM_UI}"; do
    run nvim --clean --headless -u NONE \
      -c "lua assert(loadfile([[${lua_file}]]))" \
      -c "qa"
    [ "${status}" -eq 0 ]
  done
}
