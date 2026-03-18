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
            "env": {"COLORTERM": "truecolor"},
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


class TerminusOpenNewTabCommand(sublime_plugin.WindowCommand):  # type: ignore[misc]
    """Open a new Terminus tab of the same type as the currently active terminus view.

    Detects whether the active view is a login shell or an IPython session (and
    which virtualenv) by inspecting the view settings written by the open-or-focus
    commands, then opens a fresh tab of the same kind.
    """

    def run(self):
        view = self.window.active_view()
        if not view:
            return
        s = view.settings()
        cwd = _resolve_cwd(self.window)

        if s.get(IPY_VIEW_MARKER_KEY):
            virtualenv = s.get(IPY_VIEW_VENV_KEY)
            cmd = [LAUNCHER, virtualenv, IPYTHON_EXE]
            view_settings = {IPY_VIEW_MARKER_KEY: True, IPY_VIEW_VENV_KEY: virtualenv}
        else:
            cmd = _login_shell_cmd()
            view_settings = {SHELL_VIEW_MARKER_KEY: True}

        self.window.run_command("terminus_open", {
            "cmd": cmd,
            "cwd": cwd,
            "env": {"COLORTERM": "truecolor"},
            "post_view_hooks": [
                ["terminus_launcher_move_to_rightmost_group", {"focus": True}],
            ],
            "view_settings": view_settings,
        })

    def is_enabled(self):
        view = self.window.active_view()
        if not view:
            return False
        s = view.settings()
        return bool(s.get("terminus_view") and not s.get("terminus_view.finished"))

# ---------------------------------------------------------------------------
# CLI left-pane helper: move files opened via `subl` to the leftmost pane.
# ---------------------------------------------------------------------------

def _leftmost_group_index(window):
    layout = window.get_layout()
    cells = layout.get("cells") or []
    if not cells:
        return 0

    best = 0
    best_x = _layout_group_x_center(layout, 0)
    for i in range(1, len(cells)):
        x = _layout_group_x_center(layout, i)
        if x < best_x:
            best = i
            best_x = x
    return best


class MoveToLeftmostPaneCommand(sublime_plugin.WindowCommand):  # type: ignore[misc]
    """Move CLI-opened files to the leftmost pane when a split layout is active.

    Accepts ``file`` (single path) or ``files`` (list of paths).
    Retries up to _MAX_ATTEMPTS times for views still loading when the command
    fires. Does nothing when the window has only one group.
    """

    _MAX_ATTEMPTS = 20
    _RETRY_MS = 100

    def run(self, file=None, files=None):
        window = self.window
        if window.num_groups() < 2:
            return

        paths = []
        if file:
            paths.append(os.path.normpath(file))
        if files:
            paths.extend(os.path.normpath(f) for f in files)

        for path in paths:
            self._schedule_move(window, path, self._MAX_ATTEMPTS)

    def _schedule_move(self, window, path, attempts):
        view = next(
            (v for v in window.views()
             if v.file_name() and os.path.normpath(v.file_name()) == path),
            None,
        )
        if view is None or view.is_loading():
            if attempts > 0:
                sublime.set_timeout(
                    lambda: self._schedule_move(window, path, attempts - 1),
                    self._RETRY_MS,
                )
            return

        target = _leftmost_group_index(window)
        current, _ = window.get_view_index(view)
        if current != target:
            window.set_view_index(view, target, len(window.views_in_group(target)))

# ---------------------------------------------------------------------------
# Appearance-change listener: regenerate Terminus theme when the color scheme
# or UI theme changes (e.g. switching between light and dark mode).
# ---------------------------------------------------------------------------

_last_appearance: Dict[str, Any] = {}


def _current_appearance() -> Dict[str, Any]:
    if sublime is None:
        return {}
    return sublime.ui_info()


def _on_appearance_change() -> None:
    global _last_appearance
    if sublime is None:
        return
    current = _current_appearance()
    if current == _last_appearance:
        return
    _last_appearance = current
    for window in sublime.windows():
        window.run_command("terminus_generate_theme", {"force": True})


def plugin_loaded() -> None:
    global _last_appearance
    if sublime is None:
        return
    _last_appearance = _current_appearance()
    prefs = sublime.load_settings("Preferences.sublime-settings")
    prefs.add_on_change("terminus_launcher_appearance", _on_appearance_change)


def plugin_unloaded() -> None:
    if sublime is None:
        return
    sublime.load_settings("Preferences.sublime-settings").clear_on_change(
        "terminus_launcher_appearance"
    )
