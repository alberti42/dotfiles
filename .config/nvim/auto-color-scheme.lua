-- Neovim appearance switcher for zsh-appearance-control.
--
-- This is a minimal example you can copy and adapt.
-- Inspired by the “watch a file and react” approach described here:
-- https://www.henriksommerfeld.se/neovim-automatic-light-dark-mode-switcher/

local uv = vim.uv

local function zac_appearance_file()
  local cache = os.getenv("ZAC_CACHE_DIR")
  if not cache or cache == "" then
    cache = (os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")) .. "/zac"
  end
  return cache .. "/appearance"
end

local function read_mode(path)
  local f = io.open(path, "r")
  if not f then
    return "0"
  end
  local line = f:read("*line") or "0"
  f:close()
  return line
end

local function apply_mode(mode)
  if mode == '1' then
    vim.o.background = 'dark'
    pcall(vim.cmd.colorscheme, 'catppuccin-macchiato')
    -- vim.notify("Switching to dark mode 🌘")
  else
    vim.o.background = 'light'
    pcall(vim.cmd.colorscheme, 'catppuccin-frappe')
    -- vim.notify("Switching to light mode 🌖")
  end
end

local path = zac_appearance_file()

-- Apply once on startup.
vim.schedule(function()
  apply_mode(read_mode(path))
end)

-- Watch for changes.
local handle = uv.new_fs_event()
if handle then
  uv.fs_event_start(handle, path, {}, function(err)
    if err then
      return
    end
    vim.schedule(function()
      apply_mode(read_mode(path))
    end)
  end)
end
