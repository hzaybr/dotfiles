#!/bin/bash
# Notification hook: macOS notification when Claude needs permission approval
# Only notifies when the terminal is NOT in the foreground.

INPUT=$(cat)

# Check if terminal is in the foreground — skip if user is already watching
FRONT_APP=$(osascript -e 'tell application "System Events" to get name of first process whose frontmost is true' 2>/dev/null)

case "$FRONT_APP" in
Terminal | iTerm2 | WezTerm | Alacritty | kitty | Ghostty | ghostty)
	echo "$INPUT"
	exit 0
	;;
esac

# Send macOS notification
osascript -e 'display notification "Permission approval needed" with title "Claude Code 🔐" sound name "Ping"' 2>/dev/null

echo "$INPUT"
