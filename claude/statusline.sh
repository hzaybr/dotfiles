#!/bin/bash
input=$(cat)

MODEL_DISPLAY=$(echo "$input" | jq -r '.model.display_name')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir')
CONTEXT_REMAINING=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

RESET='\033[0m'
CYAN='\033[36m'
BLUE='\033[34m'
YELLOW='\033[33m'
GREEN='\033[32m'
MAGENTA='\033[35m'
RED='\033[31m'
DIM='\033[2m'

SHORT_DIR=$(echo "$CURRENT_DIR" | sed "s|^$HOME|~|")
USER_HOST="$(whoami)@$(hostname -s)"

# Git info
GIT_PART=""
GIT_PLAIN=""
if git rev-parse --git-dir >/dev/null 2>&1; then
  BRANCH=$(git branch --show-current 2>/dev/null)
  if [ -n "$BRANCH" ]; then
    GIT_STATUS=""
    if [ -n "$(git status --porcelain 2>/dev/null | head -1)" ]; then
      GIT_STATUS="*"
    fi
    GIT_PLAIN=" ⎇ ${BRANCH}${GIT_STATUS}"
    GIT_PART=" ${GREEN}⎇ ${BRANCH}${GIT_STATUS}${RESET}"
  fi
fi

# Right side: model + context
RIGHT_PLAIN="[${MODEL_DISPLAY}]"
RIGHT_COLORED="${MAGENTA}[${MODEL_DISPLAY}]${RESET}"
if [ -n "$CONTEXT_REMAINING" ]; then
  if [ "$CONTEXT_REMAINING" -gt 50 ]; then
    CTX_COLOR=$GREEN
  elif [ "$CONTEXT_REMAINING" -gt 20 ]; then
    CTX_COLOR=$YELLOW
  else
    CTX_COLOR=$RED
  fi
  RIGHT_PLAIN="${RIGHT_PLAIN} ⚡${CONTEXT_REMAINING}%"
  RIGHT_COLORED="${RIGHT_COLORED} ${CTX_COLOR}⚡${CONTEXT_REMAINING}%${RESET}"
fi

# Get terminal width
TERM_WIDTH=$(stty size 2>/dev/null </dev/tty | awk '{print $2}')
if [ -z "$TERM_WIDTH" ] || [ "$TERM_WIDTH" -eq 0 ] 2>/dev/null; then
  TERM_WIDTH=${COLUMNS:-$(tput cols 2>/dev/null || echo 120)}
fi
# Safety margin for wide unicode chars (•, ⚡ may render as 2 columns)
TERM_WIDTH=$((TERM_WIDTH - 6))

# Left side plain text for length calculation
LEFT_PLAIN="ᖰ•ᴥ•ᖳ ${SHORT_DIR}${GIT_PLAIN}"
LEFT_COLORED="${BLUE}ᖰ•ᴥ•ᖳ ${SHORT_DIR}${RESET}${GIT_PART}"

# Calculate padding
LEFT_LEN=${#LEFT_PLAIN}
RIGHT_LEN=${#RIGHT_PLAIN}
PADDING=$((TERM_WIDTH - LEFT_LEN - RIGHT_LEN))
if [ $PADDING -lt 1 ]; then
  PADDING=1
fi

# Output with space padding between left and right
printf "%b%*s%b" "$LEFT_COLORED" "$PADDING" "" "$RIGHT_COLORED"
