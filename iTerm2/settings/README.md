Run the lines below to use the shared settings:

```bash
rm ~/Library/Preferences/*iterm2*
defaults write com.googlecode.iterm2 "LoadPrefsFromCustomFolder" -bool true
defaults write com.googlecode.iterm2 "PrefsCustomFolder" -string "/Users/andrea/.config/iterm2/settings"
```
