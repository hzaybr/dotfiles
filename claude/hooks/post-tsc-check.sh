#!/bin/bash
# PostToolUse hook: TypeScript type check after Edit on .ts/.tsx files
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

if echo "$FILE" | grep -qE '\.(ts|tsx)$' && [ -f "$FILE" ]; then
  DIR=$(dirname "$FILE")
  while [ "$DIR" != "/" ] && [ ! -f "$DIR/tsconfig.json" ]; do
    DIR=$(dirname "$DIR")
  done

  if [ -f "$DIR/tsconfig.json" ]; then
    ERRORS=$(npx tsc --noEmit --pretty false 2>&1 | grep "$FILE" | head -10)
    if [ -n "$ERRORS" ]; then
      jq -n --arg reason "[Hook] TypeScript errors found in $FILE:
$ERRORS" \
        '{ decision: "block", reason: $reason }'
      exit 0
    fi
  fi
fi

echo "$INPUT"
