-- ~/config/wezterm/wezterm.lua
local wezterm = require 'wezterm'

wezterm.on("gui-startup", function(cmd)
  local screen = wezterm.gui.screens().active
  local ratio_x = 0.7
  local ratio_y = 0.82
  local width, height = screen.width * ratio_x, screen.height * ratio_y
  -- Decide how to center the window based on architecture
  local divisor = 2
  if wezterm.target_triple == 'aarch64-apple-darwin' then
    divisor = 1  -- Apple Silicon: no extra halving
  end
  local tab, pane, window = wezterm.mux.spawn_window {
  	position = {
      x = (screen.width - width)/divisor,
      y = (screen.height - height)/divisor,
      origin = 'ActiveScreen'
    }
  }
  window:gui_window():set_inner_size(width, height)
end)

return {
  -- General options
  check_for_updates = false,
  adjust_window_size_when_changing_font_size = false,

  -- Font configuration
  font = wezterm.font('MesloLGS NF', { weight = 'Regular' }),
  font_size = 17.0,

  -- Colors
  colors = {
    foreground = '#ffffff',
    background = '#282935',
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
  },

  -- Cursor style
  default_cursor_style = 'SteadyBar',
  cursor_blink_rate = 600,

  -- Scrollback
  scrollback_lines = 10000,

  -- Workspace
  default_workspace = "home",

  -- Audible bell
  audible_bell = "Disabled",

  -- Tmux
  default_prog = { os.getenv("HOME") .. "/.config/dotfiles/.local/bin/tmux_launcher", "-l", "new-session", "-A", "-s", "main" },

  -- Mouse configuration
  -- alternate_buffer_wheel_scroll_speed = 1,
  hide_mouse_cursor_when_typing = false,

  -- macOS Left and Right Option Key
  send_composed_key_when_left_alt_is_pressed = false,
	send_composed_key_when_right_alt_is_pressed = true,

  -- Key bindings
  disable_default_key_bindings = true,
  keys = {
    { key = 'LeftArrow', mods = 'ALT', action = wezterm.action { SendString = '\x1bb' } }, -- Alt + Left (Move backward one word)
    { key = 'RightArrow', mods = 'ALT', action = wezterm.action { SendString = '\x1bf' } }, -- Alt + Right (Move forward one word)

    -- { key = 'w', mods = 'CMD', action = wezterm.action { SendString = '\x02x' } }, -- Cmd + w -> Ctrl-b x (new tmux kill-panel)
    -- { key = 't', mods = 'CMD', action = wezterm.action { SendString = '\x02c' } }, -- Cmd + t -> Ctrl-b c (new tmux window)

    { key = 'Enter', mods = 'ALT', action = wezterm.action.DisableDefaultAssignment }, -- Disable Alt + Enter (fullscreen toggle)

    -- **Override WezTerm's default tab-switching behavior**
    { key = '[', mods = 'ALT|SUPER', action = wezterm.action { SendString = '\x02p' } }, -- Cmd + Shift + [ -> Move to previous tmux pane
    { key = ']', mods = 'ALT|SUPER', action = wezterm.action { SendString = '\x02n' } }, -- Cmd + Shift + ] -> Move to next tmux pane

    { key = 'c', mods = 'SUPER', action = wezterm.action { CopyTo="Clipboard" } },
    { key = 'v', mods = 'SUPER', action = wezterm.action { PasteFrom="Clipboard" } },
    { key = 'f', mods = 'SUPER', action = wezterm.action.Search { CaseInSensitiveString = "" } },
    { key = 'f', mods = 'SHIFT|SUPER', action = wezterm.action.Search { CaseSensitiveString = "" } },
    { key = 'q', mods = 'SUPER', action = wezterm.action.QuitApplication },
    { key = 'w', mods = 'CMD', action = wezterm.action.CloseCurrentTab{confirm=false} }, -- Cmd + w -> close window
    { key = 'n', mods = 'CMD', action = wezterm.action.DisableDefaultAssignment }, -- Disable Cmd + n (new window)
  },

  -- Hyperlink hints
  hyperlink_rules = {
    {
      regex = [[\b(mailto:|https://|http://|news:|file:|git://|ssh:|ftp://)[^\s<>"\(\)\[\]\{\}]+]],
      format = '$0',
    },
  },

  -- Window settings
  window_background_opacity = 1,
  use_resize_increments = true,
  window_padding = {
    left = 30,
    right = 30,
    top = 20,
    bottom = 10,
  },
  window_decorations = 'RESIZE',
  window_close_confirmation = 'NeverPrompt',

  -- Hide tabs
  enable_tab_bar = false,
  -- hide_tab_bar_if_only_one_tab = true,

  -- Clipboard settings
  enable_kitty_keyboard = true, -- Enables clipboard integration
}
