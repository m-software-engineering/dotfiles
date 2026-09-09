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

return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.theme = {
        normal = {
          a = { fg = aura.bg, bg = aura.purple, gui = "bold" },
          b = { fg = aura.fg, bg = aura.surface },
          c = { fg = aura.gray, bg = aura.bg },
        },
        insert = {
          a = { fg = aura.bg, bg = aura.green, gui = "bold" },
          b = { fg = aura.fg, bg = aura.surface },
          c = { fg = aura.gray, bg = aura.bg },
        },
        visual = {
          a = { fg = aura.bg, bg = aura.orange, gui = "bold" },
          b = { fg = aura.fg, bg = aura.surface },
          c = { fg = aura.gray, bg = aura.bg },
        },
        replace = {
          a = { fg = aura.bg, bg = aura.red, gui = "bold" },
          b = { fg = aura.fg, bg = aura.surface },
          c = { fg = aura.gray, bg = aura.bg },
        },
        command = {
          a = { fg = aura.bg, bg = aura.pink, gui = "bold" },
          b = { fg = aura.fg, bg = aura.surface },
          c = { fg = aura.gray, bg = aura.bg },
        },
        inactive = {
          a = { fg = aura.gray, bg = aura.bg },
          b = { fg = aura.gray, bg = aura.bg },
          c = { fg = aura.gray, bg = aura.bg },
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
        fill = { bg = aura.bg },
        background = { fg = aura.gray, bg = aura.bg },
        buffer_visible = { fg = aura.gray, bg = aura.bg },
        buffer_selected = { fg = aura.green, bg = aura.surface, bold = true, italic = false },
        tab = { fg = aura.gray, bg = aura.bg },
        tab_selected = { fg = aura.green, bg = aura.surface, bold = true },
        close_button = { fg = aura.gray, bg = aura.bg },
        close_button_selected = { fg = aura.red, bg = aura.surface },
        separator = { fg = aura.bg, bg = aura.bg },
        separator_selected = { fg = aura.bg, bg = aura.surface },
        modified = { fg = aura.orange, bg = aura.bg },
        modified_selected = { fg = aura.orange, bg = aura.surface },
        indicator_selected = { fg = aura.purple, bg = aura.surface },
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
          LazyVim  ·  Aura Dark]],
        },
      },
    },
  },
}
