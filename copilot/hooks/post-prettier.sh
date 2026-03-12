#!/bin/bash
# PostToolUse hook: Run prettier on supported files after edit
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.toolArgs // ""' | jq -r '.path // .file_path // ""')

if echo "$FILE" | grep -qE '\.(ts|tsx|js|jsx|md|json|css|html|svelte)$' && [ -f "$FILE" ]; then
  npx prettier --write "$FILE" 2>/dev/null
fi

echo "$INPUT"
