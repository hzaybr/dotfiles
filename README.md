# Dotfiles

Personal configuration files for zsh, tmux, git, ghostty, neovim, Claude Code, Codex CLI, and GitHub Copilot CLI.

## Contents

```
dotfiles/
├── zsh/
│   └── .zshrc              # Zsh configuration (Zim framework + Powerlevel10k)
├── tmux/
│   └── .tmux.conf          # Tmux configuration (screen-like + vim bindings)
├── git/
│   └── ignore              # Global gitignore
├── ghostty/
│   └── config              # Ghostty terminal configuration
├── nvim/                   # Neovim configuration (NvChad-based)
├── claude/
│   ├── CLAUDE.md           # Global Claude Code instructions
│   ├── settings.json       # Plugins and UI settings
│   ├── mcp-servers.json    # MCP server source of truth (no secrets)
│   ├── statusline.sh       # Status line script
│   ├── rules/              # Coding style and security rules
│   ├── commands/           # Custom commands (tdd, plan, etc.)
│   ├── agents/             # Agent definitions
│   └── skills/             # Skill definitions
├── codex/
│   ├── AGENTS.md           # Global Codex instructions
│   ├── config.toml         # Base Codex CLI configuration
│   └── README.md           # Codex setup notes
├── copilot/
│   └── README.md           # Copilot CLI notes
├── claude-workspace/
│   └── CLAUDE.md           # Shared instructions for all ~/git/ projects
├── install.sh              # Installation script
└── README.md
```

## Prerequisites

Before running `install.sh`:

1. **Create the workspace directory** — the script expects the repo at `~/git/dotfiles`

   ```bash
   mkdir -p ~/git
   ```

2. **Install dependencies** — the script only creates symlinks; it does not install any tools. Install the ones you need from the list below before or after running the script.

## Installation

```bash
git clone <your-repo-url> ~/git/dotfiles
cd ~/git/dotfiles
chmod +x install.sh
./install.sh
```

The script will:

1. Backup existing config files to `~/.dotfiles_backup/<timestamp>/`
2. Create symbolic links to the dotfiles
3. Generate GitHub Copilot CLI config from Claude Code settings (see below)
4. Install repo-managed Codex instructions and base config from `codex/`
5. Sync MCP servers from `claude/mcp-servers.json` to both Claude and Codex

The script is safe to re-run — it backs up any existing files before overwriting.

## Claude Code → Copilot CLI

`install.sh` uses Claude Code as the single source of truth, and automatically generates corresponding Copilot CLI config under `~/.copilot/`:

- `claude/CLAUDE.md` → `~/.copilot/copilot-instructions.md`
- `claude/rules/*.md` → `~/.copilot/rules/*.instructions.md`
- `claude/skills/*/SKILL.md` → `~/.copilot/skills/*.instructions.md`
- `claude/agents/*.md` → merged into `~/.copilot/AGENTS.md`
- `claude-workspace/CLAUDE.md` → `~/git/.copilot/copilot-instructions.md`

No separate Copilot config directory is needed — edit the `claude/` files and re-run `install.sh` to sync both tools.

## Codex CLI

Codex has its own repo-managed config directory:

- `codex/AGENTS.md` → `~/.codex/AGENTS.md` as a symlink
- `codex/config.toml` → `~/.codex/config.toml` as a copied base config

`config.toml` is copied instead of symlinked because `install.sh` appends the managed MCP server block after install. That keeps resolved environment values and machine-local runtime changes out of the repository.

Runtime files such as `auth.json`, `history.jsonl`, `sessions/`, logs, cache files, and sqlite state should stay in `~/.codex/` only.

## MCP Sync (Claude + Codex)

`install.sh` treats `claude/mcp-servers.json` as the source of truth for MCP servers, then writes:

- `~/.claude.json` → `.mcpServers`
- `~/.codex/config.toml` → managed `[mcp_servers.*]` block appended to the base config from `codex/config.toml`

Do not put raw secrets in this repository.

### Secrets via inherited env

MCP subprocesses inherit the parent process env, so the cleanest way to pass
tokens is to export them in your shell rather than declaring them in
`mcp-servers.json`. For example, in `~/.zshrc`:

```bash
export GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token 2>/dev/null)
```

This keeps tokens out of `~/.claude.json` and `~/.codex/config.toml` on disk.
Rotating `gh auth` picks up automatically on the next shell.

If you still need to declare a literal `env: { KEY: "${VAR}" }` block for a
server (for example, when the server requires a differently named var),
`install.sh` resolves `${VAR}` placeholders at install time and warns about
unset ones.

Current servers:

- `github` — repo/issue/PR tools; reads `GITHUB_PERSONAL_ACCESS_TOKEN` from inherited env
- `serena` — semantic code search and edit over LSP/symbol index
- `playwright` — browser automation for UI testing

### Per-target arg overrides

A server entry may include `<target>Args` (e.g. `codexArgs`) to fully replace
`args` when syncing for that target. `install.sh` passes the target name to
`resolve_mcp_source`, and the base `args` is used when no override exists.

Example — Serena uses a different `--context` per client:

```json
"serena": {
  "command": "uvx",
  "args": ["--from", "git+...", "serena", "start-mcp-server", "--context", "ide-assistant"],
  "codexArgs": ["--from", "git+...", "serena", "start-mcp-server", "--context", "codex"]
}
```

## Dependencies

- [Zim](https://zimfw.sh/) - Zsh framework
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - Zsh theme
- [TPM](https://github.com/tmux-plugins/tpm) - Tmux Plugin Manager
- [Ghostty](https://ghostty.org/) - Terminal emulator
- [Neovim](https://neovim.io/) - Text editor
- [Claude Code](https://claude.ai/claude-code) - AI coding assistant
- [GitHub Copilot CLI](https://docs.github.com/en/copilot/github-copilot-in-the-cli) - AI terminal assistant (optional)
