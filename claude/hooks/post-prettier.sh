#!/bin/bash
# PostToolUse hook: Run prettier on JS/TS files after Edit
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

if echo "$FILE" | grep -qE '\.(ts|tsx|js|jsx)$' && [ -f "$FILE" ]; then
  npx prettier --write "$FILE" 2>/dev/null
fi

echo "$INPUT"
