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

- Short aliases: `a` (add), `cm` (commit), `co` (checkout), `b` (branch), `d` (diff), `s` (short status), `l` (compact log)
- Vim as default editor
- Simple push strategy

## Post-install

Update user info in `~/.gitconfig` if needed:

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```
