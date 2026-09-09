#!/usr/bin/env bats
# shellcheck disable=SC2154

# Resolves Neovim / LazyVim configuration paths.
setup() {
  PROJECT_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  NVIM_INIT="${PROJECT_ROOT}/nvim/.config/nvim/init.lua"
  NVIM_LAZY="${PROJECT_ROOT}/nvim/.config/nvim/lua/config/lazy.lua"
  NVIM_COLORSCHEME="${PROJECT_ROOT}/nvim/.config/nvim/lua/plugins/colorscheme.lua"
  NVIM_UI="${PROJECT_ROOT}/nvim/.config/nvim/lua/plugins/ui.lua"

  BREWFILE="${PROJECT_ROOT}/homebrew/.config/homebrew/Brewfile"
}

# Verifies LazyVim bootstrap, Aura Dark, and useful language extras.
function nvim_uses_lazyvim_with_aura_dark { #@test
  grep -Fqx 'require("config.lazy")' "${NVIM_INIT}"
  grep -Fq '{ "LazyVim/LazyVim", import = "lazyvim.plugins" }' "${NVIM_LAZY}"
  grep -Fq '"baliestri/aura-theme"' "${NVIM_COLORSCHEME}"
  grep -Fq 'aura-dark' "${NVIM_COLORSCHEME}"
  grep -Fq 'aura-dark' "${NVIM_LAZY}"
  grep -Fq 'nvim-lualine/lualine.nvim' "${NVIM_UI}"
  grep -Fq 'LazyVim  ·  Aura Dark' "${NVIM_UI}"
  grep -Fq 'lazyvim.plugins.extras.lang.typescript' "${NVIM_LAZY}"
  grep -Fq 'lazyvim.plugins.extras.lang.python' "${NVIM_LAZY}"
  grep -Fq 'lazyvim.plugins.extras.lang.go' "${NVIM_LAZY}"
}

# Verifies Homebrew ships Neovim, LazyVim tools, and the nerd font.
function brewfile_includes_neovim_lazyvim_tools { #@test
  grep -Fq 'brew "neovim"' "${BREWFILE}"
  grep -Fq 'brew "ripgrep"' "${BREWFILE}"
  grep -Fq 'brew "fd"' "${BREWFILE}"
  grep -Fq 'brew "lazygit"' "${BREWFILE}"
  grep -Fq 'cask "font-fira-code-nerd-font"' "${BREWFILE}"
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
