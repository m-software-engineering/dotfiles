local latte = {
  mauve = "#8839ef",
  green = "#40a02b",
  peach = "#fe640b",
  pink = "#ea76cb",
  blue = "#1e66f5",
  red = "#d20f39",
  text = "#4c4f69",
  subtext = "#6c6f85",
  base = "#eff1f5",
  surface = "#ccd0da",
}

---Applies LazyVim UI highlights on top of Catppuccin Latte.
local function apply_latte_ui()
  vim.api.nvim_set_hl(0, "NormalFloat", { fg = latte.text, bg = latte.base })
  vim.api.nvim_set_hl(0, "FloatBorder", { fg = latte.mauve, bg = latte.base })
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = latte.surface })
  vim.api.nvim_set_hl(0, "SnacksIndent", { fg = latte.surface })
  vim.api.nvim_set_hl(0, "SnacksIndentScope", { fg = latte.mauve })
  vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = latte.mauve, bold = true })
  vim.api.nvim_set_hl(0, "SnacksDashboardKey", { fg = latte.green, bold = true })
  vim.api.nvim_set_hl(0, "SnacksDashboardDesc", { fg = latte.text })
  vim.api.nvim_set_hl(0, "SnacksDashboardIcon", { fg = latte.blue })
  vim.api.nvim_set_hl(0, "SnacksDashboardFooter", { fg = latte.subtext })
  vim.api.nvim_set_hl(0, "FlashLabel", { fg = latte.base, bg = latte.mauve, bold = true })
  vim.api.nvim_set_hl(0, "FlashMatch", { fg = latte.green })
  vim.api.nvim_set_hl(0, "FlashCurrent", { fg = latte.peach, bold = true })
  vim.api.nvim_set_hl(0, "WhichKey", { fg = latte.green })
  vim.api.nvim_set_hl(0, "WhichKeyGroup", { fg = latte.mauve })
  vim.api.nvim_set_hl(0, "WhichKeyDesc", { fg = latte.text })
  vim.api.nvim_set_hl(0, "WhichKeySeparator", { fg = latte.subtext })
  vim.api.nvim_set_hl(0, "DiagnosticError", { fg = latte.red })
  vim.api.nvim_set_hl(0, "DiagnosticWarn", { fg = latte.peach })
  vim.api.nvim_set_hl(0, "DiagnosticInfo", { fg = latte.blue })
  vim.api.nvim_set_hl(0, "DiagnosticHint", { fg = latte.green })
end

---Loads Catppuccin Latte and reapplies the shared UI highlights.
local function load_catppuccin_latte()
  vim.cmd.colorscheme("catppuccin-latte")
  apply_latte_ui()
end

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "latte",
      background = {
        light = "latte",
        dark = "latte",
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      load_catppuccin_latte()
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        load_catppuccin_latte()
      end,
    },
  },
}
