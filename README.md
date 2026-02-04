# Dotfiles

Personal configuration files for zsh, tmux, ghostty, and Claude Code.

## Contents

```
dotfiles/
├── zsh/
│   └── .zshrc          # Zsh configuration (Zim framework + Powerlevel10k)
├── tmux/
│   └── .tmux.conf      # Tmux configuration (screen-like + vim bindings)
├── ghostty/
│   └── config          # Ghostty terminal configuration
├── claude/
│   ├── CLAUDE.md       # Global Claude Code instructions
│   ├── settings.json   # Hooks and plugins
│   ├── rules/          # Coding style and security rules
│   ├── commands/       # Custom commands (tdd, plan, etc.)
│   └── skills/         # Skill definitions
├── install.sh          # Installation script
└── README.md
```

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

## Dependencies

- [Zim](https://zimfw.sh/) - Zsh framework
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - Zsh theme
- [TPM](https://github.com/tmux-plugins/tpm) - Tmux Plugin Manager
- [Ghostty](https://ghostty.org/) - Terminal emulator
- [Claude Code](https://claude.ai/claude-code) - AI coding assistant
