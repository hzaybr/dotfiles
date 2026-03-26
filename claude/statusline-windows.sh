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

SHORT_DIR=$(echo "$CURRENT_DIR" | sed "s|^$HOME|~|" | sed 's|^/c/Users/|~/|;s|^\(~/[^/]*\)/|\1/|')
USER_HOST="$(whoami)@$(hostname)"

# Git info
GIT_PART=""
GIT_PLAIN=""
if git rev-parse --git-dir >/dev/null 2>&1; then
  BRANCH=$(git branch --show-current 2>/dev/null)
  if [ -n "$BRANCH" ]; then
    GIT_INDICATORS=""
    STAGED=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    UNSTAGED=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    AHEAD=$(git rev-list --count @{upstream}..HEAD 2>/dev/null || echo 0)
    BEHIND=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)
    [ "$BEHIND" -gt 0 ] 2>/dev/null && GIT_INDICATORS+=" ⇣${BEHIND}"
    [ "$AHEAD" -gt 0 ] 2>/dev/null && GIT_INDICATORS+=" ⇡${AHEAD}"
    [ "$STAGED" -gt 0 ] 2>/dev/null && GIT_INDICATORS+=" +${STAGED}"
    [ "$UNSTAGED" -gt 0 ] 2>/dev/null && GIT_INDICATORS+=" !${UNSTAGED}"
    [ "$UNTRACKED" -gt 0 ] 2>/dev/null && GIT_INDICATORS+=" ?${UNTRACKED}"
    GIT_PLAIN=" ⎇ ${BRANCH}${GIT_INDICATORS}"
    GIT_PART=" ${GREEN}⎇ ${BRANCH}${YELLOW}${GIT_INDICATORS}${RESET}"
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
TERM_WIDTH=${COLUMNS:-120}
if command -v mode.com >/dev/null 2>&1; then
  MODE_WIDTH=$(mode.com con 2>/dev/null | grep -i "columns" | tr -dc '0-9')
  [ -n "$MODE_WIDTH" ] && [ "$MODE_WIDTH" -gt 0 ] && TERM_WIDTH=$MODE_WIDTH
fi
# Safety margin for wide unicode chars
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
