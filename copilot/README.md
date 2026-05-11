# GitHub Copilot CLI Setup

## Prerequisites

### GitHub Copilot CLI

```bash
# Via GitHub CLI extension
gh extension install github/gh-copilot
```

Requires an active GitHub Copilot subscription.

## Install

```bash
# Symlink (handled by install.sh)
./install.sh
```

## Note

Most Copilot config is auto-generated from Claude Code config by `install.sh`. Edit files in `claude/` and re-run the install script to sync both tools. See the [root README](../README.md#claude-code--copilot-cli) for details.
