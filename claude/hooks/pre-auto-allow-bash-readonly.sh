#!/bin/bash
# PreToolUse hook: Auto-approve read-only bash commands (ls, pwd, cat, etc.)

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Safe read-only commands that cannot modify the filesystem
SAFE_CMDS='^\s*(ls|pwd|which|type|file|wc|du|df|uname|whoami|id|env|printenv|echo|cat|head|tail|less|bat|stat|readlink|realpath|hostname|date|uptime|sw_vers|man|nproc|free|lsof|ps|pgrep|top)\b'

# Safe pipe targets — commands that only read/filter/format output
SAFE_PIPE='(head|tail|wc|grep|sort|uniq|less|bat|cat|cut|awk|sed|tr|column|jq|fzf)\b'

# Strip safe redirections (2>&1, >&2, 2>/dev/null) before checking for writes
STRIPPED=$(echo "$CMD" | sed -E 's/2>&1//g; s/>&2//g; s/2>\/dev\/null//g')

if echo "$CMD" | grep -qE "$SAFE_CMDS"; then
	# Block output redirects (>) and tee (writes to file)
	if echo "$STRIPPED" | grep -qE '>|\btee\b'; then
		echo "$INPUT"
		exit 0
	fi

	# Allow pipes only if every pipe target is a safe read-only command
	if echo "$STRIPPED" | grep -qE '\|'; then
		UNSAFE=false
		# Split on | and check each segment after the first
		REMAINING=$(echo "$STRIPPED" | sed 's/^[^|]*|//')
		while echo "$REMAINING" | grep -qE '\|'; do
			SEGMENT=$(echo "$REMAINING" | sed 's/|.*//' | sed 's/^[[:space:]]*//')
			if [ -n "$SEGMENT" ] && ! echo "$SEGMENT" | grep -qE "^$SAFE_PIPE"; then
				UNSAFE=true
				break
			fi
			REMAINING=$(echo "$REMAINING" | sed 's/^[^|]*|//')
		done
		# Check the last segment
		LAST=$(echo "$REMAINING" | sed 's/^[[:space:]]*//')
		if [ -n "$LAST" ] && ! echo "$LAST" | grep -qE "^$SAFE_PIPE"; then
			UNSAFE=true
		fi

		if [ "$UNSAFE" = true ]; then
			echo "$INPUT"
			exit 0
		fi
	fi

	jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "allow",
      permissionDecisionReason: "Read-only bash command auto-approved by hook"
    }
  }'
else
	echo "$INPUT"
fi
