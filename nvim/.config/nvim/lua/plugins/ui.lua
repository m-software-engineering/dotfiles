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

return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.theme = {
        normal = {
          a = { fg = latte.base, bg = latte.mauve, gui = "bold" },
          b = { fg = latte.text, bg = latte.surface },
          c = { fg = latte.subtext, bg = latte.base },
        },
        insert = {
          a = { fg = latte.base, bg = latte.green, gui = "bold" },
          b = { fg = latte.text, bg = latte.surface },
          c = { fg = latte.subtext, bg = latte.base },
        },
        visual = {
          a = { fg = latte.base, bg = latte.peach, gui = "bold" },
          b = { fg = latte.text, bg = latte.surface },
          c = { fg = latte.subtext, bg = latte.base },
        },
        replace = {
          a = { fg = latte.base, bg = latte.red, gui = "bold" },
          b = { fg = latte.text, bg = latte.surface },
          c = { fg = latte.subtext, bg = latte.base },
        },
        command = {
          a = { fg = latte.base, bg = latte.pink, gui = "bold" },
          b = { fg = latte.text, bg = latte.surface },
          c = { fg = latte.subtext, bg = latte.base },
        },
        inactive = {
          a = { fg = latte.subtext, bg = latte.base },
          b = { fg = latte.subtext, bg = latte.base },
          c = { fg = latte.subtext, bg = latte.base },
        },
      }
      opts.options.component_separators = { left = "│", right = "│" }
      opts.options.section_separators = { left = "", right = "" }
    end,
  },
  {
    "akinsho/bufferline.nvim",
    optional = true,
    opts = {
      highlights = {
        fill = { bg = latte.base },
        background = { fg = latte.subtext, bg = latte.base },
        buffer_visible = { fg = latte.subtext, bg = latte.base },
        buffer_selected = { fg = latte.green, bg = latte.surface, bold = true, italic = false },
        tab = { fg = latte.subtext, bg = latte.base },
        tab_selected = { fg = latte.green, bg = latte.surface, bold = true },
        close_button = { fg = latte.subtext, bg = latte.base },
        close_button_selected = { fg = latte.red, bg = latte.surface },
        separator = { fg = latte.base, bg = latte.base },
        separator_selected = { fg = latte.base, bg = latte.surface },
        modified = { fg = latte.peach, bg = latte.base },
        modified_selected = { fg = latte.peach, bg = latte.surface },
        indicator_selected = { fg = latte.mauve, bg = latte.surface },
      },
    },
  },
  {
    "folke/snacks.nvim",
    opts = {
      indent = {
        char = "│",
        scope = { char = "│" },
      },
      dashboard = {
        preset = {
          header = [[
   █████╗ ██╗   ██╗██████╗  █████╗
  ██╔══██╗██║   ██║██╔══██╗██╔══██╗
  ███████║██║   ██║██████╔╝███████║
  ██╔══██║██║   ██║██╔══██╗██╔══██║
  ██║  ██║╚██████╔╝██║  ██║██║  ██║
  ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
          LazyVim  ·  Catppuccin Latte]],
        },
      },
    },
  },
}
