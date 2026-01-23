# fzf-plus (Yazi plugin)

`fzf-plus` is a small extension of Yazi’s built-in `fzf` plugin. It exposes an
extra option that lets you override `FZF_DEFAULT_COMMAND` per keymap entry, so
you can restrict the candidate list (e.g. limit depth with `fd`) without changing
global shell config.

This plugin exists as a standalone stop‑gap while a PR is under review upstream.
If the PR is accepted, you can switch back to the embedded plugin.

## Features
- Same behavior as the built-in `fzf` plugin for selection and navigation
- Optional `--fzf-command` to set `FZF_DEFAULT_COMMAND` for this run only
- No custom argument parsing beyond Yazi’s normal plugin args

## Installation

1) Create a plugin directory, e.g.:
```
~/.config/yazi/plugins/fzf-plus/
```

2) Put `main.lua` from this repository in that directory:
```
~/.config/yazi/plugins/fzf-plus/main.lua
```

3) (Optional) Ensure you have `fzf` and `fd` installed and on PATH.

## Usage

Add a keymap entry that sets `FZF_DEFAULT_COMMAND` for this one invocation:

```
[[mgr.prepend_keymap]]
on   = "z"
run  = "plugin fzf-plus -- --fzf-command='fd -d=1'"
desc = "Jump to a file/directory via fzf"
```

This makes `fzf` use the provided command to generate its candidate list.
For example:
- `fd -d=1` to limit search depth
- `fd -t=d -d=2` to list only directories to depth 2

If `--fzf-command` is omitted, `fzf` behaves as normal (reads from stdin or
uses its default command).

## Notes
- `--fzf-command` must be a string (as parsed by Yazi). It is passed verbatim to
  `FZF_DEFAULT_COMMAND`.
- When you have a selection in Yazi, the selection is piped into `fzf` and the
  default command is ignored (this matches the built-in plugin behavior).

## Relationship to Yazi
This plugin is a minimal extension of Yazi’s built-in `fzf` plugin. It exists so
users can benefit from `FZF_DEFAULT_COMMAND` overrides immediately, even if the
upstream PR takes time to review or is ultimately rejected.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
