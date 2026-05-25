local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.color_scheme = "Monokai Pro (Gogh)"
config.font = wezterm.font_with_fallback({
  { family = "Fira Code", weight = "Regular" },
  "Symbols Nerd Font Mono",
  "Noto Color Emoji",
})
config.font_size = 13.0
config.line_height = 1.08

config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
config.max_fps = 120
config.animation_fps = 60

config.window_background_opacity = 0.82
config.macos_window_background_blur = 28
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
  font = wezterm.font({ family = "Fira Code", weight = "Medium" }),
  font_size = 12.0,
  active_titlebar_bg = "#272822",
  inactive_titlebar_bg = "#1f201b",
}

config.colors = {
  tab_bar = {
    background = "#1f201b",
    active_tab = {
      bg_color = "#272822",
      fg_color = "#f8f8f2",
      intensity = "Bold",
    },
    inactive_tab = {
      bg_color = "#1f201b",
      fg_color = "#a59f85",
    },
    inactive_tab_hover = {
      bg_color = "#34352f",
      fg_color = "#f8f8f2",
    },
  },
}

return config
