# Dotfiles

- AI configuration is always copied, never symlinked, because clients rewrite
  installed settings at runtime.
- Keep `install.sh` and `install.ps1` aligned.
- Do not run an installer against the real user home unless explicitly asked.
- Keep secrets, auth, and client-generated state out of the repository.
- Commits follow Conventional Commits. Use the top-level directory as the
  scope (e.g. `nvim`, `zsh`, `ai`), `install` for the installers, and omit the
  scope for repository-wide changes.
