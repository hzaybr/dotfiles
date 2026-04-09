# Zsh Setup

## Prerequisites

### Zsh

- macOS: built-in
- Linux (Debian/Ubuntu): `sudo apt install zsh`
- Linux (Arch): `sudo pacman -S zsh`

### Zim (plugin manager)

```bash
curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
```

### Powerlevel10k (theme)

Installed automatically via Zim modules in `.zimrc`.

### Nerd Font

A [Nerd Font](https://www.nerdfonts.com/) is required for Powerlevel10k icons. Recommended: **RecMonoLinear Nerd Font**.

## Dependencies

### fzf (fuzzy finder)

- macOS: `brew install fzf`
- Linux (Debian/Ubuntu): `sudo apt install fzf`

### Node.js version manager (optional)

- fnm: `brew install fnm` or `curl -fsSL https://fnm.vercel.app/install | bash`
- nvm: `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh | bash`

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

# Zim will auto-install modules on first shell launch
```

## What it configures

- Zim modules: completions, syntax highlighting, history substring search, autosuggestions
- Powerlevel10k instant prompt
- fzf keybindings (Ctrl+R history, Ctrl+T file search, Alt+C cd)
- PATH additions: Homebrew, Mason (nvim LSPs), Bun, Zig
- Machine-specific overrides via `~/.zshrc.local` (sourced if exists)
