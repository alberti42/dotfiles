import os
import sublime
import sublime_plugin


class NewScratchCommand(sublime_plugin.WindowCommand):
    def run(self):
        view = self.window.new_file()
        if view:
            view.set_scratch(True)
            view.set_name("*Scratch*")


class CloseWithoutSavingCommand(sublime_plugin.WindowCommand):
    def run(self):
        view = self.window.active_view()
        if view:
            view.set_scratch(True)
            view.close()
            return
        sheet = self.window.active_sheet()
        if sheet:
            sheet.close()


class SmartCloseCommand(sublime_plugin.WindowCommand):
    """
    Override the close command to handle empty non-existent files gracefully.

    This command solves the annoying problem where Sublime Text prompts to save
    when closing a non-existent file that was opened but never edited.

    Example scenario:
    - User types: subl myfile.txt (but file doesn't exist)
    - User realizes it's the wrong file and wants to close it
    - Normally: Sublime prompts "Do you want to save?"
    - With this: Closes silently if nothing was typed
    """

    def run(self):
        # Get the currently active view (tab) in the window
        view = self.window.active_view()

        # Make sure we have a valid view to work with
        if view:
            # Get the file path associated with this view
            # This will be None for untitled files, or a path for named files
            file_path = view.file_name()

            # Check if this view has a file path assigned to it
            if file_path:
                # Check if the file actually exists on disk
                # This is False for files opened with 'subl nonexistent.txt'
                file_exists = os.path.exists(file_path)

                if not file_exists:
                    # The file doesn't exist on disk, so check if it's worth saving

                    # Get the size of the buffer (number of characters)
                    buffer_size = view.size()

                    # Check if the buffer has been modified
                    # This is False if user hasn't typed anything
                    is_modified = view.is_dirty()

                    # If the buffer is empty (size 0) AND hasn't been modified
                    if buffer_size == 0 and not is_modified:
                        # This is an empty, non-existent file that user never touched
                        # Mark it as scratch so Sublime won't prompt to save
                        view.set_scratch(True)

                        # Now close it - this won't prompt because it's scratch
                        view.close()

                        # Exit early - we've handled the close ourselves
                        return

        # If we get here, it means one of these:
        # - No active view
        # - File exists on disk
        # - File doesn't exist but has content
        # - File doesn't exist but was modified
        # In all these cases, use Sublime's default close behavior
        self.window.run_command("close")


# vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4 :
