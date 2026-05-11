# Global Claude Code Guidelines

## Response Language

- Respond in Traditional Chinese (繁體中文)
- Code, comments, and commit messages in English

## Tools

- Python: use `uv`, never `pip`
- Node.js: prefer `bun`, then `pnpm`

## Formatting

- Never use tables in Markdown - tables are hard to edit and read in terminal

## Git

- IMPORTANT: Always use the `/commit-message` skill when committing

## Shell Environment

- To delete files: use `mv <file> ~/tmp/` (safe delete, can recover)
- Only use `/bin/rm` when absolutely sure the file should be permanently removed, or when cleaning up temporary files in `~/tmp/`, `/tmp/`

## Critical Rules

- IMPORTANT: Never commit secrets, API keys, or .env files
- Prefer running single tests over full test suite
- Prefer editing existing files over creating new ones

---

# Coding Style

## Immutability (CRITICAL)

ALWAYS create new objects, NEVER mutate:

```javascript
// WRONG: Mutation
function updateUser(user, name) {
  user.name = name; // MUTATION!
  return user;
}

// CORRECT: Immutability
function updateUser(user, name) {
  return {
    ...user,
    name,
  };
}
```

**Exception - Svelte 5 `$state` modules:** Mutating the private `$state` object inside state modules (`.svelte.ts`) is expected and necessary. Svelte 5 uses a Proxy to track mutations for reactivity. This exception applies ONLY within encapsulated state modules; all other code (services, utils, helpers) must remain immutable.

## File Organization

MANY SMALL FILES > FEW LARGE FILES:

- High cohesion, low coupling
- 200-400 lines typical, 800 max
- Extract utilities from large components
- Organize by feature/domain, not by type

## Error Handling

ALWAYS handle errors comprehensively:

```typescript
try {
  const result = await riskyOperation();
  return result;
} catch (error) {
  console.error("Operation failed:", error);
  throw new Error("Detailed user-friendly message");
}
```

## Input Validation

ALWAYS validate user input:

```typescript
import { z } from "zod";

const schema = z.object({
  email: z.string().email(),
  age: z.number().int().min(0).max(150),
});

const validated = schema.parse(input);
```

## Code Quality Checklist

Before marking work complete:

- [ ] Code is readable and well-named
- [ ] Functions are small (<50 lines)
- [ ] Files are focused (<800 lines)
- [ ] No deep nesting (>4 levels)
- [ ] Proper error handling
- [ ] No console.log statements
- [ ] No hardcoded values
- [ ] No mutation (immutable patterns used)

---

# Security Guidelines

## Mandatory Security Checks

Before ANY commit:

- [ ] No hardcoded secrets (API keys, passwords, tokens)
- [ ] All user inputs validated
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (sanitized HTML)
- [ ] CSRF protection enabled
- [ ] Authentication/authorization verified
- [ ] Rate limiting on all endpoints
- [ ] Error messages don't leak sensitive data

## Secret Management

```typescript
// NEVER: Hardcoded secrets
const apiKey = "do-not-hardcode-api-keys"

// ALWAYS: Environment variables
const apiKey = process.env.OPENAI_API_KEY

if (!apiKey) {
  throw new Error('OPENAI_API_KEY not configured')
}
```

## Security Response Protocol

If security issue found:

1. STOP immediately
2. Use **security-reviewer** agent
3. Fix CRITICAL issues before continuing
4. Rotate any exposed secrets
5. Review entire codebase for similar issues
