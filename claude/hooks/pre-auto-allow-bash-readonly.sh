#!/bin/bash
# PreToolUse hook: Auto-approve read-only bash commands (ls, pwd, which, etc.)

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Strip safe redirections (2>&1, >&2, 2>/dev/null) before checking for writes
STRIPPED=$(echo "$CMD" | sed -E 's/2>&1//g; s/>&2//g; s/2>\/dev\/null//g')

if echo "$CMD" | grep -qE '^\s*(ls|pwd|which|type|file|wc|du|df|uname|whoami|id|env|printenv|echo)\b' &&
	! echo "$STRIPPED" | grep -qE '[>|]|\btee\b'; then
	jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "allow",
      permissionDecisionReason: "Read-only bash command auto-approved by hook"
    }
  }'
else
	echo "$INPUT"
fi
