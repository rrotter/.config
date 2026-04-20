#!/usr/bin/env -S zsh --no-rcs

# TODO:
#   - set additional settings w/o using gui
#   - where this isn't possible, detect whether a setting is already applied and skip opening settings app

pause () {
  printf "[ press any key to continue ] "
  read -k
}

# We quit Settings before and after use so it's always in a known state.
# Open modal sheets may prevent loading other pref panes.
quit_settings () {
  osascript -e 'tell app "Settings" to quit'
  sleep 0.8
}

# We just open pref panes and print instructions for user rather using UI scripting. UI scripting
# is brittle, and it requires giving the terminal added permissions which may be unwanted.

quit_settings
open x-apple.systempreferences:com.apple.preference.displays
echo "Please ensure the following are unchecked, if present:"
echo "  - True Tone"
echo "  - Automatically adjust brightness"
pause
quit_settings

## Locale ##
# set language to US English, formats mostly to DE (UK date format for loginwindow), and clock to 24h everywhere

# Setting AppleLocale to en_GB _from the GUI_ is the only way I could get a 24h clock in
# loginwindow at boot. Any other method only affects loginwindow after FileVault is unlocked.
# TODO: figure out how to set this from terminal and remove gui step (or at least detect whether it's needed?)
open x-apple.systempreferences:com.apple.Localization-Settings.extension
echo "Please set Primary language to English (UK). This is to get a 24h clock in loginwindow."
pause
quit_settings

# US English w/ DE time/date/number formats: en_US@rg=dezzzz
# UK English w/ DE time/date/number formats: en_DE
# We need US English set, or we'll get the wrong dictionary, possibly the wrong
# spell check, and probably various other annoyances.
defaults write -g AppleLocale "en_US@rg=dezzzz"
defaults write -g AppleLanguages -array en-US de-DE
defaults write -g AppleICUForce24HourTime 1

# Use UK English for system locale, this affects loginwindow formats _after_ FileVault
# is unlocked, unclear whether it affects anything else.
echo "Setting system-wide locale…"
sudo defaults write /Library/Preferences/.GlobalPreferences.plist AppleLocale en_GB
sudo defaults write /Library/Preferences/.GlobalPreferences.plist AppleLanguages -array en-US de-DE
sudo defaults write /Library/Preferences/.GlobalPreferences.plist AppleICUForce24HourTime 1
sudo -k

# Enable dictation
open x-apple.systempreferences:com.apple.preference.keyboard
echo "Please ensure:"
echo "  - Dictation enabled"
echo "  - Languages added: English (US) and German (Germany)"
pause
quit_settings
