# GitHub Copilot CLI Setup

## Prerequisites

### GitHub Copilot CLI

```bash
# Via GitHub CLI extension
gh extension install github/gh-copilot
```

Requires an active GitHub Copilot subscription.

### Formatters (for hooks)

Same as Claude Code — see [claude/README.md](../claude/README.md#formatters-for-hooks).

## Install

```bash
# Symlink (handled by install.sh)
./install.sh
```

## Note

Most Copilot config is auto-generated from Claude Code config by `install.sh`. Edit files in `claude/` and re-run the install script to sync both tools. See the [root README](../README.md#claude-code--copilot-cli) for details.

Hooks are **not** shared — they live separately in `copilot/hooks/` due to format differences.
