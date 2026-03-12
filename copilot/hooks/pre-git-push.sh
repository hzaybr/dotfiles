#!/bin/bash
# PreToolUse hook: Deny git push to prompt manual review
# Copilot only supports "deny" (not "ask"), so we block and explain

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.toolName // ""')
CMD=$(echo "$INPUT" | jq -r '.toolArgs // ""' | jq -r '.command // ""')

if [ "$TOOL" = "bash" ] || [ "$TOOL" = "Bash" ]; then
  if echo "$CMD" | grep -q "git push"; then
    jq -n '{
      permissionDecision: "deny",
      permissionDecisionReason: "Review changes before pushing to remote. Run git push manually after review."
    }'
    exit 0
  fi
fi

echo "$INPUT"
