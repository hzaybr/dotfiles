#!/bin/bash
# PostToolUse hook: Run shfmt on shell files after Edit
SHFMT="$HOME/.local/share/nvim/mason/bin/shfmt"
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

if echo "$FILE" | grep -qE '\.(sh|bash)$' && [ -f "$FILE" ] && [ -x "$SHFMT" ]; then
  "$SHFMT" -w "$FILE" 2>/dev/null
fi

echo "$INPUT"
