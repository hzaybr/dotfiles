#!/bin/bash
# Dotfiles installation script
# Creates symbolic links from home directory to dotfiles

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
WORKSPACE_DIR="$HOME/git"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

backup_and_link() {
    local src="$1"
    local dest="$2"

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        mkdir -p "$BACKUP_DIR"
        log_warn "Backing up existing $dest to $BACKUP_DIR/"
        mv "$dest" "$BACKUP_DIR/"
    fi

    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
    log_info "Linked $dest -> $src"
}

echo "=========================================="
echo "        Dotfiles Installation Script"
echo "=========================================="
echo ""

# Zsh
if [ -f "$DOTFILES_DIR/zsh/.zshrc" ]; then
    backup_and_link "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
fi
if [ -f "$DOTFILES_DIR/zsh/.zimrc" ]; then
    backup_and_link "$DOTFILES_DIR/zsh/.zimrc" "$HOME/.zimrc"
fi
if [ -f "$DOTFILES_DIR/zsh/.p10k.zsh" ]; then
    backup_and_link "$DOTFILES_DIR/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
fi

# Tmux
if [ -f "$DOTFILES_DIR/tmux/.tmux.conf" ]; then
    backup_and_link "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
fi

# Git
if [ -f "$DOTFILES_DIR/git/.gitconfig" ]; then
    backup_and_link "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
fi
if [ -f "$DOTFILES_DIR/git/ignore" ]; then
    backup_and_link "$DOTFILES_DIR/git/ignore" "$HOME/.config/git/ignore"
fi

# GitHub CLI
if [ -f "$DOTFILES_DIR/gh/config.yml" ]; then
    backup_and_link "$DOTFILES_DIR/gh/config.yml" "$HOME/.config/gh/config.yml"
fi

# Ghostty
if [ -f "$DOTFILES_DIR/ghostty/config" ]; then
    if [ "$(uname)" = "Darwin" ]; then
        GHOSTTY_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
    else
        GHOSTTY_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
    fi
    backup_and_link "$DOTFILES_DIR/ghostty/config" "$GHOSTTY_DIR/config"
fi

# Neovim
if [ -d "$DOTFILES_DIR/nvim" ]; then
    backup_and_link "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
fi

# Claude Code
CLAUDE_DIR="$HOME/.claude"
if [ -d "$DOTFILES_DIR/claude" ]; then
    # CLAUDE.md
    if [ -f "$DOTFILES_DIR/claude/CLAUDE.md" ]; then
        backup_and_link "$DOTFILES_DIR/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
    fi

    # settings.json
    if [ -f "$DOTFILES_DIR/claude/settings.json" ]; then
        backup_and_link "$DOTFILES_DIR/claude/settings.json" "$CLAUDE_DIR/settings.json"
    fi

    # statusline.sh
    if [ -f "$DOTFILES_DIR/claude/statusline.sh" ]; then
        backup_and_link "$DOTFILES_DIR/claude/statusline.sh" "$CLAUDE_DIR/statusline.sh"
    fi

    # rules
    if [ -d "$DOTFILES_DIR/claude/rules" ]; then
        mkdir -p "$CLAUDE_DIR/rules"
        for file in "$DOTFILES_DIR/claude/rules"/*.md; do
            [ -f "$file" ] && backup_and_link "$file" "$CLAUDE_DIR/rules/$(basename "$file")"
        done
    fi

    # commands
    if [ -d "$DOTFILES_DIR/claude/commands" ]; then
        mkdir -p "$CLAUDE_DIR/commands"
        for file in "$DOTFILES_DIR/claude/commands"/*.md; do
            [ -f "$file" ] && backup_and_link "$file" "$CLAUDE_DIR/commands/$(basename "$file")"
        done
    fi

    # skills
    if [ -d "$DOTFILES_DIR/claude/skills" ]; then
        for skill_dir in "$DOTFILES_DIR/claude/skills"/*/; do
            skill_name=$(basename "$skill_dir")
            mkdir -p "$CLAUDE_DIR/skills/$skill_name"
            if [ -f "$skill_dir/SKILL.md" ]; then
                backup_and_link "$skill_dir/SKILL.md" "$CLAUDE_DIR/skills/$skill_name/SKILL.md"
            fi
        done
    fi

    # hooks
    if [ -d "$DOTFILES_DIR/claude/hooks" ]; then
        mkdir -p "$CLAUDE_DIR/hooks"
        for file in "$DOTFILES_DIR/claude/hooks"/*.sh; do
            [ -f "$file" ] && backup_and_link "$file" "$CLAUDE_DIR/hooks/$(basename "$file")"
        done
    fi

    # agents
    if [ -d "$DOTFILES_DIR/claude/agents" ]; then
        mkdir -p "$CLAUDE_DIR/agents"
        for file in "$DOTFILES_DIR/claude/agents"/*.md; do
            [ -f "$file" ] && backup_and_link "$file" "$CLAUDE_DIR/agents/$(basename "$file")"
        done
    fi
fi

# Copilot CLI (symlinks to Claude source of truth)
COPILOT_DIR="$HOME/.copilot"
if [ -d "$DOTFILES_DIR/claude" ]; then
    mkdir -p "$COPILOT_DIR/rules" "$COPILOT_DIR/skills"

    # Core instructions
    if [ -f "$DOTFILES_DIR/claude/CLAUDE.md" ]; then
        backup_and_link "$DOTFILES_DIR/claude/CLAUDE.md" "$COPILOT_DIR/copilot-instructions.md"
    fi

    # Rules (.md -> .instructions.md)
    if [ -d "$DOTFILES_DIR/claude/rules" ]; then
        for file in "$DOTFILES_DIR/claude/rules"/*.md; do
            [ -f "$file" ] || continue
            name="$(basename "$file" .md)"
            backup_and_link "$file" "$COPILOT_DIR/rules/$name.instructions.md"
        done
    fi

    # Skills (SKILL.md -> skill-name.instructions.md)
    if [ -d "$DOTFILES_DIR/claude/skills" ]; then
        for skill_dir in "$DOTFILES_DIR/claude/skills"/*/; do
            skill_name=$(basename "$skill_dir")
            if [ -f "$skill_dir/SKILL.md" ]; then
                backup_and_link "$skill_dir/SKILL.md" "$COPILOT_DIR/skills/$skill_name.instructions.md"
            fi
        done
    fi

    # Hooks (Copilot-specific versions)
    if [ -d "$DOTFILES_DIR/copilot/hooks" ]; then
        mkdir -p "$COPILOT_DIR/hooks"
        for file in "$DOTFILES_DIR/copilot/hooks"/*.sh; do
            [ -f "$file" ] && backup_and_link "$file" "$COPILOT_DIR/hooks/$(basename "$file")"
        done
    fi
    if [ -f "$DOTFILES_DIR/copilot/hooks.json" ]; then
        backup_and_link "$DOTFILES_DIR/copilot/hooks.json" "$COPILOT_DIR/hooks/hooks.json"
    fi

    # Agents (merge multiple files into single AGENTS.md)
    if [ -d "$DOTFILES_DIR/claude/agents" ]; then
        agents_tmp=$(mktemp)
        first=true
        for file in "$DOTFILES_DIR/claude/agents"/*.md; do
            [ -f "$file" ] || continue
            if [ "$first" = true ]; then
                first=false
            else
                echo "" >> "$agents_tmp"
                echo "---" >> "$agents_tmp"
                echo "" >> "$agents_tmp"
            fi
            cat "$file" >> "$agents_tmp"
        done
        if [ -e "$COPILOT_DIR/AGENTS.md" ] || [ -L "$COPILOT_DIR/AGENTS.md" ]; then
            mkdir -p "$BACKUP_DIR"
            mv "$COPILOT_DIR/AGENTS.md" "$BACKUP_DIR/"
        fi
        mv "$agents_tmp" "$COPILOT_DIR/AGENTS.md"
        log_info "Generated $COPILOT_DIR/AGENTS.md from agents/*.md"
    fi
fi

# Workspace config (~/git/)
if [ -d "$DOTFILES_DIR/claude-workspace" ] && [ -d "$WORKSPACE_DIR" ]; then
    # Claude workspace CLAUDE.md
    if [ -f "$DOTFILES_DIR/claude-workspace/CLAUDE.md" ]; then
        backup_and_link "$DOTFILES_DIR/claude-workspace/CLAUDE.md" "$WORKSPACE_DIR/CLAUDE.md"
    fi

    # Copilot workspace instructions (symlink to same CLAUDE.md)
    mkdir -p "$WORKSPACE_DIR/.copilot"
    backup_and_link "$DOTFILES_DIR/claude-workspace/CLAUDE.md" "$WORKSPACE_DIR/.copilot/copilot-instructions.md"
fi

echo ""
echo "=========================================="
log_info "Installation complete!"
if [ -d "$BACKUP_DIR" ]; then
    log_warn "Backups saved to: $BACKUP_DIR"
fi
echo "=========================================="
