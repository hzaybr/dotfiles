# AI Configuration

Portable user-level defaults shared by Claude Code, Codex, and GitHub Copilot
CLI.

## Structure

- `instructions.md` contains the shared global instructions.
- `mcp-servers.json` is the source of truth for shared MCP servers.
- `skills/` contains reusable workflows shared across supported clients.
- `claude/` contains Claude Code settings and status-line scripts.
- `codex/config.toml` contains portable Codex defaults.

## Installation Model

The root install scripts copy or generate AI client files under each user's
configuration directory. AI configuration is never symlinked because clients
may update their settings at runtime.

Repository files are portable baselines. Authentication, secrets, project
trust, history, sessions, logs, caches, databases, onboarding state, and other
machine-local runtime data remain outside this repository.

Claude plugin enablement is intentionally not managed globally. Install or
enable language integrations only where they are useful.

## MCP Servers

`mcp-servers.json` currently configures:

- GitHub through the official Docker-based MCP server.
- Playwright through `npx`.
- Figma through its remote HTTP endpoint.

Do not store raw secrets in this repository. The GitHub server reads
`GITHUB_PERSONAL_ACCESS_TOKEN` from the environment inherited by the client.

## Dependencies

- `git` and `jq` are required by the status-line scripts.
- PowerShell 5.1 or newer is required for the native Windows status line.
- Git Bash is required only for the optional Windows Bash status line.
- Docker is required for the GitHub MCP server.
- Node.js and `npx` are required for the Playwright MCP server.

Only install dependencies for the clients and MCP servers you use.
