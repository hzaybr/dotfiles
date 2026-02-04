# Global Claude Code Guidelines

## Response Language
- Respond in Traditional Chinese (繁體中文)
- Code, comments, and commit messages in English

## Tools
- Python: use `uv`, never `pip`
- Node.js: prefer `bun`, then `pnpm`

## Critical Rules
- IMPORTANT: Never commit secrets, API keys, or .env files
- Prefer running single tests over full test suite
- Prefer editing existing files over creating new ones
