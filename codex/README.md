# Codex CLI Setup

## Managed Files

- `AGENTS.md` - Global Codex instructions.
- `config.toml` - Base Codex CLI configuration.

## Install

```bash
./install.sh
```

The install script links `AGENTS.md` into `~/.codex/AGENTS.md`, copies `config.toml` into `~/.codex/config.toml`, then appends the managed MCP server block from `claude/mcp-servers.json`.

`config.toml` is copied instead of symlinked so resolved MCP environment values never get written back into this repository.

## Do Not Track

Keep runtime and secret-bearing Codex files out of this directory:

- `auth.json`
- `history.jsonl`
- `sessions/`
- `logs*.sqlite`
- `state*.sqlite`
- `cache/`
- `.tmp/`
