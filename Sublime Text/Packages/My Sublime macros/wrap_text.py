import sublime
import sublime_plugin
import textwrap

class ColumnInputHandler(sublime_plugin.TextInputHandler):
    def placeholder(self):
        return "Enter the number of columns"

    def validate(self, input_value):
        # Ensure that the input is a valid positive integer
        try:
            value = int(input_value)
            return value > 0
        except ValueError:
            return False

    def preview(self, input_value):
        if input_value == "":
            return "No input entered yet"
        # Preview the column number, or show an error if invalid
        try:
            columns = int(input_value)
            if columns > 0:
                return "Wrapping text to {} columns".format(columns)
            else:
                return "Please enter a positive number"
        except ValueError:
            return "Invalid input"

class WrapTextCommand(sublime_plugin.TextCommand):
    def run(self, edit, column):
        try:
            # Convert the user input to an integer
            column = int(column)

            # Iterate over each selection and wrap the text
            for region in self.view.sel():
                if not region.empty():
                    selected_text = self.view.substr(region)
                    wrapped_text = textwrap.fill(selected_text, width=column)

                    # Replace the selected text with the wrapped version
                    self.view.replace(edit, region, wrapped_text)
        
        except ValueError:
            sublime.error_message("Invalid input. Please enter a valid number.")

    def input(self, args):
        return ColumnInputHandler()

import re
import sublime
import sublime_plugin

class UnwrapTextCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        for region in self.view.sel():
            if not region.empty():
                selected_text = self.view.substr(region)
                unwrapped_text = self.unwrap_text(selected_text)
                self.view.replace(edit, region, unwrapped_text)

    def unwrap_text(self, text: str) -> str:
        """
        Unwrap paragraphs while preserving:
          1) paragraph boundaries (empty lines),
          2) LaTeX comments (never merged with text),
          3) lines starting with '%' as standalone blocks.
        Also handles inline comments and escaped '\%'.
        """
        lines = text.splitlines()
        out_lines = []
        para_buf = []  # collects words for the current paragraph

        def flush_paragraph():
            nonlocal para_buf
            if para_buf:
                # join with single spaces
                out_lines.append(" ".join(para_buf))
                para_buf = []

        def is_blank(s: str) -> bool:
            return s.strip() == ""

        def starts_comment(s: str) -> bool:
            # lines like "  % comment"
            return bool(re.match(r'^\s*%', s))

        def find_first_unescaped_percent(s: str):
            """
            Return index of the first '%' that is not escaped by an odd number
            of backslashes immediately preceding it. Return -1 if none.
            """
            i = 0
            while True:
                j = s.find('%', i)
                if j == -1:
                    return -1
                # count backslashes immediately before j
                k = j - 1
                backslashes = 0
                while k >= 0 and s[k] == '\\':
                    backslashes += 1
                    k -= 1
                if backslashes % 2 == 0:  # even -> not escaped
                    return j
                i = j + 1

        for raw in lines:
            # Preserve exact comment lines as standalone blocks
            if starts_comment(raw):
                flush_paragraph()
                out_lines.append(raw.rstrip())
                continue

            if is_blank(raw):
                # Paragraph boundary
                flush_paragraph()
                out_lines.append("")  # keep the empty line
                continue

            # Handle inline comments within a text line
            idx = find_first_unescaped_percent(raw)
            if idx != -1:
                text_part = raw[:idx].strip()
                comment_part = raw[idx:].rstrip()

                if text_part:
                    # add text to current paragraph, then flush (boundary before comment)
                    para_buf.append(_collapse_ws(text_part))
                    flush_paragraph()

                # emit the comment as its own line
                out_lines.append(comment_part)
                # treat comment as a hard boundary before any following text
                continue

            # Plain text: collect into current paragraph
            stripped = raw.strip()
            if stripped:
                para_buf.append(_collapse_ws(stripped))

        # Flush any trailing paragraph
        flush_paragraph()

        # Normalize: avoid trailing extra blank lines produced by selection edges
        # but keep internal empty lines intact
        # (strip one trailing empty line if present)
        while len(out_lines) > 1 and out_lines[-1] == "" and out_lines[-2] == "":
            out_lines.pop()

        return "\n".join(out_lines)


def _collapse_ws(s: str) -> str:
    """Collapse all internal whitespace runs to single spaces."""
    return re.sub(r'\s+', ' ', s)
