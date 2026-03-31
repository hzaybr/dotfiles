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
	# Terminal is in foreground — save the current window ID for later use
	HS="/opt/homebrew/bin/hs"
	if [ -n "$SESSION_ID" ] && [ -x "$HS" ]; then
		perl -e 'alarm 3; exec @ARGV' -- "$HS" -c 'local app = hs.application.find("Ghostty"); if app then local w = app:focusedWindow(); if w then return tostring(w:id()) end end' \
			2>/dev/null | grep -E '^[0-9]+$' >"/tmp/copilot-ghostty-${SESSION_ID}"
	fi
	echo "$INPUT"
	exit 0
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

if command -v terminal-notifier &>/dev/null; then
	terminal-notifier \
		-title "Copilot CLI" \
		-subtitle "📁 $DIR_NAME" \
		-message "✅ $SHORT_CMD" \
		-sound "" \
		-group "copilot-${SESSION_ID:-default}" \
		-activate "com.mitchellh.ghostty" \
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
