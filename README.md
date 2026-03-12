# Dotfiles

Personal configuration files for zsh, tmux, git, ghostty, neovim, Claude Code, and GitHub Copilot CLI.

## Contents

```
dotfiles/
├── zsh/
│   └── .zshrc              # Zsh configuration (Zim framework + Powerlevel10k)
├── tmux/
│   └── .tmux.conf          # Tmux configuration (screen-like + vim bindings)
├── git/
│   └── ignore              # Global gitignore
├── ghostty/
│   └── config              # Ghostty terminal configuration
├── nvim/                   # Neovim configuration (NvChad-based)
├── claude/
│   ├── CLAUDE.md           # Global Claude Code instructions
│   ├── settings.json       # Hooks and plugins
│   ├── statusline.sh       # Status line script
│   ├── rules/              # Coding style and security rules
│   ├── commands/           # Custom commands (tdd, plan, etc.)
│   ├── hooks/              # Pre/post tool-use hook scripts
│   ├── agents/             # Agent definitions
│   └── skills/             # Skill definitions
├── copilot/
│   ├── hooks.json          # Copilot hooks configuration
│   └── hooks/              # Copilot-specific hook scripts
├── claude-workspace/
│   └── CLAUDE.md           # Shared instructions for all ~/git/ projects
├── install.sh              # Installation script
└── README.md
```

## Prerequisites

Before running `install.sh`:

1. **Create the workspace directory** — the script expects the repo at `~/git/dotfiles`
   ```bash
   mkdir -p ~/git
   ```

2. **Install dependencies** — the script only creates symlinks; it does not install any tools. Install the ones you need from the list below before or after running the script.

## Installation

```bash
git clone <your-repo-url> ~/git/dotfiles
cd ~/git/dotfiles
chmod +x install.sh
./install.sh
```

The script will:

1. Backup existing config files to `~/.dotfiles_backup/<timestamp>/`
2. Create symbolic links to the dotfiles
3. Generate GitHub Copilot CLI config from Claude Code settings (see below)

The script is safe to re-run — it backs up any existing files before overwriting.

## Claude Code → Copilot CLI

`install.sh` uses Claude Code as the single source of truth, and automatically generates corresponding Copilot CLI config under `~/.copilot/`:

- `claude/CLAUDE.md` → `~/.copilot/copilot-instructions.md`
- `claude/rules/*.md` → `~/.copilot/rules/*.instructions.md`
- `claude/skills/*/SKILL.md` → `~/.copilot/skills/*.instructions.md`
- `claude/agents/*.md` → merged into `~/.copilot/AGENTS.md`
- `claude-workspace/CLAUDE.md` → `~/git/.copilot/copilot-instructions.md`

No separate Copilot config directory is needed — edit the `claude/` files and re-run `install.sh` to sync both tools.

### Hooks

Hooks are **not** shared between Claude Code and Copilot CLI due to format differences:

- Claude hooks live in `claude/hooks/` — use `hookSpecificOutput` for feedback to the agent
- Copilot hooks live in `copilot/hooks/` — `postToolUse` output is ignored by Copilot, so warnings go to stderr only

Both sets cover the same checks (prettier, tsc, console.log, ruff, git push guard). `install.sh` installs both to their respective locations.

Copilot CLI loads global hooks from `~/.copilot/hooks/*.json`, so no per-repo setup is needed.

## Dependencies

- [Zim](https://zimfw.sh/) - Zsh framework
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - Zsh theme
- [TPM](https://github.com/tmux-plugins/tpm) - Tmux Plugin Manager
- [Ghostty](https://ghostty.org/) - Terminal emulator
- [Neovim](https://neovim.io/) - Text editor
- [Claude Code](https://claude.ai/claude-code) - AI coding assistant
- [GitHub Copilot CLI](https://docs.github.com/en/copilot/github-copilot-in-the-cli) - AI terminal assistant (optional)
