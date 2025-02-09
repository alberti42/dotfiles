# conda-manager.plugin.zsh
# (c) Andrea Alberti, 2024

# Get the directory of this plugin file
plugin_dir="${0:A:h}"

# Source all files in the `src` directory
for file in "$plugin_dir/src/_"*; do
  # Ensure it is a readable file before sourcing
  [ -r "$file" ] && source "$file"
done
