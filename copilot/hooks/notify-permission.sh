#!/bin/bash
# Notification hook: macOS notification when Copilot needs permission approval
# Only notifies when the terminal is NOT in the foreground.

INPUT=$(cat)

# Check if terminal is in the foreground — skip if user is already watching
FRONT_APP=$(perl -e 'alarm 3; exec @ARGV' -- osascript -e 'tell application "System Events" to get name of first process whose frontmost is true' 2>/dev/null)

# Parse notification data from JSON
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Permission approval needed"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

# Use directory basename for compact display
DIR_NAME=$(basename "${CWD:-unknown}" 2>/dev/null)

SESSION_FILE="/tmp/copilot-ghostty-${SESSION_ID}"

case "$FRONT_APP" in
Ghostty | ghostty)
	# Check if user is on this session's tab
	HS="/opt/homebrew/bin/hs"
	if [ -n "$SESSION_ID" ] && [ -x "$HS" ]; then
		CURRENT_INFO=$(perl -e 'alarm 3; exec @ARGV' -- "$HS" -c 'return getGhosttyWindowInfo()' \
			2>/dev/null | grep -E '^[0-9]+:[0-9]+$')
		SAVED_INFO=""
		[ -f "$SESSION_FILE" ] && SAVED_INFO=$(cat "$SESSION_FILE")

		if [ -n "$SAVED_INFO" ] && [ "$CURRENT_INFO" = "$SAVED_INFO" ]; then
			# User is on this tab — skip notification
			echo "$INPUT"
			exit 0
		fi
	else
		echo "$INPUT"
		exit 0
	fi
	# User is on a different tab — fall through to notify
	;;
Terminal | iTerm2 | WezTerm | Alacritty | kitty)
	echo "$INPUT"
	exit 0
	;;
esac

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
