---
name: commit-message
description: Create Conventional Commit messages from staged or working-tree changes and optionally make the commit. Use when the user asks for a commit message, asks to commit changes, invokes `/commit` or `/commit-message`, or wants help splitting changes into commits.
---

# Commit Message

## Workflow

1. Inspect `git status --short` and `git diff --staged`.
2. If changes are staged, base the commit message only on the staged diff.
3. If nothing is staged, inspect the working-tree diff and confirm the intended scope before staging anything.
4. Suggest separate commits when unrelated changes are mixed.
5. Show the proposed message when the user asks only for wording.
6. Run `git commit` only when the user explicitly asks to commit.

## Commit Composition

Each commit must represent one logical change. Do not bundle unrelated changes that should be independently revertible.

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) and choose the type according to the change's intent:

- `build`: Change dependencies, build tooling, or build configuration.
- `chore`: Perform repository maintenance that does not fit a more specific type. Use this only as a fallback.
- `ci`: Change continuous integration configuration or automation.
- `docs`: Change documentation only.
- `feat`: Add or expand user-visible behavior or capability.
- `fix`: Correct incorrect user-visible or technical behavior.
- `perf`: Improve runtime or build performance without changing intended behavior.
- `refactor`: Restructure implementation without adding a feature or fixing a defect.
- `style`: Change formatting or other non-semantic presentation of source code.
- `test`: Add or correct automated tests.

Write the subject in the imperative present tense.

Every commit must include a body that explains:

- the problem and technical objective;
- why the chosen implementation addresses that problem.

Do not use the body merely to restate the diff. Mechanical message constraints are defined by `commitlint.config.js`.
