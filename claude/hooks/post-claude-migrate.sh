#!/bin/bash
# PostToolUse hook: Sync .claude config after Edit/Write on .claude/ files
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

if echo "$FILE" | grep -q '\.claude/'; then
  OUTPUT=$("$HOME/.copilot/migrate.sh" 2>&1 | head -20)
  if [ -n "$OUTPUT" ]; then
    jq -n --arg msg "[Hook] migrate: $OUTPUT" '{ systemMessage: $msg }'
    exit 0
  fi
fi

echo "$INPUT"
