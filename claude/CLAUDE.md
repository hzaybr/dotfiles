# Global Claude Code Guidelines

## Response Language

- Respond in Traditional Chinese (繁體中文)
- Code, comments, and commit messages in English

## Tools

- Python: use `uv`, never `pip`
- Node.js: prefer `bun`, then `pnpm`

## Formatting

- Never use tables in Markdown — use lists or headings instead (tables are hard to edit and read in terminal)

## Shell Environment

- To delete files: use `mv <file> ~/tmp/` (safe delete, can recover)
- Only use `/bin/rm` when absolutely sure the file should be permanently removed, or when cleaning up temporary files in `~/tmp/`, `/tmp/`
