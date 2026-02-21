import os
import types
from typing import Any, Dict

try:
    import sublime  # type: ignore
    import sublime_plugin  # type: ignore
except ImportError:  # pragma: no cover
    # Allow basic linting outside Sublime Text.
    sublime = None  # type: ignore

    class WindowCommand:  # type: ignore
        pass

    sublime_plugin = types.ModuleType("sublime_plugin")  # type: ignore
    sublime_plugin.WindowCommand = WindowCommand  # type: ignore


# Open (or focus) a single Terminus session per window.
#
# Rationale:
# - `terminus_open` cannot "focus existing" by tag/panel_name; it will kill/restart.
# - This command searches the current window for an existing matching Terminus view and
#   focuses it; otherwise it opens a new one.


SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
DOTFILES = os.path.abspath(os.path.join(SCRIPT_DIR, "..", "..", ".."))

LAUNCHER = f"{DOTFILES}/.local/bin/fast-launcher-with-pyenv.zsh"

IPYTHON_EXE = "ipython"

IPY_VIEW_MARKER_KEY = "my_sublime_macros.ipython"
IPY_VIEW_VENV_KEY = "my_sublime_macros.ipython.virtualenv"
SHELL_VIEW_MARKER_KEY = "my_sublime_macros.login_shell"

TERMINUS_PANE_COL_SPLIT = 0.5


def _login_shell_cmd():
    shell = os.environ.get("SHELL")
    if shell:
        if os.path.basename(shell) == "tcsh":
            return [shell, "-l"]
        return [shell, "-i", "-l"]
    return ["/bin/bash", "-i", "-l"]


def _resolve_cwd(window):
    view = window.active_view() if window else None
    file_name = view.file_name() if view else None
    if file_name:
        cwd = os.path.dirname(file_name)
        if os.path.isdir(cwd):
            return cwd

    folders = window.folders() if window else []
    if folders:
        cwd = folders[0]
        if os.path.isdir(cwd):
            return cwd

    return os.path.expanduser("~")


def _layout_group_x_center(layout, group_index):
    cols = layout.get("cols") or [0.0, 1.0]
    cells = layout.get("cells") or []
    if group_index < 0 or group_index >= len(cells):
        return 0.0
    c0, _r0, c1, _r1 = cells[group_index]
    try:
        return (cols[c0] + cols[c1]) / 2.0
    except Exception:
        return 0.0


def _rightmost_group_index(window):
    layout = window.get_layout()
    cells = layout.get("cells") or []
    if not cells:
        return 0

    best = 0
    best_x = _layout_group_x_center(layout, 0)
    for i in range(1, len(cells)):
        x = _layout_group_x_center(layout, i)
        if x >= best_x:
            best = i
            best_x = x
    return best


def _ensure_rightmost_group(window):
    layout = window.get_layout()
    cells = layout.get("cells") or []

    # If the window has a single group, split it into two columns.
    if len(cells) <= 1:
        window.set_layout(
            {
                "cols": [0.0, TERMINUS_PANE_COL_SPLIT, 1.0],
                "rows": [0.0, 1.0],
                "cells": [[0, 0, 1, 1], [1, 0, 2, 1]],
            }
        )

    return _rightmost_group_index(window)


def _move_view_to_rightmost_group(window, view, focus=True):
    group = _ensure_rightmost_group(window)
    if view.window() != window:
        return

    current_group, _ = window.get_view_index(view)
    if current_group != group:
        window.set_view_index(view, group, len(window.views_in_group(group)))

    if focus:
        window.focus_view(view)


class TerminusLauncherMoveToRightmostGroupCommand(sublime_plugin.TextCommand):  # type: ignore[misc]
    def run(self, edit=None, focus=True, **_kwargs):
        window = self.view.window()
        if not window:
            return
        _move_view_to_rightmost_group(window, self.view, focus=focus)


class _TerminusOpenOrFocusBase(sublime_plugin.WindowCommand):  # type: ignore[misc]
    marker_key: str = ""

    def run(self):
        window = self.window
        _ensure_rightmost_group(window)

        existing = self._find_existing(window)
        if existing:
            self._focus_terminus_view(window, existing)
            return

        window.run_command("terminus_open", self._terminus_open_args())

    def _terminus_open_args(self) -> Dict[str, Any]:
        return {
            "cmd": self._cmd(),
            "cwd": _resolve_cwd(self.window),
            "post_view_hooks": [
                ["terminus_launcher_move_to_rightmost_group", {"focus": True}],
            ],
            "view_settings": self._view_settings(),
        }

    def _cmd(self):
        raise NotImplementedError

    def _view_settings(self) -> Dict[str, Any]:
        if not self.marker_key:
            raise NotImplementedError("marker_key is required")
        return {self.marker_key: True}

    def _is_matching_view(self, view):
        s = view.settings()
        if not s.get("terminus_view"):
            return False
        if s.get("terminus_view.finished"):
            return False
        return bool(self.marker_key and s.get(self.marker_key))

    def _find_existing(self, window):
        for view in window.views():
            if self._is_matching_view(view):
                return view

        for panel in window.panels():
            panel_name = panel.replace("output.", "")
            view = window.find_output_panel(panel_name)
            if view and self._is_matching_view(view):
                return view

        return None

    def _focus_terminus_view(self, window, view):
        args = view.settings().get("terminus_view.args") or {}
        if args.get("show_in_panel") and args.get("panel_name"):
            window.run_command(
                "show_panel", {"panel": f"output.{args.get('panel_name')}"}
            )
        _move_view_to_rightmost_group(window, view, focus=True)


class IpythonTerminusOpenOrFocusCommand(_TerminusOpenOrFocusBase):  # type: ignore[misc]
    marker_key = IPY_VIEW_MARKER_KEY

    def run(self, virtualenv=None):
        if virtualenv is None:
            raise ValueError(
                "ipython_terminus_open_or_focus requires arg 'virtualenv' "
                '(e.g. {"virtualenv": "3.13"}).'
            )
        if not isinstance(virtualenv, str) or not virtualenv.strip():
            raise ValueError("'virtualenv' must be a non-empty string")

        self.virtualenv = virtualenv

        super().run()

    def _cmd(self):
        return [LAUNCHER, self.virtualenv, IPYTHON_EXE]

    def _view_settings(self) -> Dict[str, Any]:
        settings = super()._view_settings()
        settings[IPY_VIEW_VENV_KEY] = self.virtualenv
        return settings

    def _is_matching_view(self, view):
        s = view.settings()
        if not s.get("terminus_view"):
            return False
        if s.get("terminus_view.finished"):
            return False
        return bool(
            s.get(IPY_VIEW_MARKER_KEY) and s.get(IPY_VIEW_VENV_KEY) == self.virtualenv
        )


class LoginShellTerminusOpenOrFocusCommand(_TerminusOpenOrFocusBase):  # type: ignore[misc]
    marker_key = SHELL_VIEW_MARKER_KEY

    def _cmd(self):
        return _login_shell_cmd()
