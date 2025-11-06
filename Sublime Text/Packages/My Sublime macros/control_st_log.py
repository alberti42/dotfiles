import sublime
import sublime_plugin

import sublime
import sublime_plugin

class ToggleCommandsLoggingCommand(sublime_plugin.ApplicationCommand):
    def run(self, enable=None):
        if enable is None:
            # Determine current logging state
            current_state = sublime.get_log_commands()
            enable = not current_state

        if enable:
            sublime.log_commands(True)
            sublime.status_message("Started logging commands.")
        else:
            sublime.log_commands(False)
            sublime.status_message("Stopped logging commands.")

class ToggleInputLoggingCommand(sublime_plugin.ApplicationCommand):
    def run(self, enable=None):
        if enable is None:
            # Determine current logging state
            current_state = sublime.get_log_input()
            enable = not current_state

        if enable:
            sublime.log_input(True)  # Optionally log input commands as well
            sublime.status_message("Started logging input.")
        else:
            sublime.log_input(False)  # Disable input logging too
            sublime.status_message("Stopped logging input.")
