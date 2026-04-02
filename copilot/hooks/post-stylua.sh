#!/bin/bash
# PostToolUse hook: Run stylua on Lua files after edit
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.toolArgs // ""' | jq -r '.path // .file_path // ""')

STYLUA=$(command -v stylua 2>/dev/null || echo "$HOME/.local/share/nvim/mason/bin/stylua")

if echo "$FILE" | grep -qE '\.lua$' && [ -f "$FILE" ] && [ -x "$STYLUA" ]; then
	"$STYLUA" "$FILE" 2>/dev/null
fi

echo "$INPUT"
