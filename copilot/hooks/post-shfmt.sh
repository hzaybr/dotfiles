#!/bin/bash
# PostToolUse hook: Run shfmt on shell files after edit
SHFMT="$HOME/.local/share/nvim/mason/bin/shfmt"
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.toolArgs // ""' | jq -r '.path // .file_path // ""')

if echo "$FILE" | grep -qE '\.(sh|bash)$' && [ -f "$FILE" ] && [ -x "$SHFMT" ]; then
  "$SHFMT" -w "$FILE" 2>/dev/null
fi

echo "$INPUT"
