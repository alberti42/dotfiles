import sublime
import sublime_plugin
import os
import shlex
import time

class BuildWithTerminusCommand(sublime_plugin.WindowCommand):
    def run(self):
        # Save the current file
        active_view = self.window.active_view()
        if active_view is None:
            return
        
        active_view.run_command('save')

        # Get the project settings
        project_data = self.window.project_data()
        if not project_data or "settings" not in project_data:
            return

        # Fetch the custom setting
        print(project_data["settings"])
        command = project_data["settings"].get("terminus_build_command", None)

        if command is None:
            sublime.error_message("No command defined in terminus_build_command!")
            return

        # If the command is a list, process it and quote each argument
        if isinstance(command, list):
            command_str = ' '.join(shlex.quote(self.replace_placeholders(arg)) for arg in command)
        else:
            command_str = shlex.quote(self.replace_placeholders(str(command)))

        # Write the command string to the .buildcmd file
        self.write_to_build_file(command_str)

        # Run the command in Terminus
        self.window.run_command("terminus_send_string", {
            "string": "source .buildcmd" + "\n",
            "tag": None,
            "visible_only": False
        })

    def write_to_build_file(self, command_str):
        """ Write the command to .buildcmd file and append the self-deletion command. """
        # Get the folder of the current project
        project_folder = self.get_project_folder()
        if not project_folder:
            sublime.error_message("No project folder found to write .buildcmd!")
            return

        build_file_path = os.path.join(project_folder, ".buildcmd")

        try:
            with open(build_file_path, 'w') as build_file:
                build_file.write(command_str + "\n")
                # Append the command to delete the .buildcmd file after execution
                # build_file.write("rm .buildcmd\n")
        except IOError as e:
            sublime.error_message("Failed to write to .buildcmd: {}".format(e))

    def get_project_folder(self):
        """ Get the first folder in the project. """
        folders = self.window.folders()
        if folders:
            return folders[0]
        return None

    def replace_placeholders(self, arg):
        """ Replace placeholders like $file, $folder with actual values. """
        # Get the current active view
        view = self.window.active_view()

        # Replace $file with the current file name (full path)
        if "$file" in arg:
            if view and view.file_name():
                arg = arg.replace("$file", view.file_name())
            else:
                sublime.error_message("No file open to use for $file!")
                return ""

        # Replace $folder with the folder of the current file
        if "$folder" in arg:
            if view and view.file_name():
                folder = os.path.dirname(view.file_name())
                arg = arg.replace("$folder", folder)
            else:
                sublime.error_message("No file open to determine folder for $folder!")
                return ""

        return arg
