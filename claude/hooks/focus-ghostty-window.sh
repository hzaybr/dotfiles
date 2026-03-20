#!/bin/bash
# Focus a specific Ghostty window by its title saved in a temp file.
# Works across macOS Spaces by setting the window as main before activating.
# Called by terminal-notifier when the notification is clicked.
# Usage: focus-ghostty-window.sh <title-file-path>

TITLE_FILE="$1"

# Read the window title from the temp file
WINDOW_TITLE=""
if [ -f "$TITLE_FILE" ]; then
	WINDOW_TITLE=$(cat "$TITLE_FILE")
fi

if [ -z "$WINDOW_TITLE" ]; then
	osascript -e 'tell application "Ghostty" to activate' 2>/dev/null
	exit 0
fi

# Raise the specific window and activate Ghostty.
# Setting AXMain forces macOS to switch to the Space containing this window.
osascript - "$WINDOW_TITLE" <<'APPLESCRIPT' 2>/dev/null
on run argv
  set targetTitle to item 1 of argv
  tell application "System Events"
    tell process "ghostty"
      set windowList to every window
      repeat with w in windowList
        if name of w is targetTitle then
          -- Force this window to become the main window (triggers Space switch)
          set value of attribute "AXMain" of w to true
          perform action "AXRaise" of w
          exit repeat
        end if
      end repeat
    end tell
  end tell
  tell application "Ghostty" to activate
end run
APPLESCRIPT
