#!/bin/bash
# PreToolUse hook: Auto-approve read-only bash commands (ls, pwd, which, etc.)

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

if echo "$CMD" | grep -qE '^\s*(ls|pwd|which|type|file|wc|du|df|uname|whoami|id|env|printenv|echo)\b' &&
	! echo "$CMD" | grep -qE '[>|]|tee\b'; then
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
