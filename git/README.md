# Git Setup

## Prerequisites

### Git

- macOS: `xcode-select --install` (includes Git)
- Linux (Debian/Ubuntu): `sudo apt install git`

## Install

```bash
# Symlink (handled by install.sh)
./install.sh
```

## What it configures

- Custom aliases (gs, gb, gd, gl, etc.)
- Vim as default editor
- Simple push strategy
- Global gitignore (OS files, editor files, build artifacts)

## Post-install

Update user info in `~/.gitconfig` if needed:

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```
