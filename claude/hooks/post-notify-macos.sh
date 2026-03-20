#!/bin/bash
# PostToolUse hook: macOS desktop notification when Bash commands complete
# Only notifies when the terminal is NOT in the foreground.
# Skips trivial read-only commands to avoid notification fatigue.

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Strip safe redirections (2>&1, >&2, 2>/dev/null) before checking for writes
STRIPPED=$(echo "$CMD" | sed -E 's/2>&1//g; s/>&2//g; s/2>\/dev\/null//g')

# Skip notification for trivial read-only commands
if echo "$CMD" | grep -qE '^\s*(ls|pwd|which|type|file|wc|du|df|uname|whoami|id|env|printenv|echo)\b' &&
	! echo "$STRIPPED" | grep -qE '[>|]|\btee\b'; then
	echo "$INPUT"
	exit 0
fi

# Check if terminal is in the foreground — skip if user is already watching
FRONT_APP=$(osascript -e 'tell application "System Events" to get name of first process whose frontmost is true' 2>/dev/null)

case "$FRONT_APP" in
Terminal | iTerm2 | WezTerm | Alacritty | kitty | Ghostty | ghostty)
	echo "$INPUT"
	exit 0
	;;
esac

# Truncate long commands for readability
SHORT_CMD="$CMD"
if [ ${#SHORT_CMD} -gt 80 ]; then
	SHORT_CMD="${SHORT_CMD:0:77}..."
fi

# Send macOS notification
osascript - "$SHORT_CMD" <<'APPLESCRIPT' 2>/dev/null
on run argv
  display notification "Command completed" with title "Claude Code" subtitle (item 1 of argv)
end run
APPLESCRIPT

echo "$INPUT"
