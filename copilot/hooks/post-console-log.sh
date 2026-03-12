#!/bin/bash
# PostToolUse hook: Detect console.log in JS/TS files after edit
# Note: Copilot ignores postToolUse output, warnings go to stderr for logging
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.toolArgs // ""' | jq -r '.path // .file_path // ""')

if echo "$FILE" | grep -qE '\.(ts|tsx|js|jsx)$' && [ -f "$FILE" ]; then
  MATCHES=$(grep -n 'console\.log' "$FILE" | head -5)
  if [ -n "$MATCHES" ]; then
    echo "[Hook] console.log found in $FILE - remove before committing:" >&2
    echo "$MATCHES" >&2
  fi
fi

echo "$INPUT"
