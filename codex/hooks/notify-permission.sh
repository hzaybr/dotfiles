#!/bin/bash
# PermissionRequest hook: macOS notification when Codex asks for permission.
# Mirrors Claude's notify-permission.sh and reuses _notify-helper.sh that the
# Claude sync installs at $HOME/.claude/hooks/.
HELPER="$HOME/.claude/hooks/_notify-helper.sh"
if [ ! -f "$HELPER" ]; then
	cat
	exit 0
fi
# shellcheck source=/dev/null
source "$HELPER"

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Permission approval needed"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

DIR_NAME=$(basename "${CWD:-unknown}" 2>/dev/null)
SESSION_FILE="/tmp/codex-ghostty-${SESSION_ID}"
FRONT_APP=$(get_front_app)

if is_user_on_tab "$SESSION_FILE" "$FRONT_APP"; then
	echo "$INPUT"
	exit 0
fi

send_notification \
	"Codex 🔐" \
	"📁 $DIR_NAME" \
	"$MESSAGE" \
	"Ping" \
	"codex-${SESSION_ID:-default}" \
	""

echo "$INPUT"
