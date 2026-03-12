#!/bin/bash
# PostToolUse hook: Run stylua on Lua files after Edit
STYLUA="$HOME/.local/share/nvim/mason/bin/stylua"
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

if echo "$FILE" | grep -qE '\.lua$' && [ -f "$FILE" ] && [ -x "$STYLUA" ]; then
  "$STYLUA" "$FILE" 2>/dev/null
fi

echo "$INPUT"
