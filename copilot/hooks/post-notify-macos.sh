#!/bin/bash
# PostToolUse hook: macOS desktop notification when Bash commands complete
# Shows working directory so you know which session finished.
# Also saves the Ghostty window ID while terminal is in foreground,
# so the notification hook can find the correct window later.
# Skips trivial read-only commands to avoid notification fatigue.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_notify-helper.sh
source "$SCRIPT_DIR/_notify-helper.sh"

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
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // .sessionId // empty')
DIR_NAME=$(basename "${CWD:-unknown}" 2>/dev/null)

SESSION_FILE="/tmp/copilot-ghostty-${SESSION_ID}"
FRONT_APP=$(get_front_app)

if is_user_on_tab "$SESSION_FILE" "$FRONT_APP" save; then
	echo "$INPUT"
	exit 0
fi

# Truncate long commands for readability
SHORT_CMD="$CMD"
if [ ${#SHORT_CMD} -gt 80 ]; then
	SHORT_CMD="${SHORT_CMD:0:77}..."
fi

refresh_session_window "$SESSION_FILE"

send_notification \
	"Copilot CLI" \
	"📁 $DIR_NAME" \
	"✅ $SHORT_CMD" \
	"" \
	"copilot-${SESSION_ID:-default}" \
	"$HOME/.copilot/hooks/focus-ghostty-window.sh '$SESSION_FILE'"

echo "$INPUT"
