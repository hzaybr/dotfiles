#!/bin/bash
# PostToolUse hook: Run stylua on Lua files after edit
STYLUA="$HOME/.local/share/nvim/mason/bin/stylua"
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.toolArgs // ""' | jq -r '.path // .file_path // ""')

if echo "$FILE" | grep -qE '\.lua$' && [ -f "$FILE" ] && [ -x "$STYLUA" ]; then
  "$STYLUA" "$FILE" 2>/dev/null
fi

echo "$INPUT"
