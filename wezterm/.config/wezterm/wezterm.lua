local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- Aura Dark: https://github.com/daltonmenezes/aura-theme
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
  black = "#110f18",
  bright_black = "#4d4d4d",
}

config.color_schemes = {
  ["Aura Dark"] = {
    foreground = aura.fg,
    background = aura.bg,
    cursor_bg = aura.purple,
    cursor_fg = aura.bg,
    cursor_border = aura.purple,
    selection_fg = aura.fg,
    selection_bg = aura.surface,
    scrollbar_thumb = aura.surface,
    split = aura.surface,
    compose_cursor = aura.orange,
    ansi = {
      aura.black,
      aura.red,
      aura.green,
      aura.orange,
      aura.blue,
      aura.purple,
      aura.green,
      aura.fg,
    },
    brights = {
      aura.bright_black,
      aura.red,
      aura.green,
      aura.orange,
      aura.blue,
      aura.pink,
      aura.blue,
      aura.fg,
    },
  },
}
config.color_scheme = "Aura Dark"

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
  active_titlebar_bg = aura.bg,
  inactive_titlebar_bg = aura.black,
}

config.colors = {
  tab_bar = {
    background = aura.bg,
    active_tab = {
      bg_color = aura.surface,
      fg_color = aura.green,
      intensity = "Bold",
    },
    inactive_tab = {
      bg_color = aura.bg,
      fg_color = aura.gray,
    },
    inactive_tab_hover = {
      bg_color = aura.surface,
      fg_color = aura.fg,
    },
    new_tab = {
      bg_color = aura.bg,
      fg_color = aura.gray,
    },
    new_tab_hover = {
      bg_color = aura.surface,
      fg_color = aura.purple,
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
