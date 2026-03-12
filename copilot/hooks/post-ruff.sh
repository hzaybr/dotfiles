#!/bin/bash
# PostToolUse hook: Ruff format + lint on Python files after edit
# Note: Copilot ignores postToolUse output, lint warnings go to stderr for logging
RUFF="$HOME/.local/bin/ruff"
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.toolArgs // ""' | jq -r '.path // .file_path // ""')

if echo "$FILE" | grep -qE '\.py$' && [ -f "$FILE" ] && [ -x "$RUFF" ]; then
  "$RUFF" format --quiet "$FILE" 2>/dev/null
  LINT=$("$RUFF" check --quiet "$FILE" 2>&1)
  if [ -n "$LINT" ]; then
    echo "[Hook] Ruff lint issues in $FILE:" >&2
    echo "$LINT" >&2
  fi
fi

echo "$INPUT"
