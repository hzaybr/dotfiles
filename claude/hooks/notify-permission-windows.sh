#!/bin/bash
# Notification hook: Windows toast notification when Claude needs permission approval
# Only notifies when the terminal is NOT in the foreground.

INPUT=$(cat)

# Use PowerShell to check if terminal is foreground and send toast
powershell.exe -NoProfile -Command '
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class ForegroundWindow {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
}
"@
$hwnd = [ForegroundWindow]::GetForegroundWindow()
$pid = 0
[ForegroundWindow]::GetWindowThreadProcessId($hwnd, [ref]$pid) | Out-Null
$proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
$terminals = @("WindowsTerminal","wezterm-gui","alacritty","kitty","ghostty","cmd","powershell","pwsh")
if ($proc -and $terminals -contains $proc.ProcessName) { exit 0 }
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime] | Out-Null
$xml = [Windows.Data.Xml.Dom.XmlDocument]::new()
$xml.LoadXml("<toast><visual><binding template=\"ToastGeneric\"><text>Claude Code</text><text>Permission approval needed</text></binding></visual><audio src=\"ms-winsoundevent:Notification.Default\"/></toast>")
$toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Claude Code").Show($toast)
' 2>/dev/null

echo "$INPUT"
