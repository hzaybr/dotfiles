-- Enable CLI access (hs -c "...")
require("hs.ipc")

-- Switch to a specific tab in a Ghostty window (1-based, 0 = no switch)
local function switchToTab(win, tabIndex)
	if not tabIndex or tabIndex <= 0 then
		return
	end
	local axWin = hs.axuielement.windowElement(win)
	local tabGroups = axWin:childrenWithRole("AXTabGroup")
	if tabGroups and #tabGroups > 0 then
		local tabs = tabGroups[1]:childrenWithRole("AXRadioButton")
		if tabs and tabs[tabIndex] then
			tabs[tabIndex]:performAction("AXPress")
		end
	end
end

-- Focus a Ghostty window by window ID, optionally switching to a specific tab.
-- tabIndex is 1-based; 0 or nil means don't switch tabs.
function focusGhosttyWindow(windowId, tabIndex)
	local win = hs.window.get(windowId)
	if not win then
		local app = hs.application.find("Ghostty")
		if app then
			app:activate()
		end
		return false
	end

	local currentSpace = hs.spaces.focusedSpace()
	local winSpaces = hs.spaces.windowSpaces(win)
	local needsSpaceSwitch = winSpaces and #winSpaces > 0 and winSpaces[1] ~= currentSpace

	if needsSpaceSwitch then
		-- Move window to target space, go there, then raise it
		-- (win:focus() pulls the window to current space, so avoid it)
		local targetSpace = winSpaces[1]
		hs.spaces.gotoSpace(targetSpace)
		hs.timer.doAfter(0.3, function()
			win:application():activate()
			win:raise()
			switchToTab(win, tabIndex)
		end)
	else
		win:focus()
		switchToTab(win, tabIndex)
	end
	return true
end

-- Focus Ghostty and switch to a specific tab index (1-based).
-- Used by notification click handlers when window ID may have changed.
function focusGhosttyTab(tabIndex)
	local app = hs.application.find("Ghostty")
	if not app then
		return false
	end
	app:activate()
	local win = app:focusedWindow()
	if not win then
		return false
	end

	switchToTab(win, tabIndex)
	return true
end

-- Called via `hs -c` from hooks/focus-ghostty-window.sh
-- Returns current tab info for saving: "windowId:tabIndex"
function getGhosttyWindowInfo()
	local app = hs.application.find("Ghostty")
	if not app then
		return ""
	end
	local win = app:focusedWindow()
	if not win then
		return ""
	end

	local winId = win:id()
	local tabIndex = 0
	local axWin = hs.axuielement.windowElement(win)
	local tabGroups = axWin:childrenWithRole("AXTabGroup")
	if tabGroups and #tabGroups > 0 then
		local tabs = tabGroups[1]:childrenWithRole("AXRadioButton")
		if tabs then
			for i, tab in ipairs(tabs) do
				if tab:attributeValue("AXValue") then
					tabIndex = i
					break
				end
			end
		end
	end
	return tostring(winId) .. ":" .. tostring(tabIndex)
end
