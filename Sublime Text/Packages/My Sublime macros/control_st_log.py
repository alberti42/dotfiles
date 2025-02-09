import sublime
import sublime_plugin
import textwrap

import sublime
import sublime_plugin

class ToggleLoggingCommand(sublime_plugin.ApplicationCommand):
    def run(self, enable):
        if enable:
            sublime.log_commands(True)
            sublime.log_input(True)  # Optionally log input commands as well
            sublime.status_message("Sublime Text logging enabled.")
        else:
            sublime.log_commands(False)
            sublime.log_input(False)  # Disable input logging too
            sublime.status_message("Sublime Text logging disabled.")
