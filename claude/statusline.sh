#!/bin/zsh
input=$(cat)

MODEL_DISPLAY=$(echo "$input" | jq -r '.model.id')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir')
CONTEXT_REMAINING=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

SHORT_DIR=$(echo "$CURRENT_DIR" | sed "s|^$HOME|~|")
LEFT_PLAIN="%F{blue}󰣙 ${SHORT_DIR}%f"
USER_HOST="$(whoami)@$(hostname -s)"

# Git info
GIT_PART=""
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
    GIT_PART=" %F{green}󰘬 ${BRANCH}%F{yellow}${GIT_INDICATORS}%f"
  fi
fi

# Right side: model + context
if [ -n "$CONTEXT_REMAINING" ]; then
  if [ "$CONTEXT_REMAINING" -gt 50 ]; then
    CTX_COLOR="green"
    CTX_ICON="󰆼"
  elif [ "$CONTEXT_REMAINING" -gt 20 ]; then
    CTX_COLOR="yellow"
    CTX_ICON="󱘺"
  else
    CTX_COLOR="red"
  fi
  CONTEXT_REMAINING="%F{${CTX_COLOR}} ${CTX_ICON} ${CONTEXT_REMAINING}%%%f"
fi
RIGHT_PLAIN="${MODEL_DISPLAY} | ${CONTEXT_REMAINING}"

print -P -- "${LEFT_PLAIN}${GIT_PART} | ${RIGHT_PLAIN}"
