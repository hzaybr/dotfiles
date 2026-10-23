# Zsh Setup

## Prerequisites

### Zsh

- macOS: built-in
- Linux (Debian/Ubuntu): `sudo apt install zsh`
- Linux (Arch): `sudo pacman -S zsh`

### Zim (plugin manager) and Powerlevel10k (theme)

No manual install needed. On the first shell launch, `.zshrc` downloads zimfw
into `~/.zim` and installs every module listed in `.zimrc`, including
Powerlevel10k. Do not run Zim's own installer script; it edits `~/.zshrc`.

### Nerd Font

A [Nerd Font](https://www.nerdfonts.com/) is required for Powerlevel10k icons. Recommended: **RecMonoLinear Nerd Font**.

## Dependencies

### fzf (fuzzy finder)

- macOS: `brew install fzf`
- Linux (Debian/Ubuntu): `sudo apt install fzf`

### nvm (optional, Node.js version manager)

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh | bash
```

### Bun (optional)

```bash
curl -fsSL https://bun.sh/install | bash
```

### Zig (optional)

- macOS: `brew install zig`
- Linux: download from [ziglang.org](https://ziglang.org/download/)

## Install

```bash
# Symlink (handled by install.sh)
./install.sh

# Open a new shell; Zim installs zimfw and all modules on first launch
```

## What it configures

- Zim modules: completions, syntax highlighting, history substring search, autosuggestions
- Powerlevel10k prompt (managed by Zim, configured in `.p10k.zsh`) with instant prompt
- fzf keybindings (Ctrl+R history, Ctrl+T file search, Alt+C cd)
- PATH additions: Homebrew, Mason (nvim LSPs), Bun, Zig
- Machine-specific overrides via `~/.zshrc.local` (sourced if exists)
