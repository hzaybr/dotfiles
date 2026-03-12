#!/bin/bash
# PostToolUse hook: Ruff format + lint on Python files after Edit/Write
RUFF="$HOME/.local/bin/ruff"
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

if echo "$FILE" | grep -qE '\.py$' && [ -f "$FILE" ] && [ -x "$RUFF" ]; then
  "$RUFF" format --quiet "$FILE" 2>/dev/null
  LINT=$("$RUFF" check --quiet "$FILE" 2>&1)
  if [ -n "$LINT" ]; then
    jq -n --arg ctx "[Hook] Ruff lint issues in $FILE:
$LINT" \
      '{ hookSpecificOutput: { hookEventName: "PostToolUse", additionalContext: $ctx } }'
    exit 0
  fi
fi

echo "$INPUT"
