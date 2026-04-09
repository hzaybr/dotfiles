# Claude Code Setup

## Prerequisites

### Claude Code

```bash
# Native install (recommended, auto-updates)
curl -fsSL https://claude.ai/install.sh | bash

# Or via Homebrew (manual updates)
brew install --cask claude-code
```

### Formatters (for hooks)

- macOS: `brew install stylua shfmt`
- prettier: `bun install -g prettier`
- ruff: `uv tool install ruff`

## Install

```bash
# Symlink (handled by install.sh)
./install.sh
```

## What it configures

- Global coding instructions (CLAUDE.md)
- Coding style and security rules
- Pre/post tool-use hooks (auto-approve reads, format on save, notifications)
- LSP plugins: pyright, typescript, lua, rust-analyzer
- Custom skills and agent definitions
