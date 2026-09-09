local aura = {
  purple = "#a277ff",
  green = "#61ffca",
  orange = "#ffca85",
  pink = "#f694ff",
  blue = "#82e2ff",
  red = "#ff6767",
  fg = "#edecee",
  gray = "#6d6d6d",
  bg = "#15141b",
  surface = "#29263c",
}

---Applies LazyVim UI highlights that the Aura port does not cover.
local function apply_aura_ui()
  vim.api.nvim_set_hl(0, "NormalFloat", { fg = aura.fg, bg = aura.bg })
  vim.api.nvim_set_hl(0, "FloatBorder", { fg = aura.purple, bg = aura.bg })
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = aura.surface })
  vim.api.nvim_set_hl(0, "SnacksIndent", { fg = aura.surface })
  vim.api.nvim_set_hl(0, "SnacksIndentScope", { fg = aura.purple })
  vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = aura.purple, bold = true })
  vim.api.nvim_set_hl(0, "SnacksDashboardKey", { fg = aura.green, bold = true })
  vim.api.nvim_set_hl(0, "SnacksDashboardDesc", { fg = aura.fg })
  vim.api.nvim_set_hl(0, "SnacksDashboardIcon", { fg = aura.blue })
  vim.api.nvim_set_hl(0, "SnacksDashboardFooter", { fg = aura.gray })
  vim.api.nvim_set_hl(0, "FlashLabel", { fg = aura.bg, bg = aura.purple, bold = true })
  vim.api.nvim_set_hl(0, "FlashMatch", { fg = aura.green })
  vim.api.nvim_set_hl(0, "FlashCurrent", { fg = aura.orange, bold = true })
  vim.api.nvim_set_hl(0, "WhichKey", { fg = aura.green })
  vim.api.nvim_set_hl(0, "WhichKeyGroup", { fg = aura.purple })
  vim.api.nvim_set_hl(0, "WhichKeyDesc", { fg = aura.fg })
  vim.api.nvim_set_hl(0, "WhichKeySeparator", { fg = aura.gray })
  vim.api.nvim_set_hl(0, "DiagnosticError", { fg = aura.red })
  vim.api.nvim_set_hl(0, "DiagnosticWarn", { fg = aura.orange })
  vim.api.nvim_set_hl(0, "DiagnosticInfo", { fg = aura.blue })
  vim.api.nvim_set_hl(0, "DiagnosticHint", { fg = aura.green })
end

---Loads Aura Dark from the official neovim port.
local function load_aura_dark(plugin)
  vim.opt.rtp:append(plugin.dir .. "/packages/neovim")
  vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "aura*",
    callback = apply_aura_ui,
  })
  vim.cmd.colorscheme("aura-dark")
  apply_aura_ui()
end

return {
  {
    "baliestri/aura-theme",
    lazy = false,
    priority = 1000,
    config = load_aura_dark,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        vim.cmd.colorscheme("aura-dark")
        apply_aura_ui()
      end,
    },
  },
}
