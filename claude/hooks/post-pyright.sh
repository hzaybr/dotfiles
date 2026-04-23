#!/bin/bash
# PostToolUse hook: Pyright type check on Python files after Edit/Write
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

if ! echo "$FILE" | grep -qE '\.py$' || [ ! -f "$FILE" ]; then
	echo "$INPUT"
	exit 0
fi

if command -v pyright >/dev/null 2>&1; then
	PYRIGHT=(pyright)
elif command -v uvx >/dev/null 2>&1; then
	PYRIGHT=(uvx --quiet pyright)
else
	echo "$INPUT"
	exit 0
fi

ERRORS=$("${PYRIGHT[@]}" --outputjson "$FILE" 2>/dev/null |
	jq -r '.generalDiagnostics[]? | select(.severity == "error" or .severity == "warning") | "line \(.range.start.line + 1): \(.severity): \(.message)"' 2>/dev/null)

if [ -n "$ERRORS" ]; then
	jq -n --arg ctx "[Hook] pyright diagnostics in $FILE:
$ERRORS" \
		'{ hookSpecificOutput: { hookEventName: "PostToolUse", additionalContext: $ctx } }'
	exit 0
fi

echo "$INPUT"
