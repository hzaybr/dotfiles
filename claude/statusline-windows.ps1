# PowerShell port of statusline-windows.sh for native Windows sessions.
#
# Claude Code on native Windows runs the statusLine `command` through
# PowerShell, which cannot execute the bash `.sh` script (it produces empty
# output, so no status line renders). This port keeps the same layout,
# ordering and width math as the bash/zsh originals; only the host primitives
# differ. PS 5.1 compatible (no ternary / null-coalescing operators).

$ErrorActionPreference = 'SilentlyContinue'

# Read the JSON Claude pipes to stdin.
$raw = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($raw)) { return }
$data = $raw | ConvertFrom-Json

# Emit UTF-8 so supplementary-plane Nerd Font icons survive to the terminal.
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

# Claude sets COLUMNS to the terminal width (v2.1.153+). Fall back to mode.com,
# then 80, for older versions or early-startup renders.
$termWidth = 0
if ($env:COLUMNS -and [int]::TryParse($env:COLUMNS, [ref]$termWidth)) { } else { $termWidth = 0 }
if ($termWidth -lt 1) {
    $modeOut = & "$env:WINDIR\System32\mode.com" con 2>$null | Out-String
    $m = [regex]::Match($modeOut, '(?im)columns\D*(\d+)')
    if ($m.Success) { $termWidth = [int]$m.Groups[1].Value }
}
if ($termWidth -lt 1) { $termWidth = 80 }

# Diagnostic: set STATUSLINE_DEBUG=1 to log the width source.
if ($env:STATUSLINE_DEBUG) {
    $line = "[{0}] src=PS COLUMNS={1} TERM_WIDTH={2}" -f (Get-Date -Format 'HH:mm:ss'), $env:COLUMNS, $termWidth
    Add-Content -LiteralPath "$HOME\.claude\statusline-debug.log" -Value $line -ErrorAction SilentlyContinue
}

$modelDisplay = $data.model.display_name
if (-not $modelDisplay) { $modelDisplay = $data.model.id }
$modelDisplay = ($modelDisplay -replace '\s*\(.*$', '')  # drop trailing parenthetical
$currentDir = $data.workspace.current_dir
$ctxRemaining = $data.context_window.remaining_percentage

# Shorten the directory: collapse the home prefix to ~ (handle / and \ forms).
$shortDir = $currentDir
$homeFwd = $HOME -replace '\\', '/'
$dirFwd = $currentDir -replace '\\', '/'
if ($dirFwd -like "$homeFwd*") {
    $shortDir = '~' + $dirFwd.Substring($homeFwd.Length)
} else {
    $shortDir = $dirFwd
}

# Nerd Font glyphs live in the supplementary plane (> U+FFFF), so they must be
# built with ConvertFromUtf32 (a [char] cast only holds 16 bits and throws).
$ICON_HOST = [char]::ConvertFromUtf32(0xF08D9)
$ICON_BRANCH = [char]::ConvertFromUtf32(0xF062C)
$ICON_CTX_OK = [char]::ConvertFromUtf32(0xF01BC)
$ICON_CTX_LOW = [char]::ConvertFromUtf32(0xF163A)

$hostName = $env:COMPUTERNAME.ToUpper()
$hostIconName = "$ICON_HOST $hostName"

# ANSI colors (real ESC byte so the width stripper can find them).
$ESC = [char]27
$RESET = "$ESC[0m"; $BOLD = "$ESC[1m"; $WHITE = "$ESC[97m"
$BLUE = "$ESC[34m"; $GREEN = "$ESC[32m"; $YELLOW = "$ESC[33m"; $RED = "$ESC[31m"

# Locate git: not always on PATH on Windows (Git Bash carries its own). Check
# known install paths first — Get-Command scans all of PATH and is slow when
# git is absent from it.
$gitExe = $null
foreach ($c in @(
    "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe",
    "$env:ProgramFiles\Git\cmd\git.exe",
    "${env:ProgramFiles(x86)}\Git\cmd\git.exe")) {
    if (Test-Path $c) { $gitExe = $c; break }
}
if (-not $gitExe) { $gitExe = (Get-Command git -ErrorAction SilentlyContinue).Source }

# Git info from a single `status --porcelain --branch` call (one process spawn
# instead of six). The porcelain XY field gives staged (X) / unstaged (Y), the
# branch header gives the name and ahead/behind counts.
$gitPart = ''
if ($gitExe -and (Test-Path $currentDir)) {
    $status = @(& $gitExe -C $currentDir status --porcelain=v1 --branch --untracked-files=all 2>$null)
    $branch = ''; $ahead = 0; $behind = 0; $staged = 0; $unstaged = 0; $untracked = 0
    foreach ($line in $status) {
        if ($line.StartsWith('## ')) {
            $head = $line.Substring(3)
            if ($head -notmatch '\(no branch\)') {
                $branch = ($head -split '\.\.\.')[0]
                $am = [regex]::Match($line, 'ahead (\d+)'); if ($am.Success) { $ahead = [int]$am.Groups[1].Value }
                $bm = [regex]::Match($line, 'behind (\d+)'); if ($bm.Success) { $behind = [int]$bm.Groups[1].Value }
            }
        } elseif ($line.StartsWith('??')) {
            $untracked++
        } elseif ($line.Length -ge 2) {
            if ($line[0] -ne ' ') { $staged++ }
            if ($line[1] -ne ' ') { $unstaged++ }
        }
    }
    if ($branch) {
        $indicators = ''
        if ($behind -gt 0) { $indicators += " $([char]0x21E3)$behind" }
        if ($ahead -gt 0) { $indicators += " $([char]0x21E1)$ahead" }
        if ($staged -gt 0) { $indicators += " +$staged" }
        if ($unstaged -gt 0) { $indicators += " !$unstaged" }
        if ($untracked -gt 0) { $indicators += " ?$untracked" }
        $gitPart = " $GREEN$ICON_BRANCH $branch$YELLOW$indicators$RESET"
    }
}

# Context window remaining.
$contextPart = ''
if ($ctxRemaining -ne $null -and "$ctxRemaining" -ne '') {
    $pct = [int]$ctxRemaining
    if ($pct -gt 70) { $ctxColor = $GREEN; $ctxIcon = $ICON_CTX_OK }
    elseif ($pct -gt 40) { $ctxColor = $YELLOW; $ctxIcon = $ICON_CTX_LOW }
    else { $ctxColor = $RED; $ctxIcon = $ICON_CTX_LOW }
    $contextPart = "|$ctxColor $ctxIcon $pct%$RESET"
}

$rightColored = $modelDisplay
if ($contextPart) { $rightColored = "$modelDisplay $contextPart" }

# Visible width: strip ANSI, then count UTF-16 code units. Supplementary-plane
# Nerd Font icons are surrogate pairs (length 2), which matches their two-cell
# render width, so no per-icon adjustment is needed.
function Get-VisibleLength([string]$s) {
    $stripped = [regex]::Replace($s, "$ESC\[[0-9;]*[a-zA-Z]", '')
    return $stripped.Length
}

# Hide the hostname on machines that export STATUSLINE_HIDE_HOST=1.
$hostPart = "$WHITE$BOLD$hostIconName$RESET "
if ($env:STATUSLINE_HIDE_HOST -in @('1', 'true', 'yes')) { $hostPart = '' }

$rightLen = Get-VisibleLength $rightColored

# Truncate the directory tail when the whole line would not fit. Reserve 1
# trailing column so the terminal never wraps on the final cell.
$hostLen = Get-VisibleLength $hostPart
$gitLen = Get-VisibleLength $gitPart
$fixedLen = $hostLen + $gitLen
$dirBudget = $termWidth - 3 - $rightLen - $fixedLen
if ($shortDir.Length -gt $dirBudget) {
    $ellipsis = [char]0x2026
    if ($dirBudget -gt 1) {
        $tail = $dirBudget - 1
        $shortDir = $ellipsis + $shortDir.Substring($shortDir.Length - $tail)
    } else {
        $shortDir = "$ellipsis"
    }
}

$leftColored = "$hostPart$BLUE$shortDir$RESET$gitPart"
$leftLen = Get-VisibleLength $leftColored

$spacing = $termWidth - 2 - $leftLen - $rightLen
if ($spacing -lt 1) { $spacing = 1 }

[Console]::Out.Write($leftColored + (' ' * $spacing) + $rightColored)
