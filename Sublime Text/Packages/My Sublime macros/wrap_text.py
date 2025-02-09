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

class UnwrapTextCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        # Iterate over each selection and wrap the text
        for region in self.view.sel():
            if not region.empty():
                # Get the text in the region and unwrap it
                selected_text = self.view.substr(region)
                unwrapped_text = self.unwrap_text(selected_text)

                # Replace the selected text with the unwrapped version
                self.view.replace(edit, region, unwrapped_text)

    # def expand_to_paragraph(self, region):
    #     # Expand the region to the start and end of the paragraph
    #     start = self.view.find_by_class(region.begin(), False, sublime.CLASS_EMPTY_LINE)
    #     end = self.view.find_by_class(region.end(), True, sublime.CLASS_EMPTY_LINE)
    #     return sublime.Region(start, end)

    def unwrap_text(self, text):
        # Remove line breaks and replace with single spaces
        lines = text.splitlines()
        return ' '.join(line.strip() for line in lines)
        
# class ReplaceTextCommand(sublime_plugin.TextCommand):
#     def run(self, edit, region, wrapped_text):
#         # Replace the text in the given region with the wrapped text
#         region_to_replace = sublime.Region(region[0], region[1])
#         self.view.replace(edit, region_to_replace, wrapped_text)
