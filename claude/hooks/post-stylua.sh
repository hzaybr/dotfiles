#!/bin/bash
# PostToolUse hook: Run stylua on Lua files after Edit
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

STYLUA=$(command -v stylua 2>/dev/null || echo "$HOME/.local/share/nvim/mason/bin/stylua")

if echo "$FILE" | grep -qE '\.lua$' && [ -f "$FILE" ] && [ -x "$STYLUA" ]; then
	"$STYLUA" "$FILE" 2>/dev/null
fi

echo "$INPUT"
