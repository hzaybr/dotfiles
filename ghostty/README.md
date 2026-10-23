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

- Vesper color theme (alternatives are commented out in `config.ghostty`)
- Font size 16, cell height adjustment, Heiti TC for CJK characters
- macOS: native titlebar, Option as Alt
- Native Cmd keybindings for splits and tabs (`Cmd-d`, `Cmd-[`/`Cmd-]`, `Cmd-Opt-arrows`); run `ghostty +list-keybinds` to see them
- Window state persistence across restarts
- Shell integration (cursor styling disabled)
