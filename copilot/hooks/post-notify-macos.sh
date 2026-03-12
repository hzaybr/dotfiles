#!/bin/bash
# PostToolUse hook: macOS desktop notification when Bash commands complete
# Only notifies when the terminal is NOT in the foreground.

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.toolArgs // ""' | jq -r '.command // ""')

# Truncate long commands for readability
if [ ${#CMD} -gt 80 ]; then
  CMD="${CMD:0:77}..."
fi

# Check if terminal is in the foreground — skip if user is already watching
FRONT_APP=$(osascript -e 'tell application "System Events" to get name of first process whose frontmost is true' 2>/dev/null)

case "$FRONT_APP" in
  Terminal|iTerm2|WezTerm|Alacritty|kitty|Ghostty|ghostty)
    echo "$INPUT"
    exit 0
    ;;
esac

# Send macOS notification
osascript - "$CMD" <<'APPLESCRIPT' 2>/dev/null
on run argv
  display notification "Command completed" with title "Copilot CLI ✅" subtitle (item 1 of argv)
end run
APPLESCRIPT

echo "$INPUT"
