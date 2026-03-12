# Global Claude Code Guidelines

## Response Language

- Respond in Traditional Chinese (繁體中文)
- Code, comments, and commit messages in English

## Tools

- Python: use `uv`, never `pip`
- Node.js: prefer `bun`, then `pnpm`

## Formatting

- Never use tables in Markdown — use lists or headings instead (tables are hard to edit and read in terminal)

## Git

- IMPORTANT: Always use the `/commit-message` skill when committing

## Shell Environment

- To delete files: use `mv <file> ~/tmp/` (safe delete, can recover)
- Only use `/bin/rm` when absolutely sure the file should be permanently removed, or when cleaning up temporary files in `~/tmp/`, `/tmp/`

## Critical Rules

- IMPORTANT: Never commit secrets, API keys, or .env files
- Prefer running single tests over full test suite
- Prefer editing existing files over creating new ones
