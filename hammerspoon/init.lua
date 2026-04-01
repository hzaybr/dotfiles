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

-- Focus a window, handling space switching
local function focusWindow(win, tabIndex)
	local currentSpace = hs.spaces.focusedSpace()
	local winSpaces = hs.spaces.windowSpaces(win)
	local needsSpaceSwitch = winSpaces and #winSpaces > 0 and winSpaces[1] ~= currentSpace

	if needsSpaceSwitch then
		hs.spaces.gotoSpace(winSpaces[1])
		hs.timer.doAfter(0.3, function()
			win:application():activate()
			win:raise()
			switchToTab(win, tabIndex)
		end)
	else
		win:focus()
		switchToTab(win, tabIndex)
	end
end

-- Find a Ghostty window that has at least N tabs
local function findGhosttyWindowWithTab(tabIndex)
	local app = hs.application.find("Ghostty")
	if not app then
		return nil
	end
	for _, win in ipairs(app:allWindows()) do
		local axWin = hs.axuielement.windowElement(win)
		local tabGroups = axWin:childrenWithRole("AXTabGroup")
		if tabGroups and #tabGroups > 0 then
			local tabs = tabGroups[1]:childrenWithRole("AXRadioButton")
			if tabs and tabs[tabIndex] then
				return win
			end
		end
	end
	return nil
end

-- Focus a Ghostty window by window ID, optionally switching to a specific tab.
-- tabIndex is 1-based; 0 or nil means don't switch tabs.
function focusGhosttyWindow(windowId, tabIndex)
	-- Try exact window ID first
	local win = hs.window.get(windowId)
	if win then
		focusWindow(win, tabIndex)
		return true
	end

	-- Window ID stale — search all Ghostty windows for one with the right tab
	if tabIndex and tabIndex > 0 then
		win = findGhosttyWindowWithTab(tabIndex)
		if win then
			focusWindow(win, tabIndex)
			return true
		end
	end

	-- Last resort: just activate Ghostty
	local app = hs.application.find("Ghostty")
	if app then
		app:activate()
	end
	return false
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
-- Uses mainWindow to avoid capturing transient/secondary windows
function getGhosttyWindowInfo()
	local app = hs.application.find("Ghostty")
	if not app then
		return ""
	end
	local win = app:mainWindow() or app:focusedWindow()
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
