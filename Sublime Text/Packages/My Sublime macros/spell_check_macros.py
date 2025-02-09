import sublime
import sublime_plugin
from typing import Any, Dict
import os
import sys
import re 

# Add the plugin directory to sys.path
plugin_dir = os.path.dirname(__file__)
sys.path.append(os.path.join(plugin_dir, "json5"))

class SwitchDictionaryCommand(sublime_plugin.ApplicationCommand):
    def run(self, **args):
        # Handle Preferences.sublime-settings
        language = args.get('language', None)
        if language:
            preferences_settings = sublime.load_settings("Preferences.sublime-settings")
            preferences_settings.set("dictionary", language)
            sublime.save_settings("Preferences.sublime-settings")

        # Handle LSP-ltex-ls.sublime-settings
        ltex_language = args.get('ltex.language', None)
        if ltex_language:
            # Construct the file path manually
            ltex_file_path = os.path.join(sublime.packages_path(), "User", "LSP-ltex-ls.sublime-settings")

            # Read the file as text
            with open(ltex_file_path, 'r') as file:
                content = file.read()

            # Replace only the `settings` part in the original content
            pattern = r'("ltex.language"\s*:\s*").*?(")'
            replacement = f'\\1{ltex_language}\\2'

            new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)

            # Write the updated content back to the file
            with open(ltex_file_path, 'w') as file:
                file.write(new_content)
