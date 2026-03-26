# Dotfiles installation script for Windows
# Creates symbolic links from home directory to dotfiles
# Requires: Run as Administrator OR Developer Mode enabled

#Requires -Version 5.1

param(
    [switch]$Force,
    [switch]$Copy  # Use copy instead of symlinks if symlinks not available
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

function Backup-AndLink {
    param(
        [string]$Source,
        [string]$Destination,
        [switch]$IsDirectory
    )

    if (Test-Path $Destination) {
        if (-not $script:BackupCreated) {
            New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
            $script:BackupCreated = $true
        }
        Write-Warn "Backing up existing $Destination to $BackupDir\"
        $backupName = Split-Path $Destination -Leaf
        Move-Item -Path $Destination -Destination (Join-Path $BackupDir $backupName) -Force
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

# Header
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "     Dotfiles Installation Script" -ForegroundColor Cyan
Write-Host "              (Windows)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check symlink support
$script:UseCopy = $false
if (-not (Test-SymlinkSupport)) {
    if ($Copy) {
        Write-Warn "Symlinks not available, using copy mode instead."
        Write-Warn "Note: Changes to dotfiles won't auto-sync. Re-run script after updates."
        $script:UseCopy = $true
    } else {
        Write-Err "Cannot create symbolic links."
        Write-Err "Please either:"
        Write-Err "  1. Run this script as Administrator"
        Write-Err "  2. Enable Developer Mode in Windows Settings"
        Write-Err "  3. Use -Copy flag to copy files instead of symlinks"
        Write-Host ""
        Write-Host "To enable Developer Mode:" -ForegroundColor Yellow
        Write-Host "  Settings -> Update & Security -> For developers -> Developer Mode" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Or run with copy mode:" -ForegroundColor Yellow
        Write-Host "  .\install.ps1 -Copy" -ForegroundColor Yellow
        exit 1
    }
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

    # hooks
    $hooksDir = Join-Path $claudeSourceDir "hooks"
    if (Test-Path $hooksDir) {
        $destHooksDir = Join-Path $claudeDir "hooks"
        if (-not (Test-Path $destHooksDir)) {
            New-Item -ItemType Directory -Path $destHooksDir -Force | Out-Null
        }
        # Install all hooks except macOS-only ones
        Get-ChildItem -Path $hooksDir -File | Where-Object {
            $_.Name -notmatch '^(notify-permission|post-notify-macos)\.sh$'
        } | ForEach-Object {
            Backup-AndLink -Source $_.FullName -Destination (Join-Path $destHooksDir $_.Name)
        }
    }

    # statusline (use Windows-specific version)
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

    # Hooks (Copilot-specific, skip macOS-only)
    $copilotHooksDir = Join-Path $DotfilesDir "copilot\hooks"
    if (Test-Path $copilotHooksDir) {
        $destHooksDir = Join-Path $copilotDir "hooks"
        if (-not (Test-Path $destHooksDir)) {
            New-Item -ItemType Directory -Path $destHooksDir -Force | Out-Null
        }
        Get-ChildItem -Path $copilotHooksDir -File | Where-Object {
            $_.Name -notmatch 'notify-macos'
        } | ForEach-Object {
            Backup-AndLink -Source $_.FullName -Destination (Join-Path $destHooksDir $_.Name)
        }
    }

    # hooks.json (use Windows version if exists, otherwise filter macOS hooks from original)
    $copilotHooksJson = Join-Path $DotfilesDir "copilot\hooks.windows.json"
    if (-not (Test-Path $copilotHooksJson)) {
        $copilotHooksJson = Join-Path $DotfilesDir "copilot\hooks.json"
    }
    if (Test-Path $copilotHooksJson) {
        Backup-AndLink -Source $copilotHooksJson -Destination (Join-Path $copilotDir "hooks\hooks.json")
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

# Footer
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Info "Installation complete!"
if ($BackupCreated) {
    Write-Warn "Backups saved to: $BackupDir"
}
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
