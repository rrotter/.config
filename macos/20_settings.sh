#!/bin/sh

# open and close apps to ensure that their preference files actually exist
open -a iCal
open -a Safari
sleep 0.8

osascript -e 'tell app "Finder" to quit'
osascript -e 'tell app "iCal" to quit'
osascript -e 'tell app "Safari" to quit'
osascript -e 'tell app "Settings" to quit'
sleep 0.8

### System Settings ###
# silence system beep
install -d ~/.config/macos/Silence.aiff ~/Library/Sounds/Silence.aiff
defaults write -g com.apple.sound.beep.sound /Users/rrotter/Library/Sounds/Silence.aiff

# disable autocorrect
defaults write -g NSAutomaticCapitalizationEnabled -bool false
defaults write -g NSAutomaticDashSubstitutionEnabled -bool false
defaults write -g NSAutomaticInlinePredictionEnabled -bool false
defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false

# menubar clock
defaults write com.apple.menuextra.clock IsAnalog -bool false
defaults write com.apple.menuextra.clock ShowAMPM -bool false
defaults write com.apple.menuextra.clock ShowDate -bool false
defaults write com.apple.menuextra.clock ShowDayOfWeek -bool false
defaults write com.apple.menuextra.clock ShowSeconds -bool true

# Magic Trackpad silent click
defaults write com.apple.AppleMultitouchTrackpad ActuationStrength 0

### Finder ###
# show file extensions, and don't whine when I change them
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# don't use tabs in Finder
defaults write com.apple.finder FinderSpawnTab -bool false

# show drives on Desktop
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true

# New Finder windows show home dir
defaults write com.apple.finder NewWindowTarget PfHm
defaults write com.apple.finder NewWindowTargetPath "file://${HOME}/"

# Finder search scope: Current Folder
defaults write com.apple.finder FXDefaultSearchScope SCcf

open -a Finder

### iCal ###
defaults write com.apple.iCal "TimeZone support enabled" -bool true

### Safari ###
# safari develop menu 
defaults write com.apple.Safari.SandboxBroker ShowDevelopMenu -bool true
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true

# disable spyware
defaults write com.apple.Safari WebKitPreferences.privateClickMeasurementEnabled -bool false

# other Safari settings
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true
