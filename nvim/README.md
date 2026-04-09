# Neovim Setup

## Prerequisites

### Neovim (>= 0.10)

- macOS: `brew install neovim`
- Linux (Debian/Ubuntu): `sudo apt install neovim` (note: apt version may be too old; use [GitHub releases](https://github.com/neovim/neovim/releases) or the [PPA](https://launchpad.net/~neovim-ppa/+archive/ubuntu/unstable) for latest)
- Linux (Arch): `sudo pacman -S neovim`

### Node.js (for LSP servers)

- fnm: `fnm install --lts`
- nvm: `nvm install --lts`

### Package Managers

- bun: `curl -fsSL https://bun.sh/install | bash`
- uv: `curl -LsSf https://astral.sh/uv/install.sh | sh`

### Nerd Font

A [Nerd Font](https://www.nerdfonts.com/) is required for icons. Recommended: **RecMonoLinear Nerd Font**.

## Dependencies

### CLI Tools

- macOS: `brew install fzf ripgrep shfmt stylua lua-language-server fixjson`
- Linux (Debian/Ubuntu): `sudo apt install fzf ripgrep`
  - shfmt, stylua, lua-language-server: install from GitHub releases

### Language Servers (npm-based)

```bash
bun install -g bash-language-server yaml-language-server dockerfile-language-server-nodejs typescript-language-server prettier prettierd svelte-language-server @tailwindcss/language-server vscode-langservers-extracted
```

### Python Tools

```bash
uv tool install ruff
uv tool install pyright
```

### Rust (optional)

```bash
# rust-analyzer is included with rustup
rustup component add rust-analyzer
```

### Zig (optional)

- macOS: `brew install zig zls`

## Install

```bash
# 1. Symlink (handled by install.sh)
./install.sh

# 2. Open Neovim — Lazy.nvim will auto-install all plugins on first launch
nvim
```

## What it configures

- **Framework**: NvChad v2.5 (via Lazy.nvim)
- **LSP servers**: bash, css, docker, html, json, lua, markdown (marksman), python (pyright), rust, svelte, tailwindcss, typescript, yaml, zig
- **Formatters** (format on save): stylua, prettier/prettierd, ruff, rustfmt, shfmt, zigfmt, fixjson
- **Plugins**: Copilot, gitsigns, nvim-tree, treesitter, render-markdown, presenting.nvim, image.nvim
