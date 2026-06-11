#!/bin/bash

# Bash port of statusline.sh for Git Bash / WSL on Windows. Layout, ordering
# and width calculation are kept in sync with the zsh original; only the
# escape sequences and shell builtins differ.

# Force UTF-8 so ${#var} returns code-unit counts (not bytes). On Git Bash
# the MSYS2 wchar_t is 16-bit, so supplementary-plane Nerd Font icons count
# as 2 code units — which conveniently matches their on-screen cell width.
export LC_ALL=C.UTF-8

input=$(cat)

# Claude Code captures stdout (it is a pipe, not a TTY), so `tput cols` cannot
# read the real width. Claude sets COLUMNS to the terminal width (v2.1.153+);
# fall back to mode.com on Windows, then 80, for older versions or
# early-startup renders.
COLUMNS_RAW=${COLUMNS:-}
TERM_WIDTH=${COLUMNS:-0}
WIDTH_SRC="COLUMNS"
if [ "$TERM_WIDTH" -lt 1 ] && command -v mode.com >/dev/null 2>&1; then
  MODE_WIDTH=$(mode.com con 2>/dev/null | grep -i "columns" | tr -dc '0-9')
  if [ -n "$MODE_WIDTH" ]; then
    TERM_WIDTH=$MODE_WIDTH
    WIDTH_SRC="mode.com"
  fi
fi
if [ "$TERM_WIDTH" -lt 1 ]; then
  TERM_WIDTH=80
  WIDTH_SRC="fallback80"
fi

# Diagnostic: set STATUSLINE_DEBUG=1 to log what width was picked up. Each run
# appends one line, so tail the file after a few renders.
if [ -n "$STATUSLINE_DEBUG" ]; then
  {
    printf '[%s] src=%s COLUMNS=%q LINES=%q TERM_WIDTH=%s TERM=%q\n' \
      "$(date +%H:%M:%S)" "$WIDTH_SRC" "$COLUMNS_RAW" "${LINES:-}" "$TERM_WIDTH" "${TERM:-}"
  } >>"$HOME/.claude/statusline-debug.log" 2>/dev/null
fi

MODEL_DISPLAY=$(echo "$input" | jq -r '.model.display_name // .model.id')
MODEL_DISPLAY=${MODEL_DISPLAY%%" ("*}  # drop trailing parenthetical, e.g. " (1M context)"
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir')
CONTEXT_REMAINING=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Git Bash reports /c/Users/<user>/...; the second sed is a fallback for the
# rare case where $HOME is not a prefix (junction, alternate mount, etc).
SHORT_DIR=$(echo "$CURRENT_DIR" | sed "s|^$HOME|~|" | sed 's|^/c/Users/|~/|;s|^\(~/[^/]*\)/|\1/|')

HOST_NAME_RAW=$(hostname -s 2>/dev/null || hostname)
HOST_NAME=$(echo "$HOST_NAME_RAW" | tr '[:lower:]' '[:upper:]')
HOST_ICON_NAME="󰣙 ${HOST_NAME}"

# ANSI colors (use real ESC bytes so printf %s keeps them intact).
RESET=$'\033[0m'
BOLD=$'\033[1m'
WHITE=$'\033[97m'
BLUE=$'\033[34m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
ESC=$'\033'

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
    GIT_PART=" ${GREEN}󰘬 ${BRANCH}${YELLOW}${GIT_INDICATORS}${RESET}"
  fi
fi

# Context window remaining
CONTEXT_PART=""
if [ -n "$CONTEXT_REMAINING" ]; then
  if [ "$CONTEXT_REMAINING" -gt 70 ]; then
    CTX_COLOR=$GREEN
    CTX_ICON="󰆼"
  elif [ "$CONTEXT_REMAINING" -gt 40 ]; then
    CTX_COLOR=$YELLOW
    CTX_ICON="󱘺"
  else
    CTX_COLOR=$RED
    CTX_ICON="󱘺"
  fi
  CONTEXT_PART="|${CTX_COLOR} ${CTX_ICON} ${CONTEXT_REMAINING}%${RESET}"
fi

RIGHT_COLORED="${MODEL_DISPLAY}${CONTEXT_PART:+ ${CONTEXT_PART}}"

# Visible width of a string: strip ANSI escape sequences and return the code-
# unit count. With LC_ALL=C.UTF-8 on Git Bash, BMP characters count as 1 and
# supplementary-plane Nerd Font icons count as 2 — which matches their
# two-cell rendering, so no per-icon adjustment is needed.
visible_length() {
  local s="$1"
  local stripped
  stripped=$(printf '%s' "$s" | sed -E "s/${ESC}\[[0-9;]*[a-zA-Z]//g")
  echo "${#stripped}"
}

# Hide the hostname on machines that export STATUSLINE_HIDE_HOST=1 (set it
# per-machine via shell or ~/.claude/settings.local.json, not the public repo).
case "$STATUSLINE_HIDE_HOST" in
  1|true|yes)
    HOST_PART=""
    ;;
  *)
    HOST_PART="${WHITE}${BOLD}${HOST_ICON_NAME}${RESET} "
    ;;
esac

RIGHT_LEN=$(visible_length "$RIGHT_COLORED")

# Truncate the directory (keeping its tail) when the whole line would not fit.
# Reserve 1 trailing column so the terminal never wraps on the final cell.
HOST_LEN=$(visible_length "$HOST_PART")
GIT_LEN=$(visible_length "$GIT_PART")
FIXED_LEN=$((HOST_LEN + GIT_LEN))
DIR_BUDGET=$((TERM_WIDTH - 3 - RIGHT_LEN - FIXED_LEN))
if (( ${#SHORT_DIR} > DIR_BUDGET )); then
  if (( DIR_BUDGET > 1 )); then
    TAIL=$((DIR_BUDGET - 1))
    SHORT_DIR="…${SHORT_DIR: -TAIL}"
  else
    SHORT_DIR="…"
  fi
fi

LEFT_COLORED="${HOST_PART}${BLUE}${SHORT_DIR}${RESET}${GIT_PART}"
LEFT_LEN=$(visible_length "$LEFT_COLORED")

SPACING=$((TERM_WIDTH - 2 - LEFT_LEN - RIGHT_LEN))
(( SPACING < 1 )) && SPACING=1

printf '%s%*s%s' "$LEFT_COLORED" "$SPACING" "" "$RIGHT_COLORED"
