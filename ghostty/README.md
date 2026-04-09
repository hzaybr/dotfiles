# Ghostty Setup

## Prerequisites

### Ghostty

- macOS: download `.dmg` from [ghostty.org](https://ghostty.org/download) or `brew install --cask ghostty`
- Linux: available via distro package managers (Arch `[extra]`, Alpine, Gentoo, Void, etc.)

### Fonts

Install the following fonts:

- **RecMonoLinear Nerd Font** — primary monospace font
- **RecMonoDuotone Nerd Font** — bold variant
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

- Nord color theme
- Font size 18, cell height adjustment
- macOS: native titlebar with tabs, Option as Alt
- Window state persistence across restarts
- Shell integration (cursor styling disabled)
