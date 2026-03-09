---
name: commit-message
description: Write conventional commit messages from staged changes. Use when the
  user asks to commit, write a commit message, /commit, or wants to describe their
  changes for git. Analyzes git diff to generate clear, consistent commit messages
  following Conventional Commits format.
---

# Commit Message

Generate commit messages from staged changes using the Conventional Commits format.

## Workflow

1. Run `git diff --staged` to see what's being committed
2. If nothing is staged, run `git diff` and `git status` to show the user what's available, then ask what they want to stage
3. Analyze the changes and craft a commit message
4. Present the message to the user for approval before committing

## Message Format

```
type(scope): subject

body (optional)
```

### Type

Choose the type that best describes the **intent** of the change, not just what files were touched:

- **feat** — a new capability for the user (not just a new function — something that delivers new value)
- **fix** — corrects a bug that was affecting users or functionality
- **refactor** — restructures code without changing behavior (rename, extract, reorganize)
- **docs** — documentation only (README, comments, JSDoc)
- **style** — formatting, whitespace, semicolons — no logic change
- **test** — adding or updating tests only
- **chore** — build config, dependencies, tooling, CI — nothing the app user sees
- **perf** — performance improvement without changing functionality

### Scope

Optional. Use when the change is clearly scoped to a specific module, component, or domain:

- `feat(auth): add OAuth2 login flow`
- `fix(api): handle null response from payment gateway`

Skip the scope when the change is broad or doesn't belong to a clear module. A missing scope is better than a forced one.

### Subject

- Start with a lowercase verb (add, fix, update, remove, refactor)
- Be specific about **what** changed, not just "update code"
- Under 50 characters — if you can't fit it, the commit might be doing too much
- No period at the end

**Good subjects:**
- `add email validation to signup form`
- `fix race condition in websocket reconnect`
- `remove deprecated payment API endpoints`

**Bad subjects:**
- `update files` (too vague)
- `Fix bug` (what bug?)
- `Add new feature for the user authentication system` (too long)

### Body

Add a body when the **why** isn't obvious from the subject alone. The subject says *what* changed; the body explains *why* it matters. A good rule of thumb: if someone reading just the subject would ask "why?", add a body.

**Always use bullet points** (`- `) in the body, not prose paragraphs. Each bullet should describe one logical change or reason.

Typical cases that need a body:
- Bug fixes (what was the root cause?)
- Non-obvious refactors (why restructure this way?)
- Changes that affect multiple areas
- Decisions that trade off one thing for another

Leave a blank line between subject and body. Wrap lines at 72 characters.

```
fix(auth): reject expired refresh tokens on rotation

- Expired refresh tokens were accepted during token rotation,
  allowing indefinite session extension
- Validate expiry before issuing a new access token
```

Cases that usually **don't** need a body:
- `feat(ui): add dark mode toggle` (obvious)
- `fix: typo in error message` (self-explanatory)
- `chore: bump vite to 6.1.0` (routine)

## Analyzing Changes

When reading the diff, focus on understanding **intent** rather than listing every file:

- Look at what functions/components were added, removed, or changed
- Notice patterns: is this a rename? a migration? a new feature? a fix?
- Check if tests were added alongside code changes (if so, probably a feat or fix — not a test commit)
- If changes span multiple concerns, suggest splitting into separate commits

## Presenting to the User

Show the proposed commit message and ask for confirmation. If you're uncertain about the type or scope, say so and offer alternatives. For example:

> This looks like it could be either `refactor` or `fix` — the code was reorganized but also corrects a subtle bug. Which feels more accurate?

After the user confirms (or edits), run the commit.
