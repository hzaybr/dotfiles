#!/bin/bash
# PostToolUse hook: Run shfmt on shell files after edit
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.toolArgs // ""' | jq -r '.path // .file_path // ""')

SHFMT=$(command -v shfmt 2>/dev/null || echo "$HOME/.local/share/nvim/mason/bin/shfmt")

if echo "$FILE" | grep -qE '\.(sh|bash)$' && [ -f "$FILE" ] && [ -x "$SHFMT" ]; then
	"$SHFMT" -w "$FILE" 2>/dev/null
fi

echo "$INPUT"
