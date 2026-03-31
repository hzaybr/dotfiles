#!/bin/bash
# PostToolUse hook: macOS desktop notification when Bash commands complete
# Shows working directory so you know which session finished.
# Also saves the Ghostty window ID while terminal is in foreground,
# so the notification hook can find the correct window later.
# Skips trivial read-only commands to avoid notification fatigue.

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.toolArgs // ""' | jq -r '.command // ""')

# Strip safe redirections before checking for writes
STRIPPED=$(echo "$CMD" | sed -E 's/2>&1//g; s/>&2//g; s/2>\/dev\/null//g')

# Skip notification for trivial read-only commands
if echo "$CMD" | grep -qE '^\s*(ls|pwd|which|type|file|wc|du|df|uname|whoami|id|env|printenv|echo)\b' &&
	! echo "$STRIPPED" | grep -qE '[>|]|\btee\b'; then
	echo "$INPUT"
	exit 0
fi

# Parse context
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
DIR_NAME=$(basename "${CWD:-unknown}" 2>/dev/null)

# Check if terminal is in the foreground
FRONT_APP=$(perl -e 'alarm 3; exec @ARGV' -- osascript -e 'tell application "System Events" to get name of first process whose frontmost is true' 2>/dev/null)

case "$FRONT_APP" in
Ghostty | ghostty)
	HS="/opt/homebrew/bin/hs"
	SESSION_FILE="/tmp/copilot-ghostty-${SESSION_ID}"
	if [ -n "$SESSION_ID" ] && [ -x "$HS" ]; then
		CURRENT_INFO=$(perl -e 'alarm 3; exec @ARGV' -- "$HS" -c 'return getGhosttyWindowInfo()' \
			2>/dev/null | grep -E '^[0-9]+:[0-9]+$')
		SAVED_INFO=""
		[ -f "$SESSION_FILE" ] && SAVED_INFO=$(cat "$SESSION_FILE")

		if [ -z "$SAVED_INFO" ] || [ "$CURRENT_INFO" = "$SAVED_INFO" ]; then
			# User is on this session's tab (or first time) — save and skip
			[ -n "$CURRENT_INFO" ] && echo "$CURRENT_INFO" >"$SESSION_FILE"
			echo "$INPUT"
			exit 0
		fi
		# User is on a different tab — fall through to notify
	else
		# No session ID or no Hammerspoon — skip notification
		echo "$INPUT"
		exit 0
	fi
	;;
Terminal | iTerm2 | WezTerm | Alacritty | kitty)
	echo "$INPUT"
	exit 0
	;;
esac

# Truncate long commands for readability
SHORT_CMD="$CMD"
if [ ${#SHORT_CMD} -gt 80 ]; then
	SHORT_CMD="${SHORT_CMD:0:77}..."
fi

SESSION_FILE="/tmp/copilot-ghostty-${SESSION_ID}"
if command -v terminal-notifier &>/dev/null; then
	terminal-notifier \
		-title "Copilot CLI" \
		-subtitle "📁 $DIR_NAME" \
		-message "✅ $SHORT_CMD" \
		-sound "" \
		-group "copilot-${SESSION_ID:-default}" \
		-activate "com.mitchellh.ghostty" \
		-execute "$HOME/.copilot/hooks/focus-ghostty-window.sh '$SESSION_FILE'" \
		2>/dev/null &
else
	perl -e 'alarm 3; exec @ARGV' -- osascript - "$DIR_NAME" "$SHORT_CMD" <<'APPLESCRIPT' 2>/dev/null
on run argv
  set dirName to item 1 of argv
  set cmd to item 2 of argv
  display notification ("✅ " & cmd) with title "Copilot CLI" subtitle ("📁 " & dirName)
end run
APPLESCRIPT
fi

echo "$INPUT"
