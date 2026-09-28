local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- Catppuccin Latte: https://github.com/catppuccin/catppuccin
-- ANSI mapping matches the official catppuccin/wezterm Latte port.
local latte = {
  rosewater = "#dc8a78",
  flamingo = "#dd7878",
  pink = "#ea76cb",
  mauve = "#8839ef",
  red = "#d20f39",
  peach = "#fe640b",
  yellow = "#df8e1d",
  green = "#40a02b",
  teal = "#179299",
  blue = "#1e66f5",
  text = "#4c4f69",
  subtext1 = "#5c5f77",
  subtext0 = "#6c6f85",
  overlay0 = "#9ca0b0",
  surface2 = "#acb0be",
  surface1 = "#bcc0cc",
  surface0 = "#ccd0da",
  crust = "#dce0e8",
  mantle = "#e6e9ef",
  base = "#eff1f5",
}

config.color_schemes = {
  ["Catppuccin Latte"] = {
    foreground = latte.text,
    background = latte.base,
    cursor_bg = latte.rosewater,
    cursor_fg = latte.base,
    cursor_border = latte.rosewater,
    selection_fg = latte.text,
    selection_bg = latte.surface2,
    scrollbar_thumb = latte.surface2,
    split = latte.overlay0,
    compose_cursor = latte.flamingo,
    ansi = {
      latte.subtext1,
      latte.red,
      latte.green,
      latte.yellow,
      latte.blue,
      latte.pink,
      latte.teal,
      latte.surface2,
    },
    brights = {
      latte.subtext0,
      latte.red,
      latte.green,
      latte.yellow,
      latte.blue,
      latte.pink,
      latte.teal,
      latte.surface1,
    },
  },
}
config.color_scheme = "Catppuccin Latte"

config.font = wezterm.font_with_fallback({
  { family = "FiraCode Nerd Font", weight = "Regular" },
  { family = "Fira Code", weight = "Regular" },
  "Symbols Nerd Font Mono",
  "Noto Color Emoji",
})
config.font_size = 13.0
config.line_height = 1.08

-- Preserve smooth Retina rendering and subtle translucency without returning
-- to the original 120 FPS and heavy-blur compositor cost.
config.front_end = "WebGpu"
config.webgpu_power_preference = "LowPower"
config.max_fps = 60
config.animation_fps = 30
config.cursor_blink_rate = 700

config.window_background_opacity = 0.92
config.macos_window_background_blur = 12
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.window_padding = {
  left = 14,
  right = 14,
  top = 12,
  bottom = 10,
}

config.initial_cols = 120
config.initial_rows = 36
config.adjust_window_size_when_changing_font_size = false
config.audible_bell = "Disabled"
config.check_for_updates = false

config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.show_new_tab_button_in_tab_bar = false
config.tab_bar_at_bottom = false
config.window_frame = {
  font = wezterm.font_with_fallback({
    { family = "FiraCode Nerd Font", weight = "Medium" },
    { family = "Fira Code", weight = "Medium" },
  }),
  font_size = 12.0,
  active_titlebar_bg = latte.crust,
  inactive_titlebar_bg = latte.mantle,
}

config.colors = {
  tab_bar = {
    background = latte.crust,
    active_tab = {
      bg_color = latte.mauve,
      fg_color = latte.base,
      intensity = "Bold",
    },
    inactive_tab = {
      bg_color = latte.mantle,
      fg_color = latte.text,
    },
    inactive_tab_hover = {
      bg_color = latte.base,
      fg_color = latte.text,
    },
    new_tab = {
      bg_color = latte.surface0,
      fg_color = latte.text,
    },
    new_tab_hover = {
      bg_color = latte.surface1,
      fg_color = latte.text,
    },
  },
}

-- Forward Ctrl+Space to tmux. macOS Input Sources may still steal this chord.
config.keys = {
  {
    key = "Space",
    mods = "CTRL",
    action = wezterm.action.SendKey({ key = "Space", mods = "CTRL" }),
  },
}

return config
