# Ghostty Setup

## Prerequisites

### Ghostty

- macOS: download `.dmg` from [ghostty.org](https://ghostty.org/download) or `brew install --cask ghostty`
- Linux: available via distro package managers (Arch `[extra]`, Alpine, Gentoo, Void, etc.)

### Fonts

Install the following fonts:

- **RecMonoLinear Nerd Font** — primary and bold monospace font
- **Heiti TC** — CJK fallback for Chinese characters

Nerd Fonts can be installed via:

```bash
# macOS
brew install --cask font-recursive-mono-nerd-font

# Or download from https://www.nerdfonts.com/font-downloads
```

## Install

```bash
# Symlink (handled by install.sh)
./install.sh
```

## What it configures

- Vesper color theme (alternatives are commented out in `config`)
- Font size 16, cell height adjustment, Heiti TC for CJK characters
- macOS: native titlebar, Option as Alt
- Split keybindings (`Ctrl-Shift-d/s` to split, `Ctrl-h/j/k/l` to move)
- Window state persistence across restarts
- Shell integration (cursor styling disabled)
