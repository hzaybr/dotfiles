#!/bin/bash
# PostToolUse hook: TypeScript type check after edit on .ts/.tsx files
# Note: Copilot ignores postToolUse output, errors go to stderr for logging
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.toolArgs // ""' | jq -r '.path // .file_path // ""')

if echo "$FILE" | grep -qE '\.(ts|tsx)$' && [ -f "$FILE" ]; then
  DIR=$(dirname "$FILE")
  while [ "$DIR" != "/" ] && [ ! -f "$DIR/tsconfig.json" ]; do
    DIR=$(dirname "$DIR")
  done

  if [ -f "$DIR/tsconfig.json" ]; then
    ERRORS=$(npx tsc --noEmit --pretty false 2>&1 | grep "$FILE" | head -10)
    if [ -n "$ERRORS" ]; then
      echo "[Hook] TypeScript errors in $FILE:" >&2
      echo "$ERRORS" >&2
    fi
  fi
fi

echo "$INPUT"
