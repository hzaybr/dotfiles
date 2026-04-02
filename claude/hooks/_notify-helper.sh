#!/bin/bash
# Shared helper for notification hooks.
# Provides foreground detection, Ghostty tab matching, and notification sending.
# Source this file — do not execute directly.

HS="/opt/homebrew/bin/hs"

# Get the frontmost application name (with 3s timeout)
get_front_app() {
	perl -e 'alarm 3; exec @ARGV' -- osascript -e \
		'tell application "System Events" to get name of first process whose frontmost is true' 2>/dev/null
}

# Get current Ghostty window info via Hammerspoon ("windowId:tabIndex")
get_ghostty_info() {
	[ -x "$HS" ] || return 1
	perl -e 'alarm 3; exec @ARGV' -- "$HS" -c 'return getGhosttyWindowInfo()' \
		2>/dev/null | grep -E '^[0-9]+:[0-9]+$'
}

# Check if a Ghostty window ID still exists
ghostty_window_exists() {
	local window_id="$1"
	[ -x "$HS" ] || return 1
	local result
	result=$(perl -e 'alarm 3; exec @ARGV' -- "$HS" -c \
		"return hs.window.get($window_id) and 'yes' or 'no'" 2>/dev/null)
	[ "$result" = "yes" ]
}

# Check if user is watching this session's tab.
# Returns 0 (true) if user is on this tab or if we can't determine, 1 if on a different tab.
# Usage: is_user_on_tab "$SESSION_FILE" "$FRONT_APP" [save_on_match]
#   save_on_match: if "save", writes current info to SESSION_FILE when matched (for post hooks)
is_user_on_tab() {
	local session_file="$1"
	local front_app="$2"
	local save_on_match="${3:-}"

	case "$front_app" in
	Ghostty | ghostty)
		local session_id
		session_id=$(basename "$session_file" | sed 's/^[a-z]*-ghostty-//')
		if [ -n "$session_id" ] && [ -x "$HS" ]; then
			local current_info saved_info
			current_info=$(get_ghostty_info)
			saved_info=""
			[ -f "$session_file" ] && saved_info=$(cat "$session_file")

			local saved_window_id="${saved_info%%:*}"

			# Treat stale window ID as first-time
			local saved_valid=true
			if [ -n "$saved_window_id" ] && [ -n "$current_info" ]; then
				local current_window_id="${current_info%%:*}"
				if [ "$saved_window_id" != "$current_window_id" ]; then
					ghostty_window_exists "$saved_window_id" || saved_valid=false
				fi
			fi

			# Exact match — user is on this tab
			if [ -n "$saved_info" ] && [ "$saved_valid" = "true" ] && [ "$current_info" = "$saved_info" ]; then
				return 0
			fi

			# First time or stale window — save current info if requested, assume watching
			if [ -z "$saved_info" ] || [ "$saved_valid" = "false" ]; then
				if [ "$save_on_match" = "save" ] && [ -n "$current_info" ]; then
					echo "$current_info" >"$session_file"
				fi
				# "save" callers (post hooks) treat first-time as watching
				# non-save callers (notification hooks) should notify
				[ "$save_on_match" = "save" ] && return 0
				return 1
			fi
			# User is on a different tab
			return 1
		fi
		# No session ID or no Hammerspoon — assume watching
		return 0
		;;
	Terminal | iTerm2 | WezTerm | Alacritty | kitty)
		return 0
		;;
	*)
		# Not a terminal — user is away
		return 1
		;;
	esac
}

# Refresh stale window ID in session file before sending notification
refresh_session_window() {
	local session_file="$1"
	[ -x "$HS" ] && [ -f "$session_file" ] || return
	local saved_info saved_window_id saved_tab
	saved_info=$(cat "$session_file")
	saved_window_id="${saved_info%%:*}"
	saved_tab="${saved_info##*:}"
	[ -n "$saved_window_id" ] || return
	if ! ghostty_window_exists "$saved_window_id"; then
		local new_window_id
		new_window_id=$(perl -e 'alarm 3; exec @ARGV' -- "$HS" -c '
			local app = hs.application.find("Ghostty")
			if app then
				local win = app:mainWindow()
				if win then return tostring(win:id()) end
			end
			return ""
		' 2>/dev/null)
		if [ -n "$new_window_id" ]; then
			echo "${new_window_id}:${saved_tab}" >"$session_file"
		fi
	fi
}

# Send a macOS notification.
# Usage: send_notification "$title" "$subtitle" "$message" "$sound" "$group" "$focus_script"
send_notification() {
	local title="$1" subtitle="$2" message="$3" sound="$4" group="$5" focus_script="$6"

	if command -v terminal-notifier &>/dev/null; then
		local args=(
			-title "$title"
			-subtitle "$subtitle"
			-message "$message"
			-group "$group"
		)
		[ -n "$sound" ] && args+=(-sound "$sound")
		[ -n "$focus_script" ] && args+=(-execute "$focus_script")
		terminal-notifier "${args[@]}" 2>/dev/null &
	else
		perl -e 'alarm 3; exec @ARGV' -- osascript - "$subtitle" "$message" "$title" "${sound:-}" <<'APPLESCRIPT' 2>/dev/null
on run argv
  set sub to item 1 of argv
  set msg to item 2 of argv
  set ttl to item 3 of argv
  set snd to item 4 of argv
  if snd is not "" then
    display notification msg with title ttl subtitle sub sound name snd
  else
    display notification msg with title ttl subtitle sub
  end if
end run
APPLESCRIPT
	fi
}
