# Dotfiles installation script for Windows
# Default mode copies files from the dotfiles repo into the user home; pass
# -Symlink to use symbolic links instead (requires Administrator or Developer
# Mode). Re-run after updating dotfiles in copy mode.

#Requires -Version 5.1

param(
    [switch]$Force,
    [switch]$Symlink  # Opt in to symlinks; default is copy + remove for parity with .sh
)

$ErrorActionPreference = "Stop"

$DotfilesDir = $PSScriptRoot
$BackupDir = Join-Path $env:USERPROFILE ".dotfiles_backup\$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$BackupCreated = $false

# Colors
function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Green }
function Write-Warn { Write-Host "[WARN] $args" -ForegroundColor Yellow }
function Write-Err { Write-Host "[ERROR] $args" -ForegroundColor Red }

function Test-SymlinkSupport {
    $testPath = Join-Path $env:TEMP "symlink_test_$(Get-Random)"
    $testTarget = Join-Path $env:TEMP "symlink_target_$(Get-Random)"

    try {
        New-Item -ItemType Directory -Path $testTarget -Force | Out-Null
        New-Item -ItemType SymbolicLink -Path $testPath -Target $testTarget -ErrorAction Stop | Out-Null
        Remove-Item $testPath -Force
        Remove-Item $testTarget -Force
        return $true
    } catch {
        if (Test-Path $testTarget) { Remove-Item $testTarget -Force -ErrorAction SilentlyContinue }
        return $false
    }
}

# Symlink-aware filesystem helpers. GetAttributes works even on broken
# reparse points, so these stay correct when a link's target is gone.
function Test-IsSymlink {
    param([string]$Path)
    try {
        $attr = [System.IO.File]::GetAttributes($Path)
        return ($attr -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
    } catch {
        return $false
    }
}

function Test-PathOrLink {
    param([string]$Path)
    return (Test-Path -LiteralPath $Path) -or (Test-IsSymlink -Path $Path)
}

# Delete a symlink/junction without recursing into (or removing) its target.
function Remove-Symlink {
    param([string]$Path)
    $attr = [System.IO.File]::GetAttributes($Path)
    if (($attr -band [System.IO.FileAttributes]::Directory) -ne 0) {
        [System.IO.Directory]::Delete($Path, $false)
    } else {
        [System.IO.File]::Delete($Path)
    }
}

function Backup-Existing {
    param([string]$Destination)
    if (-not $script:BackupCreated) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
        $script:BackupCreated = $true
    }
    Write-Warn "Backing up existing $Destination to $BackupDir\"
    $backupName = Split-Path $Destination -Leaf
    Move-Item -LiteralPath $Destination -Destination (Join-Path $BackupDir $backupName) -Force
}

function Backup-AndLink {
    param(
        [string]$Source,
        [string]$Destination,
        [switch]$IsDirectory
    )

    if (Test-PathOrLink $Destination) {
        if (Test-IsSymlink $Destination) {
            # Stale link from a previous run; drop without backup.
            Remove-Symlink $Destination
        } elseif ($script:UseCopy) {
            # We own the destination in copy mode; overwrite without piling
            # up backups every run. Matches install.sh's clobber-on-relink.
            Remove-Item -LiteralPath $Destination -Recurse -Force
        } else {
            Backup-Existing $Destination
        }
    }

    $parentDir = Split-Path $Destination -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    if ($script:UseCopy) {
        if ($IsDirectory) {
            Copy-Item -Path $Source -Destination $Destination -Recurse -Force
        } else {
            Copy-Item -Path $Source -Destination $Destination -Force
        }
        Write-Info "Copied $Source -> $Destination"
    } else {
        New-Item -ItemType SymbolicLink -Path $Destination -Target $Source | Out-Null
        Write-Info "Linked $Destination -> $Source"
    }
}

# Copy (never symlink) so downstream mutation never touches the repo source.
function Backup-AndCopy {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (Test-PathOrLink $Destination) {
        if (Test-IsSymlink $Destination) {
            Remove-Symlink $Destination
        } else {
            Backup-Existing $Destination
        }
    }

    $parentDir = Split-Path $Destination -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    Copy-Item -LiteralPath $Source -Destination $Destination -Force
    Write-Info "Copied $Source -> $Destination"
}

# UTF-8 (no BOM) writers; PS 5.1 Set-Content -Encoding utf8 emits a BOM
# that breaks some JSON/TOML parsers.
function Write-Utf8Text {
    param([string]$Path, [string]$Text)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

function Write-Utf8Lines {
    param([string]$Path, [string[]]$Lines)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($Path, $Lines, $enc)
}

# JSON-encode a scalar/array the way `jq @json` does (used for TOML emission).
function ConvertTo-JsonString {
    param([string]$Value)
    return ($Value | ConvertTo-Json -Compress)
}

function ConvertTo-JsonArray {
    param([object[]]$Values)
    $items = @($Values | ForEach-Object { $_ | ConvertTo-Json -Compress })
    return '[' + ($items -join ',') + ']'
}

# Replace a "$VAR" / "${VAR}" placeholder with its env value.
# Returns @{ Keep = $bool; Value = <resolved> }; Keep=$false means drop the key.
function Resolve-McpValue {
    param($Value)
    if ($Value -is [string] -and $Value -match '^\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?$') {
        $name = $Matches[1]
        $envVal = [Environment]::GetEnvironmentVariable($name)
        if ([string]::IsNullOrEmpty($envVal)) {
            return @{ Keep = $false; Value = $null }
        }
        return @{ Keep = $true; Value = $envVal }
    }
    return @{ Keep = $true; Value = $Value }
}

function Get-McpServers {
    param([string]$SourcePath)
    $json = Get-Content -LiteralPath $SourcePath -Raw | ConvertFrom-Json
    if ($json.PSObject.Properties.Name -contains 'mcpServers') {
        return $json.mcpServers
    }
    return $json
}

# Resolve mcp-servers.json into concrete {command,args,env} per server for a
# given target. <target>Args (e.g. codexArgs) fully overrides the base args.
function Resolve-McpSource {
    param([string]$SourcePath, [string]$Target)
    $servers = Get-McpServers $SourcePath
    $overrideKey = "${Target}Args"
    $result = [ordered]@{}

    foreach ($prop in $servers.PSObject.Properties) {
        $srv = $prop.Value

        # Remote (http/sse) servers have no command; preserve their fields as-is.
        if (-not (($srv.PSObject.Properties.Name -contains 'command') -and $null -ne $srv.command)) {
            $entry = [ordered]@{}
            foreach ($p in $srv.PSObject.Properties) {
                if ($p.Name -eq $overrideKey) { continue }
                $entry[$p.Name] = $p.Value
            }
            $result[$prop.Name] = $entry
            continue
        }

        $serverArgs = @()
        if (($srv.PSObject.Properties.Name -contains $overrideKey) -and $null -ne $srv.$overrideKey) {
            $serverArgs = @($srv.$overrideKey)
        } elseif (($srv.PSObject.Properties.Name -contains 'args') -and $null -ne $srv.args) {
            $serverArgs = @($srv.args)
        }

        $env = [ordered]@{}
        if (($srv.PSObject.Properties.Name -contains 'env') -and $srv.env) {
            foreach ($e in $srv.env.PSObject.Properties) {
                $r = Resolve-McpValue $e.Value
                if ($r.Keep) { $env[$e.Name] = $r.Value }
            }
        }

        $result[$prop.Name] = [ordered]@{
            command = $srv.command
            args    = $serverArgs
            env     = $env
        }
    }
    return $result
}

function Write-MissingMcpEnvWarnings {
    param([string]$SourcePath)
    $servers = Get-McpServers $SourcePath
    $missing = [System.Collections.Generic.SortedSet[string]]::new()
    foreach ($prop in $servers.PSObject.Properties) {
        $srv = $prop.Value
        if (($srv.PSObject.Properties.Name -contains 'env') -and $srv.env) {
            foreach ($e in $srv.env.PSObject.Properties) {
                if ($e.Value -is [string] -and $e.Value -match '^\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?$') {
                    $name = $Matches[1]
                    if ([string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable($name))) {
                        [void]$missing.Add($name)
                    }
                }
            }
        }
    }
    foreach ($name in $missing) {
        Write-Warn "MCP env var $name is not set; omitting it during sync"
    }
}

# Replace .mcpServers in ~/.claude.json, preserving every other key.
function Sync-ClaudeMcp {
    param([string]$SourcePath, [string]$DestPath)
    if (-not (Test-Path -LiteralPath $SourcePath)) {
        Write-Warn "MCP source not found at $SourcePath; skipping Claude MCP sync"
        return
    }

    $resolved = Resolve-McpSource -SourcePath $SourcePath -Target 'claude'
    $mcpServers = [ordered]@{}
    foreach ($name in $resolved.Keys) {
        $srv = $resolved[$name]
        if ($srv.Contains('command')) {
            $mcpServers[$name] = [ordered]@{
                command = $srv.command
                args    = @($srv.args)
                env     = $srv.env
            }
        } else {
            # Remote (http/sse) server: pass through type/url/headers.
            $mcpServers[$name] = $srv
        }
    }

    if (Test-Path -LiteralPath $DestPath) {
        $existing = Get-Content -LiteralPath $DestPath -Raw | ConvertFrom-Json
        $existing | Add-Member -NotePropertyName mcpServers -NotePropertyValue $mcpServers -Force
        $out = $existing
    } else {
        $out = [ordered]@{ mcpServers = $mcpServers }
    }

    Write-Utf8Text -Path $DestPath -Text ($out | ConvertTo-Json -Depth 20)
    Write-Info "Synced Claude MCP servers to $DestPath"
}

# Rewrite the dotfiles-managed MCP block in ~/.codex/config.toml in place,
# leaving everything outside the markers untouched.
function Sync-CodexMcp {
    param([string]$SourcePath, [string]$DestPath)
    $beginMarker = "# BEGIN MCP SERVERS (managed by dotfiles)"
    $endMarker = "# END MCP SERVERS (managed by dotfiles)"

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        Write-Warn "MCP source not found at $SourcePath; skipping Codex MCP sync"
        return
    }

    $resolved = Resolve-McpSource -SourcePath $SourcePath -Target 'codex'

    $baseLines = [System.Collections.Generic.List[string]]::new()
    if (Test-Path -LiteralPath $DestPath) {
        $skip = $false
        foreach ($line in (Get-Content -LiteralPath $DestPath)) {
            if ($line -eq $beginMarker) { $skip = $true; continue }
            if ($line -eq $endMarker) { $skip = $false; continue }
            if (-not $skip) { $baseLines.Add($line) }
        }
    }

    $blockLines = [System.Collections.Generic.List[string]]::new()
    foreach ($name in $resolved.Keys) {
        $srv = $resolved[$name]
        if ([string]::IsNullOrEmpty($srv.command)) { continue }
        $blockLines.Add("[mcp_servers.$(ConvertTo-JsonString $name)]")
        $blockLines.Add("command = $(ConvertTo-JsonString $srv.command)")
        if (@($srv.args).Count -gt 0) {
            $blockLines.Add("args = $(ConvertTo-JsonArray @($srv.args))")
        }
        if ($srv.env.Count -gt 0) {
            $pairs = foreach ($k in $srv.env.Keys) {
                "$(ConvertTo-JsonString $k) = $(ConvertTo-JsonString $srv.env[$k])"
            }
            $blockLines.Add("env = { $($pairs -join ', ') }")
        }
        $blockLines.Add("")
    }

    $output = [System.Collections.Generic.List[string]]::new()
    foreach ($l in $baseLines) { $output.Add($l) }
    if ($blockLines.Count -gt 0) {
        if ($output.Count -gt 0) { $output.Add("") }
        $output.Add($beginMarker)
        foreach ($l in $blockLines) { $output.Add($l) }
        $output.Add($endMarker)
    }

    $parent = Split-Path $DestPath -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Write-Utf8Lines -Path $DestPath -Lines $output
    Write-Info "Synced Codex MCP servers to $DestPath"
}

# Remove dest entries whose source counterpart no longer exists.
# Works for both copy and symlink modes (a stale symlink's target won't exist
# either, so the source-side check catches both kinds of drift).
function Remove-OrphanedItems {
    param(
        [string]$DestDir,
        [scriptblock]$SourcePathFromName
    )
    if (-not (Test-Path -LiteralPath $DestDir)) { return }
    Get-ChildItem -LiteralPath $DestDir -Force -ErrorAction SilentlyContinue | ForEach-Object {
        $srcPath = & $SourcePathFromName $_.Name
        if (-not $srcPath) { return }
        if (-not (Test-Path -LiteralPath $srcPath)) {
            if (Test-IsSymlink $_.FullName) {
                Remove-Symlink $_.FullName
            } else {
                Remove-Item -LiteralPath $_.FullName -Recurse -Force
            }
            Write-Info "Removed orphan $($_.FullName)"
        }
    }
}

# Header
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "     Dotfiles Installation Script" -ForegroundColor Cyan
Write-Host "              (Windows)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Default mode is copy + remove (parity with install.sh on machines without
# stable symlinks). Opt in to symlinks with -Symlink.
$script:UseCopy = -not $Symlink
if ($Symlink) {
    if (-not (Test-SymlinkSupport)) {
        Write-Err "-Symlink requested but symbolic links are not available."
        Write-Err "Please either:"
        Write-Err "  1. Run this script as Administrator"
        Write-Err "  2. Enable Developer Mode in Windows Settings"
        Write-Err "  3. Omit -Symlink (default behavior copies files)"
        Write-Host ""
        Write-Host "To enable Developer Mode:" -ForegroundColor Yellow
        Write-Host "  Settings -> Update & Security -> For developers -> Developer Mode" -ForegroundColor Yellow
        exit 1
    }
    Write-Info "Symlink mode enabled."
} else {
    Write-Info "Copy mode (default). Re-run install.ps1 after updating dotfiles."
}

# Git
$gitConfig = Join-Path $DotfilesDir "git\.gitconfig"
if (Test-Path $gitConfig) {
    Backup-AndLink -Source $gitConfig -Destination (Join-Path $env:USERPROFILE ".gitconfig")
}

$gitIgnore = Join-Path $DotfilesDir "git\ignore"
if (Test-Path $gitIgnore) {
    $gitConfigDir = Join-Path $env:USERPROFILE ".config\git"
    Backup-AndLink -Source $gitIgnore -Destination (Join-Path $gitConfigDir "ignore")
}

# GitHub CLI
$ghConfig = Join-Path $DotfilesDir "gh\config.yml"
if (Test-Path $ghConfig) {
    $ghConfigDir = Join-Path $env:APPDATA "GitHub CLI"
    Backup-AndLink -Source $ghConfig -Destination (Join-Path $ghConfigDir "config.yml")
}

# Neovim
$nvimDir = Join-Path $DotfilesDir "nvim"
if (Test-Path $nvimDir) {
    $nvimConfigDir = Join-Path $env:LOCALAPPDATA "nvim"
    Backup-AndLink -Source $nvimDir -Destination $nvimConfigDir -IsDirectory
}

# Windows Terminal (if settings exist)
$wtSettings = Join-Path $DotfilesDir "windows-terminal\settings.json"
if (Test-Path $wtSettings) {
    # Windows Terminal from Microsoft Store
    $wtDir = Get-ChildItem -Path (Join-Path $env:LOCALAPPDATA "Packages") -Filter "Microsoft.WindowsTerminal_*" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($wtDir) {
        $wtSettingsPath = Join-Path $wtDir.FullName "LocalState\settings.json"
        Backup-AndLink -Source $wtSettings -Destination $wtSettingsPath
    }
}

# PowerShell profile
$psProfile = Join-Path $DotfilesDir "powershell\Microsoft.PowerShell_profile.ps1"
if (Test-Path $psProfile) {
    $psProfileDir = Split-Path $PROFILE -Parent
    if (-not (Test-Path $psProfileDir)) {
        New-Item -ItemType Directory -Path $psProfileDir -Force | Out-Null
    }
    Backup-AndLink -Source $psProfile -Destination $PROFILE
}

# Claude Code
$claudeSourceDir = Join-Path $DotfilesDir "claude"
if (Test-Path $claudeSourceDir) {
    $claudeDir = Join-Path $env:USERPROFILE ".claude"

    # Ensure .claude directory exists
    if (-not (Test-Path $claudeDir)) {
        New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
    }

    # CLAUDE.md
    $claudeMd = Join-Path $claudeSourceDir "CLAUDE.md"
    if (Test-Path $claudeMd) {
        Backup-AndLink -Source $claudeMd -Destination (Join-Path $claudeDir "CLAUDE.md")
    }

    # settings.json (use Windows-specific version)
    $claudeSettings = Join-Path $claudeSourceDir "settings.windows.json"
    if (Test-Path $claudeSettings) {
        Backup-AndLink -Source $claudeSettings -Destination (Join-Path $claudeDir "settings.json")
    }

    # rules
    $rulesDir = Join-Path $claudeSourceDir "rules"
    if (Test-Path $rulesDir) {
        $destRulesDir = Join-Path $claudeDir "rules"
        if (-not (Test-Path $destRulesDir)) {
            New-Item -ItemType Directory -Path $destRulesDir -Force | Out-Null
        }
        Get-ChildItem -Path $rulesDir -Filter "*.md" | ForEach-Object {
            Backup-AndLink -Source $_.FullName -Destination (Join-Path $destRulesDir $_.Name)
        }
    }

    # commands
    $commandsDir = Join-Path $claudeSourceDir "commands"
    if (Test-Path $commandsDir) {
        $destCommandsDir = Join-Path $claudeDir "commands"
        if (-not (Test-Path $destCommandsDir)) {
            New-Item -ItemType Directory -Path $destCommandsDir -Force | Out-Null
        }
        Get-ChildItem -Path $commandsDir -Filter "*.md" | ForEach-Object {
            Backup-AndLink -Source $_.FullName -Destination (Join-Path $destCommandsDir $_.Name)
        }
    }

    # statusline (PowerShell version; native Windows runs statusLine via
    # PowerShell, which cannot execute the bash .sh). Deploy the .sh too so
    # Git Bash sessions still have it available.
    $statuslinePs1 = Join-Path $claudeSourceDir "statusline-windows.ps1"
    if (Test-Path $statuslinePs1) {
        Backup-AndLink -Source $statuslinePs1 -Destination (Join-Path $claudeDir "statusline-windows.ps1")
    }
    $statusline = Join-Path $claudeSourceDir "statusline-windows.sh"
    if (Test-Path $statusline) {
        Backup-AndLink -Source $statusline -Destination (Join-Path $claudeDir "statusline-windows.sh")
    }

    # agents
    $agentsDir = Join-Path $claudeSourceDir "agents"
    if (Test-Path $agentsDir) {
        $destAgentsDir = Join-Path $claudeDir "agents"
        if (-not (Test-Path $destAgentsDir)) {
            New-Item -ItemType Directory -Path $destAgentsDir -Force | Out-Null
        }
        Get-ChildItem -Path $agentsDir -Filter "*.md" | ForEach-Object {
            Backup-AndLink -Source $_.FullName -Destination (Join-Path $destAgentsDir $_.Name)
        }
    }

    # skills
    $skillsDir = Join-Path $claudeSourceDir "skills"
    if (Test-Path $skillsDir) {
        $destSkillsDir = Join-Path $claudeDir "skills"
        Get-ChildItem -Path $skillsDir -Directory | ForEach-Object {
            $skillName = $_.Name
            $skillDestDir = Join-Path $destSkillsDir $skillName
            if (-not (Test-Path $skillDestDir)) {
                New-Item -ItemType Directory -Path $skillDestDir -Force | Out-Null
            }
            $skillMd = Join-Path $_.FullName "SKILL.md"
            if (Test-Path $skillMd) {
                Backup-AndLink -Source $skillMd -Destination (Join-Path $skillDestDir "SKILL.md")
            }
        }
    }
}

# Copilot CLI (reuses Claude source of truth)
$copilotDir = Join-Path $env:USERPROFILE ".copilot"
if (Test-Path $claudeSourceDir) {
    if (-not (Test-Path $copilotDir)) {
        New-Item -ItemType Directory -Path $copilotDir -Force | Out-Null
    }

    # Core instructions (CLAUDE.md -> copilot-instructions.md)
    $claudeMd = Join-Path $claudeSourceDir "CLAUDE.md"
    if (Test-Path $claudeMd) {
        Backup-AndLink -Source $claudeMd -Destination (Join-Path $copilotDir "copilot-instructions.md")
    }

    # Rules (.md -> .instructions.md)
    $rulesDir = Join-Path $claudeSourceDir "rules"
    if (Test-Path $rulesDir) {
        $destRulesDir = Join-Path $copilotDir "rules"
        if (-not (Test-Path $destRulesDir)) {
            New-Item -ItemType Directory -Path $destRulesDir -Force | Out-Null
        }
        Get-ChildItem -Path $rulesDir -Filter "*.md" | ForEach-Object {
            $name = $_.BaseName
            Backup-AndLink -Source $_.FullName -Destination (Join-Path $destRulesDir "$name.instructions.md")
        }
    }

    # Skills (SKILL.md -> skill-name.instructions.md)
    $skillsDir = Join-Path $claudeSourceDir "skills"
    if (Test-Path $skillsDir) {
        $destSkillsDir = Join-Path $copilotDir "skills"
        if (-not (Test-Path $destSkillsDir)) {
            New-Item -ItemType Directory -Path $destSkillsDir -Force | Out-Null
        }
        Get-ChildItem -Path $skillsDir -Directory | ForEach-Object {
            $skillName = $_.Name
            $skillMd = Join-Path $_.FullName "SKILL.md"
            if (Test-Path $skillMd) {
                Backup-AndLink -Source $skillMd -Destination (Join-Path $destSkillsDir "$skillName.instructions.md")
            }
        }
    }

    # Agents (merge multiple .md into single AGENTS.md)
    $agentsDir = Join-Path $claudeSourceDir "agents"
    if (Test-Path $agentsDir) {
        $agentFiles = Get-ChildItem -Path $agentsDir -Filter "*.md" | Sort-Object Name
        if ($agentFiles.Count -gt 0) {
            $agentsDest = Join-Path $copilotDir "AGENTS.md"
            if (Test-Path $agentsDest) {
                if (-not $script:BackupCreated) {
                    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
                    $script:BackupCreated = $true
                }
                Move-Item -Path $agentsDest -Destination (Join-Path $BackupDir "AGENTS.md") -Force
            }
            $content = ($agentFiles | ForEach-Object { Get-Content $_.FullName -Raw }) -join "`n`n---`n`n"
            Set-Content -Path $agentsDest -Value $content -NoNewline
            Write-Info "Generated $agentsDest from agents/*.md"
        }
    }
}

# Codex CLI (reuses Claude source of truth)
$codexSourceDir = Join-Path $DotfilesDir "codex"
$codexDir = Join-Path $env:USERPROFILE ".codex"
# Codex discovers skills in $CODEX_HOME/skills (default ~/.codex/skills),
# not ~/.agents/skills. Keep in sync with install.sh.
$codexSkillsDir = Join-Path $codexDir "skills"
$mcpSource = Join-Path $claudeSourceDir "mcp-servers.json"
if ((Test-Path $claudeSourceDir) -or (Test-Path $codexSourceDir)) {
    foreach ($d in @($codexDir, $codexSkillsDir)) {
        if (-not (Test-Path $d)) {
            New-Item -ItemType Directory -Path $d -Force | Out-Null
        }
    }

    # AGENTS.md (link codex/AGENTS.md, or merge CLAUDE.md + rules for old checkouts)
    $codexAgents = Join-Path $codexSourceDir "AGENTS.md"
    if (Test-Path $codexAgents) {
        Backup-AndLink -Source $codexAgents -Destination (Join-Path $codexDir "AGENTS.md")
    } else {
        $claudeMd = Join-Path $claudeSourceDir "CLAUDE.md"
        if (Test-Path $claudeMd) {
            $parts = @((Get-Content -LiteralPath $claudeMd -Raw))
            $claudeRulesDir = Join-Path $claudeSourceDir "rules"
            if (Test-Path $claudeRulesDir) {
                Get-ChildItem -Path $claudeRulesDir -Filter "*.md" | Sort-Object Name | ForEach-Object {
                    $parts += "`n---`n"
                    $parts += (Get-Content -LiteralPath $_.FullName -Raw)
                }
            }
            $agentsDest = Join-Path $codexDir "AGENTS.md"
            if (Test-PathOrLink $agentsDest) {
                if (Test-IsSymlink $agentsDest) { Remove-Symlink $agentsDest } else { Backup-Existing $agentsDest }
            }
            Write-Utf8Text -Path $agentsDest -Text ($parts -join "`n")
            Write-Info "Generated $agentsDest from CLAUDE.md + rules/*.md"
        }
    }

    # Base config is copied (never symlinked) so MCP edits never touch the repo.
    $codexConfig = Join-Path $codexSourceDir "config.toml"
    if (Test-Path $codexConfig) {
        Backup-AndCopy -Source $codexConfig -Destination (Join-Path $codexDir "config.toml")
    }

    # Skills (~/.codex/skills/<name> -> claude/skills/<name>)
    $codexSkillsSrc = Join-Path $claudeSourceDir "skills"
    if (Test-Path $codexSkillsSrc) {
        Get-ChildItem -Path $codexSkillsSrc -Directory | ForEach-Object {
            Backup-AndLink -Source $_.FullName -Destination (Join-Path $codexSkillsDir $_.Name) -IsDirectory
        }
    }

    # MCP servers (repo source -> Claude + Codex)
    if (Test-Path $mcpSource) {
        Write-MissingMcpEnvWarnings -SourcePath $mcpSource
        Sync-ClaudeMcp -SourcePath $mcpSource -DestPath (Join-Path $env:USERPROFILE ".claude.json")
        Sync-CodexMcp -SourcePath $mcpSource -DestPath (Join-Path $codexDir "config.toml")
    }
}

# Workspace config (~/git/)
$workspaceDir = Join-Path $env:USERPROFILE "git"
$claudeWorkspaceDir = Join-Path $DotfilesDir "claude-workspace"
if ((Test-Path $claudeWorkspaceDir) -and (Test-Path $workspaceDir)) {
    # Claude workspace CLAUDE.md
    $wsClaude = Join-Path $claudeWorkspaceDir "CLAUDE.md"
    if (Test-Path $wsClaude) {
        Backup-AndLink -Source $wsClaude -Destination (Join-Path $workspaceDir "CLAUDE.md")
    }

    # Copilot workspace instructions
    $wsCopilotDir = Join-Path $workspaceDir ".copilot"
    if (-not (Test-Path $wsCopilotDir)) {
        New-Item -ItemType Directory -Path $wsCopilotDir -Force | Out-Null
    }
    Backup-AndLink -Source $wsClaude -Destination (Join-Path $wsCopilotDir "copilot-instructions.md")
}

# Drop dest entries left behind when their source was deleted or renamed.
# Each mapping converts a dest file/dir name back to its expected source path;
# anything whose source is gone gets removed.
$cleanupClaudeDir = Join-Path $env:USERPROFILE ".claude"
$cleanupCopilotDir = Join-Path $env:USERPROFILE ".copilot"
$cleanupCodexSkillsDir = Join-Path $env:USERPROFILE ".codex\skills"
$cleanupClaudeSrc = Join-Path $DotfilesDir "claude"

Remove-OrphanedItems -DestDir (Join-Path $cleanupClaudeDir "commands") -SourcePathFromName {
    param($name) Join-Path $cleanupClaudeSrc "commands\$name"
}
Remove-OrphanedItems -DestDir (Join-Path $cleanupClaudeDir "agents") -SourcePathFromName {
    param($name) Join-Path $cleanupClaudeSrc "agents\$name"
}
Remove-OrphanedItems -DestDir (Join-Path $cleanupClaudeDir "rules") -SourcePathFromName {
    param($name) Join-Path $cleanupClaudeSrc "rules\$name"
}
Remove-OrphanedItems -DestDir (Join-Path $cleanupClaudeDir "skills") -SourcePathFromName {
    param($name) Join-Path $cleanupClaudeSrc "skills\$name"
}
Remove-OrphanedItems -DestDir (Join-Path $cleanupCopilotDir "rules") -SourcePathFromName {
    param($name)
    $base = $name -replace '\.instructions\.md$', '.md'
    Join-Path $cleanupClaudeSrc "rules\$base"
}
Remove-OrphanedItems -DestDir (Join-Path $cleanupCopilotDir "skills") -SourcePathFromName {
    param($name)
    $base = $name -replace '\.instructions\.md$', ''
    Join-Path $cleanupClaudeSrc "skills\$base"
}
Remove-OrphanedItems -DestDir $cleanupCodexSkillsDir -SourcePathFromName {
    param($name) Join-Path $cleanupClaudeSrc "skills\$name"
}

# Footer
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Info "Installation complete!"
if ($BackupCreated) {
    Write-Warn "Backups saved to: $BackupDir"
}
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
