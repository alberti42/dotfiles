import sublime
import sublime_plugin

# Command is registered as "jump_lines" in Sublime's command system.
# Since it's a WindowCommand, it can open UI panels (like input dialogs).
class JumpLinesCommand(sublime_plugin.WindowCommand):
    """
    Jump caret(s) up or down by a number of lines, optionally extending the selection(s).
    """
    forward: bool
    show_at_center: bool
    extend: bool

    def run(self, forward: bool = True, show_at_center: bool = False, extend: bool = False):
        """
        Entry point when the command is triggered.
        Shows an input panel asking how many lines to jump.
        """
        self.forward = forward
        self.show_at_center = show_at_center
        self.extend = extend

        direction = "down" if forward else "up"
        self.window.show_input_panel(
            f"Jump {direction} by how many lines?",
            "",
            self.on_done,
            None,
            None
        )

    def _point_at_row_col_clamped(self, view: sublime.View, row: int, col: int) -> int:
        """
        Returns a text point in 'row' at column 'col', but clamps 'col' to the
        *visible* end of that line (before the newline), so we never land on the
        newline itself (which can visually appear as the next line).
        """
        # Start-of-line point for the target row
        bol = view.text_point(row, 0)

        # Region of that line excluding the trailing newline (a..b)
        line_region = view.line(bol)

        # Length of the line in characters (no newline)
        line_len = line_region.b - line_region.a

        # Clamp desired column into [0, line_len]
        target_col = max(0, min(col, line_len))

        # Final point is "start of line + clamped column"
        return line_region.a + target_col

    def move_by_n_lines(self, view: sublime.View, nlines: int = 0):
        """
        Move or extend all carets by nlines (positive = down, negative = up),
        preserving columns and clamping safely within file bounds.
        """
        new_regions = []
        # Index of the last valid row in the buffer (0-based)
        last_row, _ = view.rowcol(view.size())

        for region in view.sel():
            # Current caret (use .b; for zero-width carets .a == .b)
            row, col = view.rowcol(region.b)

            # Clamp target row within [0, last_row]
            target_row = max(0, min(last_row, row + nlines))

            # Compute safe point at (target_row, col) without landing on newline
            target = self._point_at_row_col_clamped(view, target_row, col)

            # Save new caret region
            if self.extend:
                # Extend selection rather than move caret
                new_regions.append(sublime.Region(region.a, target))
            else:
                # Move caret only
                new_regions.append(sublime.Region(target))

        # Replace selections
        sel = view.sel()
        sel.clear()
        for r in new_regions:
            sel.add(r)

        # Ensure visibility: single caret -> center, multiple carets -> show last
        last_region = new_regions[-1]
        if self.show_at_center:
            view.show_at_center(last_region)
        else:
            view.show(last_region)

    def on_done(self, text: str):
        """
        Parse number and perform the jump.
        """
        try:
            amount = int(text.strip())
        except ValueError:
            sublime.error_message("Please enter an integer (e.g. -5 or 12) representing the relative number of lines.")
            return

        if not self.forward:
            amount = -amount

        view = self.window.active_view()
        if view:
            self.move_by_n_lines(view, amount)
