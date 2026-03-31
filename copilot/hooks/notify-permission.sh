#!/bin/bash
# Notification hook: macOS notification when Copilot needs permission approval
# Only notifies when the terminal is NOT in the foreground.

INPUT=$(cat)

# Check if terminal is in the foreground — skip if user is already watching
FRONT_APP=$(perl -e 'alarm 3; exec @ARGV' -- osascript -e 'tell application "System Events" to get name of first process whose frontmost is true' 2>/dev/null)

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

# Read the Ghostty window ID saved by PostToolUse hooks
TITLE_FILE="/tmp/copilot-ghostty-${SESSION_ID}"
WINDOW_TITLE=""
if [ -n "$SESSION_ID" ] && [ -f "$TITLE_FILE" ]; then
	WINDOW_TITLE=$(cat "$TITLE_FILE")
fi

if command -v terminal-notifier &>/dev/null; then
	terminal-notifier \
		-title "Copilot CLI 🔐" \
		-subtitle "📁 $DIR_NAME" \
		-message "$MESSAGE" \
		-sound "Ping" \
		-group "copilot-${SESSION_ID:-default}" \
		-execute "$HOME/.copilot/hooks/focus-ghostty-window.sh '$TITLE_FILE'" \
		2>/dev/null &
else
	perl -e 'alarm 3; exec @ARGV' -- osascript - "$DIR_NAME" "$MESSAGE" <<'APPLESCRIPT' 2>/dev/null
on run argv
  set dirName to item 1 of argv
  set msg to item 2 of argv
  display notification msg with title "Copilot CLI 🔐" subtitle ("📁 " & dirName) sound name "Ping"
end run
APPLESCRIPT
fi

echo "$INPUT"
