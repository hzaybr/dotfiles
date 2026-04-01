# Vim Setup

## Prerequisites

### Vim (needs +termguicolors)

- macOS: `brew install vim`
- Linux (Debian/Ubuntu): `sudo apt install vim-gtk3`
- Linux (Fedora): `sudo dnf install vim-enhanced`
- Linux (Arch): `sudo pacman -S gvim`

### Node.js (coc.nvim dependency)

- All platforms: `nvm install --lts` or `fnm install --lts`

### Package Managers

- bun: `curl -fsSL https://bun.sh/install | bash`
- uv: `curl -LsSf https://astral.sh/uv/install.sh | sh`

## Dependencies

### CLI Tools

- macOS: `brew install fzf ripgrep shfmt stylua lua-language-server`
- Linux (Debian/Ubuntu): `sudo apt install fzf ripgrep`
  - shfmt, stylua, lua-language-server need manual install from GitHub releases

### Language Servers (npm-based)

```bash
bun install -g bash-language-server yaml-language-server dockerfile-language-server-nodejs prettier
```

### Python Formatters

```bash
uv tool install black
uv tool install isort
```

### coc.nvim Extensions

Open vim and run:

```vim
:CocInstall coc-tsserver coc-json coc-html coc-css coc-pyright coc-svelte coc-prettier coc-sh
```

### Copilot

First time only, run in vim:

```vim
:Copilot auth
```

## Install

```bash
# 1. Symlink (handled by install.sh)
./install.sh

# 2. Install vim plugins
vim +PlugInstall +qall

# 3. Install coc extensions (see above)
```
