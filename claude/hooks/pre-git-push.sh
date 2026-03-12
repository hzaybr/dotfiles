#!/bin/bash
# PreToolUse hook: Prompt user before git push
# Uses permissionDecision: "ask" to show a confirmation dialog

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

if echo "$CMD" | grep -q "git push"; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "ask",
      permissionDecisionReason: "Review changes before pushing to remote"
    }
  }'
else
  echo "$INPUT"
fi
