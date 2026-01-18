# EXIF (ExifTool) Sublime syntax + bat integration

This repo contains an `EXIF.sublime-syntax` for highlighting `exiftool` output.

## Install in Sublime Text

1. Find your Sublime **User** package directory:

   - **Linux:** `~/.config/sublime-text/Packages/User/`
   - **macOS:** `~/Library/Application Support/Sublime Text/Packages/User/`
   - **Windows:** `%APPDATA%\Sublime Text\Packages\User\`

2. Copy the syntax file there:

   ```sh
   cp EXIF.sublime-syntax ~/.config/sublime-text/Packages/User/
   ```

3. Open exif output:
   - Save exif output to a file ending in `.exif` or `.exiftool`, then open it in Sublime.
   - Or paste it in Sublime and use **View → Syntax → EXIF (ExifTool)**.

## Install for `bat`

`bat` can load Sublime `.sublime-syntax` files from its configuration directory.

1. Find `bat`’s config directory:

   ```sh
   bat --config-dir
   ```

   On Linux this is usually: `~/.config/bat/`

2. Create the `syntaxes` directory if it doesn’t exist:

   ```sh
   mkdir -p "$(bat --config-dir)/syntaxes"
   ```

3. Copy the syntax file:

   ```sh
   cp EXIF.sublime-syntax "$(bat --config-dir)/syntaxes/"
   ```

4. Rebuild `bat`’s syntax cache (required):

   ```sh
   bat cache --build
   ```

5. Use it:

   ```sh
   exiftool -- file.jpg | bat --plain --color=always -l exif
   ```

## Notes

- `bat` recognizes the syntax after `bat cache --build`.
- If you change the syntax file later, run `bat cache --build` again.
