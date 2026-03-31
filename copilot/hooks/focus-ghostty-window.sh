#!/bin/bash
# Focus Ghostty and switch to the correct window + tab.
# Reads "windowId:tabIndex" from a temp file.
# Tries window ID first (works across multiple windows),
# falls back to tab-only if window ID is stale.
# Called by terminal-notifier when the notification is clicked.
# Usage: focus-ghostty-window.sh <id-file-path>

ID_FILE="$1"
HS="/opt/homebrew/bin/hs"

# Read "windowId:tabIndex" from the temp file
INFO=""
if [ -f "$ID_FILE" ]; then
	INFO=$(cat "$ID_FILE")
fi

if [ -n "$INFO" ] && [ -x "$HS" ]; then
	WINDOW_ID="${INFO%%:*}"
	TAB_INDEX="${INFO##*:}"
	# Try window ID first, fall back to tab-only
	"$HS" -c "return focusGhosttyWindow($WINDOW_ID, ${TAB_INDEX:-0}) or focusGhosttyTab(${TAB_INDEX:-0})" 2>/dev/null
	exit 0
fi

# Fallback: just activate Ghostty
osascript -e 'tell application "Ghostty" to activate' 2>/dev/null
