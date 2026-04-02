#!/bin/bash
# Notification hook: macOS notification when Claude needs permission approval
# Shows working directory and action info so you know which session needs attention.
# If terminal-notifier is installed, clicking the notification focuses the correct Ghostty window.
# Only notifies when the terminal is NOT in the foreground.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_notify-helper.sh
source "$SCRIPT_DIR/_notify-helper.sh"

INPUT=$(cat)

# Parse notification data from JSON
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Permission approval needed"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

# Use directory basename for compact display
DIR_NAME=$(basename "${CWD:-unknown}" 2>/dev/null)

SESSION_FILE="/tmp/claude-ghostty-${SESSION_ID}"
FRONT_APP=$(get_front_app)

if is_user_on_tab "$SESSION_FILE" "$FRONT_APP"; then
	echo "$INPUT"
	exit 0
fi

# Only pass focus script if session file exists (written by post-notify-macos when user was watching)
FOCUS_SCRIPT=""
if [ -f "$SESSION_FILE" ]; then
	FOCUS_SCRIPT="$HOME/.claude/hooks/focus-ghostty-window.sh '$SESSION_FILE'"
fi

send_notification \
	"Claude Code 🔐" \
	"📁 $DIR_NAME" \
	"$MESSAGE" \
	"Ping" \
	"claude-${SESSION_ID:-default}" \
	"$FOCUS_SCRIPT"

echo "$INPUT"
