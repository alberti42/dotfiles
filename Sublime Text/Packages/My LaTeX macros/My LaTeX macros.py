import sublime, sublime_plugin
import os
import subprocess
import re

class OpenTerminalInTmuxCommand(sublime_plugin.WindowCommand):
    def run(self):
        # Get the folder of the currently opened file
        view = self.window.active_view()
        if not view or not view.file_name():
            sublime.error_message("No file is currently open.")
            return

        filename = view.file_name()

        if filename is None:
            return

        folder = os.path.dirname(filename)

        # Path to your tmux script
        tmux_script = os.path.expanduser("~/.config/dotfiles/bin/new_tmux_window_in_session.zsh")

        # First command: launch tmux window
        subprocess.Popen([tmux_script, "-s", "main", "-c", folder])

        # Second command: bring WezTerm to the front
        subprocess.Popen(
            ["/bin/sh", "-c",
             "/usr/bin/osascript -e 'tell application id \"com.github.wez.wezterm\" to activate' 2>/dev/null"]
        )

class EncapsulateInEnvironmentCommand(sublime_plugin.TextCommand):
    def run(self, edit, **params):
        env_name = params.get('env_name')
        if env_name is not None:
            # Walk through each region in the selection
            for region in self.view.sel():
                content = self.view.substr(region)

                if content[-1] in ['\n','\r']:
                    suffix = '';
                else:
                    suffix = '\n';
        
                self.view.insert(edit, self.view.sel()[0].begin(), "\\begin{" + env_name + "}\n")
                self.view.insert(edit, self.view.sel()[0].end(), suffix+"\\end{" + env_name + "}")

class NewLatexLineCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        # Walk through each region in the selection
        for region in self.view.sel():
            if region.empty():
                cursor = region.begin()
                line = self.view.line(cursor)
                line_str = self.view.substr(line)
                # Detect indentation (spaces or tabs)
                indent_match = re.match(r'^(\s*)', line_str)
                indent = indent_match.group(1) if indent_match else ''
                line_r = self.view.substr(sublime.Region(cursor,line.end()))
                # line_l = self.view.substr(sublime.Region(line.begin(),cursor))
                isComment = any([self.view.match_selector(cursor,selector) for selector in ('comment.line.percentage.tex',)])
                if isComment:
                    match = re.match(r'\s+(.*)',line_r)
                    if match:
                        self.view.insert(edit,cursor,'\n%')
                    else:
                        self.view.insert(edit,cursor,'\n% ')
                else:
                    self.view.insert(edit,cursor,f"\n{indent}%\n{indent}")
                        
class SplitLatexLinesCommand(sublime_plugin.TextCommand):
    def process_each_line(self, x):
        # Remove multiple spaces
        x = re.sub(r"[\s\t]+", r" ", x.group(0))
        # Split lines after full stop, colon, or semicolon
        x = re.compile(r"(?<!\\)([\.:;])[\s\t]+(?=[^\s\t])").sub(r"\g<1>\n%\n", x)
        return x

    def run(self, edit):
        # Walk through each region in the selection
        regions = self.view.sel()
        selections = []
        
        for region in regions:
            # Expand to include the whole line
            region = self.view.line(region)

            selected_text = self.view.substr(region)

            if selected_text:
                # Preserve empty lines (newlines between paragraphs)
                paragraphs = re.split(r'\n{2,}', selected_text)

                processed_paragraphs = []

                for paragraph in paragraphs:
                    # Remove empty spaces before comments %
                    paragraph = re.sub(r"^[\s\t]+%", r"%", paragraph, flags=re.MULTILINE)
                    # Remove empty spaces in empty lines
                    paragraph = re.sub(r"^[\s\t]+$", "", paragraph, flags=re.MULTILINE)
                    # If it contains a comment at the end of the sentence, make a new line with the comment
                    paragraph = re.sub(r"([^\%].*?)[\s\t]*((?<!\\)%.*)", r"\g<1>\n\g<2>", paragraph, flags=re.MULTILINE)
                    # Remove carriage returns in long sentences
                    paragraph = re.sub(r"^([^\n%].*)\n(?![\n\r\s\%])(.*)", r"\g<1> \g<2>", paragraph, flags=re.MULTILINE)
                    # Split lines at the full period except for the case of Latex symbols \.
                    paragraph = re.sub(r"^[^\%].*", self.process_each_line, paragraph, flags=re.MULTILINE)

                    processed_paragraphs.append(paragraph)

                # Join paragraphs with double newlines to preserve separation
                processed_text = '\n\n'.join(processed_paragraphs)

                selections.append(sublime.Region(region.begin(), region.begin() + len(processed_text)))
                self.view.replace(edit, region, processed_text)

        # Reset the cursor positions after processing
        cursors = self.view.sel()
        cursors.clear()
        for region in selections:
            cursors.add(region)
