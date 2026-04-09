# Tmux Setup

## Prerequisites

### Tmux

- macOS: `brew install tmux`
- Linux (Debian/Ubuntu): `sudo apt install tmux`
- Linux (Arch): `sudo pacman -S tmux`

### TPM (Tmux Plugin Manager)

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

## Install

```bash
# 1. Symlink (handled by install.sh)
./install.sh

# 2. Install plugins: open tmux, then press prefix + I
tmux
# Press Ctrl-a + I (capital I) to install plugins
```

## Plugins

- tmux-plugins/tmux-sensible — sensible defaults
- arcticicestudio/nord-tmux — Nord color theme

## What it configures

- Prefix key: `Ctrl-a` (instead of default `Ctrl-b`)
- Vim-style pane navigation (`h/j/k/l`)
- Mouse support enabled
- 256-color and RGB support
- Default shell: `/bin/zsh`
