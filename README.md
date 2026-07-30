# Dotfiles

Personal configuration for shell, terminal, editors, Git, and AI coding
clients.

## Structure

```text
dotfiles/
├── ai/                  # Claude Code, Codex, and Copilot CLI baselines
│   ├── claude/          # Claude settings and status lines
│   ├── codex/           # Codex configuration
│   ├── skills/          # Shared personal skills
│   ├── instructions.md  # Shared global instructions
│   └── mcp-servers.json # Shared MCP source of truth
├── ghostty/
├── git/
├── hammerspoon/
├── nvim/
├── tmux/
├── vim/
├── zsh/
├── install.sh           # macOS and Linux installer
└── install.ps1          # Windows installer
```

See [`ai/README.md`](ai/README.md) for the AI-specific structure and
dependencies.

## Installation

Clone the repository anywhere, then run the installer from its root.

### macOS and Linux

```bash
./install.sh
```

Static shell, terminal, Git, and editor configuration is installed with
symbolic links.

### Windows

```powershell
.\install.ps1
```

Windows uses copies by default. Pass `-Symlink` to link non-AI configuration
when symbolic-link support is available.

### AI configuration

AI configuration is always copied, never linked. This prevents client-side
settings updates from modifying repository files. Re-running an installer
backs up an existing managed AI path under
`~/.dotfiles_backup/<timestamp>/` before replacing it.

| Repository source | Installed destinations |
| --- | --- |
| `ai/instructions.md` | `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.copilot/copilot-instructions.md` |
| `ai/skills/<name>/` | `~/.claude/skills/<name>/`, `~/.agents/skills/<name>/` |
| `ai/claude/settings*.json` | `~/.claude/settings.json` |
| `ai/claude/statusline*` | `~/.claude/statusline*` |
| `ai/codex/config.toml` | `~/.codex/config.toml` |
| `ai/mcp-servers.json` | `~/.claude.json` and the managed MCP block in `~/.codex/config.toml` |

Authentication, project trust, history, sessions, logs, caches, databases, and
other machine-local runtime data are intentionally not managed here.

## MCP Servers

The shared MCP configuration currently includes:

- GitHub through Docker
- Playwright through `npx`
- Figma through its remote HTTP endpoint

The GitHub MCP container inherits `GITHUB_PERSONAL_ACCESS_TOKEN` from the
client environment. Do not store raw secrets in this repository.

## Dependencies

The installers configure tools but do not install them. Install only what you
use:

- Zim and Powerlevel10k for the provided Zsh setup
- TPM for Tmux plugins
- Ghostty, Neovim, Vim, Git, and GitHub CLI for their respective configuration
- Claude Code, Codex CLI, or GitHub Copilot CLI for AI configuration
- `jq` and `git` for the Claude status line
- Docker for the GitHub MCP server
- Node.js and `npx` for the Playwright MCP server
- PowerShell 5.1 or newer for the native Windows Claude status line
- Git Bash only when using the optional Windows Bash status line
