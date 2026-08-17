require("full-border"):setup({
	-- Available values: ui.Border.PLAIN, ui.Border.ROUNDED
	type = ui.Border.ROUNDED,
})

require("git"):setup()

require("folder-rules"):setup()

-- mux.yazi: cycle between several previewers for the same file/folder.
require("mux"):setup({
	notify_on_switch = true,
	aliases = {
		eza_tree_1 = {
			previewer = "faster-piper",
			args = {
				'cd "$1" && LS_COLORS="ex=32" eza --oneline --tree --level 1 --color=always --icons=always --group-directories-first --no-quotes .',
			},
		},
		eza_tree_2 = {
			previewer = "faster-piper",
			args = {
				'cd "$1" && LS_COLORS="ex=32" eza --oneline --tree --level 2 --color=always --icons=always --group-directories-first --no-quotes .',
			},
		},
		eza_tree_3 = {
			previewer = "faster-piper",
			args = {
				'cd "$1" && LS_COLORS="ex=32" eza --oneline --tree --level 3 --color=always --icons=always --group-directories-first --no-quotes .',
			},
		},
		eza_tree_4 = {
			previewer = "faster-piper",
			args = {
				'cd "$1" && LS_COLORS="ex=32" eza --oneline --tree --level 4 --color=always --icons=always --group-directories-first --no-quotes .',
			},
		},
	},
})

function Linemode:size_and_mtime()
	local time = math.floor(self._file.cha.mtime or 0)
	local time_str
	if time == 0 then
		time_str = ""
	else
		time_str = os.date("%x %H:%M", time)
	end

	local size = self._file:size()
	local size_str = size and ya.readable_size(size) or ""
	if size then
		return string.format("%s %s", size_str, time_str)
	else
		return string.format("%s", time_str)
	end
end

function Linemode:mtime()
	local time = math.floor(self._file.cha.mtime or 0)
	local time_str
	if time == 0 then
		time_str = ""
	else
		time_str = os.date("%x %H:%M", time)
	end
	return time_str
end

function Linemode:btime()
	local time = math.floor(self._file.cha.btime or 0)
	local time_str
	if time == 0 then
		time_str = ""
	else
		time_str = os.date("%x %H:%M", time)
	end
	return time_str
end

function Linemode:my_default()
	return self:size_and_mtime()
end

-- vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2 :
