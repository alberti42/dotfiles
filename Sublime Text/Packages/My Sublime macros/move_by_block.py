import sublime
import sublime_plugin
import re
from typing import Union, List

def is_separator_line(line: str, separators: List[str]) -> bool:
    """
    A line is a separator if:
      - it is empty
      - it matches any of the regex strings provided in separators
    """
    if line.strip() == "":
        return True

    for sep in separators:
        # Treat each separator as a regex pattern string
        if re.fullmatch(sep, line):
            return True

    return False

def line_text(view: sublime.View, row: int) -> str:
    return view.substr(view.line(view.text_point(row, 0)))


def max_row(view: sublime.View) -> int:
    return view.rowcol(view.size())[0]

def find_next_block_start(view: sublime.View, row: int, separators) -> Union[int, None]:
    """From current row, find the first non-separator after the next separator cluster.
    If none, jump to the end of the document.
    """
    i = row + 1
    m = max_row(view)
    if i > m:
        # Already at bottom: move to end of document
        return view.size()

    # walk down to next separator
    while i <= m and not is_separator_line(line_text(view, i), separators):
        i += 1

    if i > m:
        # no separator found: move to end of document
        return view.size()

    # skip the whole separator cluster
    while i <= m and is_separator_line(line_text(view, i), separators):
        i += 1

    return view.text_point(i, 0) if i <= m else view.size()


def find_prev_block_start(view: sublime.View, row: int, separators) -> Union[int, None]:
    """
    From current row, jump to the FIRST non-separator of the previous block.
    Algorithm:
      1) Walk up to the separator cluster just above the caret.
      2) Move above that cluster to the previous block.
      3) Walk up within that block to its first line.
    """
    i = row - 1
    # If no separator above at all -> go to first non-separator from top (if any)
    while i >= 0 and not is_separator_line(line_text(view, i), separators):
        i -= 1
    if i < 0:
        j, m = 0, max_row(view)
        while j <= m and is_separator_line(line_text(view, j), separators):
            j += 1
        return view.text_point(j, 0) if j <= m else None

    # i is within a separator cluster; skip entire cluster upward
    while i >= 0 and is_separator_line(line_text(view, i), separators):
        i -= 1

    # If cluster was at very top, again go to first non-separator from top
    if i < 0:
        j, m = 0, max_row(view)
        while j <= m and is_separator_line(line_text(view, j), separators):
            j += 1
        return view.text_point(j, 0) if j <= m else None

    # Now i is inside the previous block; walk up to its first line
    while i - 1 >= 0 and not is_separator_line(line_text(view, i - 1), separators):
        i -= 1
    return view.text_point(i, 0)


class MoveByBlockCommand(sublime_plugin.TextCommand):
    def run(self, edit, forward=True, extend=False, separators=None):
        view = self.view
        if separators is None:
            separators = []  # empty line is always a separator; these are additional literals

        sels = list(view.sel())
        targets = []

        for sel in sels:
            # Use caret as origin when extending; otherwise use current caret/point
            origin_point = sel.b if extend else sel.begin()
            row, _ = view.rowcol(origin_point)

            if forward:
                target_pt = find_next_block_start(view, row, separators)
            else:
                target_pt = find_prev_block_start(view, row, separators)

            if target_pt is not None:
                targets.append((sel, target_pt))

        if not targets:
            return

        new_sels = view.sel()
        new_sels.clear()
        for sel, target in targets:
            if extend:
                anchor, caret = sel.a, sel.b

                # If direction flips across the anchor, swap anchor/caret like Sublime does
                if (caret < anchor and target > anchor) or (caret > anchor and target < anchor):
                    anchor, caret = caret, anchor

                # Build region from (possibly flipped) anchor to new target
                new_sels.add(sublime.Region(anchor, target))
            else:
                new_sels.add(sublime.Region(target))

        # Scroll to the caret of the first selection
        first = next(iter(new_sels))
        view.show(first.b, show_surrounds=False)
