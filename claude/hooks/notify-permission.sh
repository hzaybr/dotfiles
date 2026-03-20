#!/bin/bash
# Notification hook: macOS notification when Claude needs permission approval
# Shows working directory and action info so you know which session needs attention.
# If terminal-notifier is installed, clicking the notification focuses the correct Ghostty window.
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

# Parse notification data from JSON
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Permission approval needed"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

# Use directory basename for compact display
DIR_NAME=$(basename "${CWD:-unknown}" 2>/dev/null)

# Read the Ghostty window title saved by PostToolUse hooks (saved while terminal was in foreground)
TITLE_FILE="/tmp/claude-ghostty-${SESSION_ID}"
WINDOW_TITLE=""
if [ -n "$SESSION_ID" ] && [ -f "$TITLE_FILE" ]; then
	WINDOW_TITLE=$(cat "$TITLE_FILE")
fi

if command -v terminal-notifier &>/dev/null; then
	# Rich notification: click to focus the correct Ghostty window
	# -activate handles Space switching via NSWorkspace
	# -execute raises the specific window by title
	terminal-notifier \
		-title "Claude Code 🔐" \
		-subtitle "📁 $DIR_NAME" \
		-message "$MESSAGE" \
		-sound "Ping" \
		-group "claude-${SESSION_ID:-default}" \
		-activate "com.mitchellh.ghostty" \
		-execute "$HOME/.claude/hooks/focus-ghostty-window.sh '$TITLE_FILE'" \
		2>/dev/null &
else
	# Fallback: osascript with enriched info (no click action)
	osascript - "$DIR_NAME" "$MESSAGE" <<'APPLESCRIPT' 2>/dev/null
on run argv
  set dirName to item 1 of argv
  set msg to item 2 of argv
  display notification msg with title "Claude Code 🔐" subtitle ("📁 " & dirName) sound name "Ping"
end run
APPLESCRIPT
fi

echo "$INPUT"
