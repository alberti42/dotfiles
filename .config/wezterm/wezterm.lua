-- ~/config/wezterm/wezterm.lua
local wezterm = require 'wezterm'

local home    = os.getenv('HOME')

wezterm.on("gui-startup", function(cmd)
  local screen = wezterm.gui.screens().active
  local ratio_x = 0.70
  local ratio_y = 0.85

  -- These are still in logical points, which is correct for sizing the window
  local width_pt, height_pt = screen.width * ratio_x, screen.height * ratio_y

  -- Calculate the position in POINTS first
  local x_pos_pt = (screen.width - width_pt) / 2
  local y_pos_pt = (screen.height - height_pt) / 2

  local tab, pane, window = wezterm.mux.spawn_window {
    position = {
      x = tostring(x_pos_pt) .. "pt",
      y = tostring(y_pos_pt) .. "pt",
      origin = 'ActiveScreen'
    }
  }

  window:gui_window():set_inner_size(width_pt, height_pt)
  window:gui_window():toggle_fullscreen()
end)

function scheme_for_appearance(appearance)
  -- tmux_dir must be on PATH explicitly: WezTerm is a GUI app and does not
  -- inherit the shell PATH, so system tmux (or Homebrew/zinit-installed tmux)
  -- would not be found otherwise.
  local tmux_dir = home .. "/.local/share/zinit/polaris/bin"
  local dotfiles_dir = home .. "/.config/dotfiles"
  local zac_dispatcher = dotfiles_dir .. "/oh-my-zsh/custom/plugins/zsh-appearance-control/bin/appearance-dispatch"
  local zac_io_cmd = dotfiles_dir .. "/zinit/src/zac/zac-io-cmd.zsh"
  local is_dark = (appearance:find("Dark") ~= nil)
  local dark = is_dark and "1" or "0"

  wezterm.run_child_process({
    'env',
    "PATH=" .. tmux_dir .. ":" .. os.getenv("PATH"),
    'ZAC_IO_CMD=' .. zac_io_cmd,
    zac_dispatcher, 'dispatch', dark,
  })

  -- Return the wezterm color scheme
  if is_dark then
    return "Catppuccin Frappe Custom"
  else
    return "Catppuccin Latte Custom"
  end
end

function extend_scheme(base_name, overrides)
  local builtin = wezterm.color.get_builtin_schemes()
  local base = builtin[base_name]
  if not base then
    wezterm.log_error("extend_scheme: scheme '" .. base_name .. "' not found")
    return overrides or {}
  end

  -- make a shallow copy so we don’t mutate the builtin
  local result = {}
  for k, v in pairs(base) do
    result[k] = v
  end

  -- apply overrides
  if overrides then
    for k, v in pairs(overrides) do
      result[k] = v
    end
  end

  return result
end

-- wezterm.on("update-status", function(window, pane)
--     window:set_left_status(wezterm.format {
--       { Text = 'Status bar' },
--     })
-- end)

local platform
if string.find(wezterm.target_triple, "darwin") then
  platform = "darwin"
elseif string.find(wezterm.target_triple, "windows") then
  platform = "win"
else
  platform = "linux"
end

local is_linux = function()
  return platform == "linux"
end

local is_mac = function()
  return platform == "darwin"
end

local is_win = function()
  return platform == "win"
end

config = {}

-- Check for updates every day
config.check_for_updates = false
config.check_for_updates_interval_seconds = 86400
  
-- Font configuration
config.adjust_window_size_when_changing_font_size = false
config.font = wezterm.font('JetBrainsMonoNL Nerd Font Mono', { weight = 'Regular' })
if is_mac() then
  config.font_size = 17.0
elseif is_linux() then
  config.font_size = 12.0
end

-- Colors
--[[
config.colors = {
  foreground = '#ffffff',
  background = '#111111',
  cursor_bg = '#ffffff',
  cursor_fg = '#000000',
  cursor_border = '#ffffff',

  ansi = {
    '#000000', -- black
    '#c91b00', -- red
    '#00c300', -- green
    '#c7c400', -- yellow
    '#0226c8', -- blue
    '#ca30c7', -- magenta
    '#00c5c8', -- cyan
    '#c7c7c7', -- white
  },
  brights = {
    '#686868', -- bright black
    '#ff6e68', -- bright red
    '#60fa67', -- bright green
    '#fffc67', -- bright yellow
    '#6872ff', -- bright blue
    '#ff77ff', -- bright magenta
    '#5ffdff', -- bright cyan
    '#ffffff', -- bright white
  },
}
--]]

-- Extend it with your overrides
config.color_schemes = {
  ["Catppuccin Mocha Custom"] = extend_scheme("Catppuccin Mocha", {
    -- background = 'white'
    cursor_bg = "#cad3f5",
    -- cursor_fg = "#cad3f5",
    cursor_border = "#cad3f5",
  }),
  ["Catppuccin Macchiato Custom"] = extend_scheme("Catppuccin Macchiato", {
    -- background = 'white'
    cursor_bg = "#cad3f5",
    -- cursor_fg = "#cad3f5",
    cursor_border = "#cad3f5",
  }),
  ["Catppuccin Frappe Custom"] = extend_scheme("Catppuccin Frappe", {
    -- background = 'white'
    cursor_bg = "#cad3f5",
    -- cursor_fg = "#cad3f5",
    cursor_border = "#cad3f5",
  }),
  ["Catppuccin Latte Custom"] = extend_scheme("Catppuccin Latte", {
    -- background = 'white',
    -- cursor_bg = "#b58dd7",
    -- cursor_fg = "#cad3f5",
    -- cursor_border = "#b58dd7",
  }),
}
-- Catppuccin color scheme https://github.com/catppuccin/wezter
config.color_scheme = scheme_for_appearance(wezterm.gui.get_appearance())

-- Cursor style
config.default_cursor_style = 'BlinkingBlock'
-- config.cursor_thickness = "150%"
config.cursor_blink_rate = 250

-- Scrollback
config.scrollback_lines = 10000
  
-- Animation fps
config.max_fps = 240

if is_mac() then
  config.front_end = "WebGpu"
  config.webgpu_power_preference = "HighPerformance"
elseif is_linux() then
  config.front_end = "OpenGL"
elseif is_win() then
  config.front_end = "OpenGL"
end
  
-- Workspace
config.default_workspace = "home"

-- Audible bell
config.audible_bell = "Disabled"

-- Tmux
config.term = "xterm-256color"
config.default_prog = { "/usr/bin/env", "PATH=" .. home .. "/.local/share/zinit/polaris/bin:/usr/bin:/bin", "TERM=" .. config.term, "tmux", "new-session", "-A", "-D", "-s", "main", ";", "set-option", "-g", "@dark_appearance", (wezterm.gui.get_appearance():find("Dark") ~= nil) and "1" or "0" }

-- Mouse configuration
config.alternate_buffer_wheel_scroll_speed = 1
config.hide_mouse_cursor_when_typing = false
config.precise_scroll_scale = 15
config.tui_scroll_gesture_support = true

-- macOS Left and Right Option Key
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = true

-- macOS native fullscreen
-- config.native_macos_fullscreen_mode = true

-- Key bindings
config.disable_default_key_bindings = true
config.enable_csi_u_key_encoding = true
config.keys = {
  { key = '[', mods = 'CTRL|ALT', action = wezterm.action.SendString('\x02p') }, -- Cmd + Shift + [ -> Move to previous tmux pane
  { key = ']', mods = 'CTRL|ALT', action = wezterm.action.SendString('\x02n') }, -- Cmd + Shift + ] -> Move to next tmux pane

  -- { key = '[', mods = 'ALT|SUPER', action = wezterm.action { SendString = '\x02p' } }, -- Cmd + Shift + [ -> Move to previous tmux pane
  -- { key = ']', mods = 'ALT|SUPER', action = wezterm.action { SendString = '\x02n' } }, -- Cmd + Shift + ] -> Move to next tmux pane

  { key = "{", mods = "CTRL|SHIFT", action = wezterm.action.SendKey { key = "LeftArrow", mods = "CTRL|SHIFT" } },
  { key = "}", mods = "CTRL|SHIFT", action = wezterm.action.SendKey { key = "RightArrow", mods = "CTRL|SHIFT" } },

  { key = "{", mods = "ALT|SHIFT", action = wezterm.action.SendKey { key = "LeftArrow", mods = "ALT|SHIFT" } },
  { key = "}", mods = "ALT|SHIFT", action = wezterm.action.SendKey { key = "RightArrow", mods = "ALT|SHIFT" } },

  { key = "+", mods = "ALT|SHIFT", action = wezterm.action.SendKey { key = "UpArrow", mods = "ALT|SHIFT" } },
  { key = "\"", mods = "ALT|SHIFT", action = wezterm.action.SendKey { key = "DownArrow", mods = "ALT|SHIFT" } },

  -- { key = 'LeftArrow', mods = 'ALT|SUPER', action = wezterm.action { SendString = '\x02p' } }, -- Cmd + Shift + [ -> Move to previous tmux pane
  -- { key = 'RightArrow', mods = 'ALT|SUPER', action = wezterm.action { SendString = '\x02n' } }, -- Cmd + Shift + ] -> Move to next tmux pane

  -- { key = 'w', mods = 'CMD', action = wezterm.action { SendString = '\x02x' } }, -- Cmd + w -> Ctrl-b x (new tmux kill-panel)
  -- { key = 't', mods = 'CMD', action = wezterm.action { SendString = '\x02c' } }, -- Cmd + t -> Ctrl-b c (new tmux window)

  { key = 'Enter', mods = 'ALT', action = wezterm.action.DisableDefaultAssignment }, -- Disable Alt + Enter (fullscreen toggle)

  -- Use in tmux `printf '\e[>4;1m'` to enable usage of CSI u 
	{ key = 'Tab', mods = 'CTRL', action = wezterm.action.SendString('\x1b[9;5u') },
	{ key = 'Enter', mods = 'SHIFT', action = wezterm.action.SendString('\x1b[13;2u') },

  { key = 'c', mods = 'SUPER', action = wezterm.action { CopyTo="Clipboard" } },
  { key = 'v', mods = 'SUPER', action = wezterm.action { PasteFrom="Clipboard" } },
  -- { key = 'f', mods = 'SUPER', action = wezterm.action.Search { CaseInSensitiveString = "" } },
  -- { key = 'f', mods = 'SHIFT|SUPER', action = wezterm.action.Search { CaseSensitiveString = "" } },
  { key = 'q', mods = 'SUPER', action = wezterm.action.QuitApplication },
  { key = 'w', mods = 'SUPER', action = wezterm.action.CloseCurrentTab{confirm=false} }, -- Cmd + w -> close window
  { key = 'n', mods = 'SUPER', action = wezterm.action.DisableDefaultAssignment }, -- Disable Cmd + n (new window)
  { key = 'L', mods = 'SUPER', action = wezterm.action.ShowDebugOverlay },
  { key = 'f', mods = 'SUPER|SHIFT', action = wezterm.action.ToggleFullScreen },
}

-- Hyperlink hints
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- Window settings
config.window_background_opacity = 1.0
config.use_resize_increments = false
config.window_padding = {
  left = "15pt",
  right = "15pt",
  top = "10pt",
  bottom = "10pt",
}
config.window_decorations = 'RESIZE|MACOS_DISABLE_TITLEBAR_DRAG'
config.window_close_confirmation = 'NeverPrompt'
config.use_fancy_tab_bar = true
  
-- Hide tabs
config.enable_tab_bar = false
-- config.hide_tab_bar_if_only_one_tab = true

-- Clipboard settings
config.enable_kitty_keyboard = true -- Enables clipboard integration

return config
