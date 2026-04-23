#!/bin/bash
# Stop hook: run project-level checks when relevant files changed.
# Uses git diff as a proxy for "what was touched" — includes pre-existing
# uncommitted work, which may surface unrelated errors. Acceptable trade-off.
INPUT=$(cat)

CHANGED=$( (
	git diff --name-only HEAD 2>/dev/null
	git ls-files --others --exclude-standard 2>/dev/null
) | sort -u)

[ -z "$CHANGED" ] && {
	echo "$INPUT"
	exit 0
}

MESSAGES=""

# Strip ANSI escape and low-ASCII control chars so jq output stays valid JSON.
# Keeps \t (0x09), \n (0x0A), \r (0x0D); drops 0x00–0x08, 0x0B, 0x0C, 0x0E–0x1F.
strip_ctrl() {
	printf "%s" "$1" | LC_ALL=C tr -d '\000-\010\013\014\016-\037'
}

# TS / JS / Svelte → bun run check
if echo "$CHANGED" | grep -qE '\.(ts|tsx|js|jsx|svelte)$' && [ -f "package.json" ]; then
	if command -v bun >/dev/null 2>&1 && jq -e '.scripts.check' package.json >/dev/null 2>&1; then
		OUT=$(FORCE_COLOR=0 NO_COLOR=1 bun run check 2>&1)
		if [ $? -ne 0 ]; then
			OUT=$(strip_ctrl "$OUT")
			MESSAGES+="[Stop] bun run check failed:
$OUT

"
		fi
	fi
fi

# Rust → cargo check
if echo "$CHANGED" | grep -qE '\.rs$' && [ -f "Cargo.toml" ] && command -v cargo >/dev/null 2>&1; then
	OUT=$(CARGO_TERM_COLOR=never cargo check --quiet 2>&1)
	if [ $? -ne 0 ]; then
		OUT=$(strip_ctrl "$OUT")
		MESSAGES+="[Stop] cargo check failed:
$OUT

"
	fi
fi

if [ -n "$MESSAGES" ]; then
	jq -n --arg ctx "$MESSAGES" \
		'{ hookSpecificOutput: { hookEventName: "Stop", additionalContext: $ctx } }'
	exit 0
fi

echo "$INPUT"
