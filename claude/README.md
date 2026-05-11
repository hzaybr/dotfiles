# Claude Code Setup

## Prerequisites

### Claude Code

```bash
# Native install (recommended, auto-updates)
curl -fsSL https://claude.ai/install.sh | bash

# Or via Homebrew (manual updates)
brew install --cask claude-code
```

## Install

```bash
# Symlink (handled by install.sh)
./install.sh
```

## What it configures

- Global coding instructions (CLAUDE.md)
- Coding style and security rules
- MCP servers (from `mcp-servers.json`)
- LSP plugins: pyright, typescript, lua, rust-analyzer
- Custom skills and agent definitions
