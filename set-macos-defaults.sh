#!/bin/zsh

#sudo codesign --force --deep --sign - /Applications/Utilities/XQuartz.app

chflags nohidden ~/Library

defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1
defaults write com.apple.commerce AutoUpdate -bool true


defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

defaults write com.apple.universalaccess reduceTransparency -bool true


defaults write NSGlobalDomain AppleShowAllExtensions -bool true

defaults write com.apple.finder ShowStatusBar -bool true

defaults write com.apple.finder ShowPathbar -bool true

defaults write com.apple.Safari ShowFavoritesBar -bool false

defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

defaults write NSGlobalDomain AppleShowScrollBars -string "Always"

defaults write NSGlobalDomain NSUseAnimatedFocusRing -bool false

defaults write com.apple.LaunchServices LSQuarantine -bool false

defaults write com.apple.CrashReporter DialogType -string "none"

defaults write com.apple.Safari UniversalSearchEnabled -bool false
defaults write com.apple.Safari SuppressSearchSuggestions -bool true
defaults write com.apple.Safari ShowSidebarInTopSites -bool false

defaults write com.apple.finder DisableAllAnimations -bool true

defaults write com.apple.dock launchanim -bool false

defaults write org.macosforge.xquartz.X11 app_to_run /usr/bin/true

sudo chflags nohidden /Volumes

sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true
