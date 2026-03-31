#!/bin/bash
# Focus a specific Ghostty window by its saved window ID.
# Uses Hammerspoon CLI to call focusGhosttyWindow() directly.
# Called by terminal-notifier when the notification is clicked.
# Usage: focus-ghostty-window.sh <id-file-path>

ID_FILE="$1"
HS="/opt/homebrew/bin/hs"

# Read the window ID from the temp file
WINDOW_ID=""
if [ -f "$ID_FILE" ]; then
	WINDOW_ID=$(cat "$ID_FILE")
fi

if [ -n "$WINDOW_ID" ] && [ -x "$HS" ]; then
	"$HS" -c "focusGhosttyWindow($WINDOW_ID)" 2>/dev/null
	exit 0
fi

# Fallback: just activate Ghostty
osascript -e 'tell application "Ghostty" to activate' 2>/dev/null
