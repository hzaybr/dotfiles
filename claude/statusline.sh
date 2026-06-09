#!/bin/zsh

# Basic info 
input=$(cat)
# Claude Code captures stdout (it is a pipe, not a TTY), so `tput cols` cannot
# read the real width. Claude sets COLUMNS to the terminal width (v2.1.153+);
# fall back to tput, then 80, for older versions or early-startup renders.
TERM_WIDTH=${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}

MODEL_DISPLAY=$(echo "$input" | jq -r '.model.display_name // .model.id')
MODEL_DISPLAY=${MODEL_DISPLAY%%" ("*}  # drop trailing parenthetical, e.g. " (1M context)"
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir')
CONTEXT_REMAINING=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
SHORT_DIR=$(echo "$CURRENT_DIR" | sed "s|^$HOME|~|")
HOST_NAME="󰣙 $(hostname -s)"

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

# Context window remaining
if [ -n "$CONTEXT_REMAINING" ]; then
  if [ "$CONTEXT_REMAINING" -gt 70 ]; then
    CTX_COLOR="green"
    CTX_ICON="󰆼"
  elif [ "$CONTEXT_REMAINING" -gt 40 ]; then
    CTX_COLOR="yellow"
    CTX_ICON="󱘺"
  else
    CTX_COLOR="red"
    CTX_ICON="󱘺"
  fi
  CONTEXT_REMAINING="|%F{${CTX_COLOR}} ${CTX_ICON} ${CONTEXT_REMAINING}%%%f"
fi

RIGHT_PLAIN="${MODEL_DISPLAY}${CONTEXT_REMAINING:+ ${CONTEXT_REMAINING}}"

# Visible width of a prompt string: expand prompt escapes, strip ANSI codes,
# then add 1 column per Nerd Font icon (they render two cells wide).
visible_length() {
  emulate -L zsh
  setopt extendedglob
  local stripped=${${(%)1}//$'\e'\[[0-9;]##[a-zA-Z]/}
  local base=${#stripped}
  local no_icons=${stripped//[󰣙󰘬󰆼󱘺]/}
  local extra=$((base - ${#no_icons}))
  print -r -- $((base + extra))
}

RIGHT_LEN=$(visible_length "$RIGHT_PLAIN")

# Hide the hostname on machines that export STATUSLINE_HIDE_HOST=1 (set it
# per-machine via shell or ~/.claude/settings.local.json, not the public repo).
# The trailing space lives inside HOST_PART so it vanishes too when hidden.
if [[ $STATUSLINE_HIDE_HOST == (1|true|yes) ]]; then
  HOST_PART=""
else
  HOST_PART="%F{15}%B${HOST_NAME:u}%f%b "
fi

# Truncate the directory (keeping its tail) when the whole line would not fit.
# Reserve 1 trailing column so the terminal never wraps on the final cell.
FIXED_LEN=$(( $(visible_length "$HOST_PART") + $(visible_length "$GIT_PART") ))
DIR_BUDGET=$((TERM_WIDTH - 2 - RIGHT_LEN - FIXED_LEN))
if (( ${#SHORT_DIR} > DIR_BUDGET )); then
  if (( DIR_BUDGET > 1 )); then
    TAIL=$((DIR_BUDGET - 1))
    SHORT_DIR="…${SHORT_DIR[-TAIL,-1]}"
  else
    SHORT_DIR="…"
  fi
fi

LEFT_PLAIN="${HOST_PART}%F{blue}${SHORT_DIR}%f${GIT_PART}"
LEFT_LEN=$(visible_length "$LEFT_PLAIN")

SPACING=$((TERM_WIDTH - 1 - LEFT_LEN - RIGHT_LEN))
(( SPACING < 1 )) && SPACING=1

STATUS_LINE="${LEFT_PLAIN}$(printf '%*s' $SPACING)${RIGHT_PLAIN}"
print -P -- "${STATUS_LINE}"
