# Hammerspoon Setup

## Prerequisites

### Hammerspoon (macOS only, requires macOS 13+)

```bash
# Via Homebrew
brew install --cask hammerspoon

# Or download from GitHub releases
# https://github.com/Hammerspoon/hammerspoon/releases/latest
```

Grant **Accessibility** permissions in System Settings → Privacy & Security → Accessibility.

### IPC CLI (optional)

Enable the `hs` CLI for scripting:

```bash
# In Hammerspoon console (Cmd+Alt+C):
hs.ipc.cliInstall()
```

## Install

```bash
# Symlink (handled by install.sh)
./install.sh
```

## What it configures

- Ghostty window management via accessibility API
- New tab / new window creation in Ghostty
- Workspace/space-aware window operations
