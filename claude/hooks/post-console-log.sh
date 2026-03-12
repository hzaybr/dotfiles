#!/bin/bash
# PostToolUse hook: Detect console.log in JS/TS files after Edit
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

if echo "$FILE" | grep -qE '\.(ts|tsx|js|jsx)$' && [ -f "$FILE" ]; then
  MATCHES=$(grep -n 'console\.log' "$FILE" | head -5)
  if [ -n "$MATCHES" ]; then
    jq -n --arg ctx "[Hook] console.log found in $FILE - remove before committing:
$MATCHES" \
      '{ hookSpecificOutput: { hookEventName: "PostToolUse", additionalContext: $ctx } }'
    exit 0
  fi
fi

echo "$INPUT"
