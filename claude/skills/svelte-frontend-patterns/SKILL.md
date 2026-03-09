---
name: svelte-frontend-patterns
description: Svelte 5 and SvelteKit 2 development patterns. Use for runes,
  component composition, data loading, form actions, state management, or
  transitions. Covers $state, $derived, $effect, $props, snippets, load
  functions, form actions. Prevents common reactivity mistakes.
---

# Svelte 5 Frontend Patterns

Modern patterns for Svelte 5 runes, SvelteKit 2, and performant user interfaces.

## 1. Runes Essentials

### $state — Reactive State

```svelte
<script lang="ts">
  // Primitive state
  let count = $state(0);

  // Object state (deeply reactive — mutations tracked automatically)
  let user = $state({ name: 'Alice', age: 30 });

  // Array state (deeply reactive)
  let items = $state<string[]>([]);
</script>

<button onclick={() => count++}>{count}</button>
```

### $state.raw — Immutable-Friendly State

```svelte
<script lang="ts">
  // ✅ PREFER $state.raw for immutable patterns (no deep proxy overhead)
  let items = $state.raw<Item[]>([]);

  function addItem(item: Item) {
    // Replace entire array — aligns with immutability coding style
    items = [...items, item];
  }

  function updateItem(id: string, updates: Partial<Item>) {
    items = items.map(item =>
      item.id === id ? { ...item, ...updates } : item
    );
  }
</script>
```

> **When to use which**: Use `$state.raw` for data you replace immutably (lists, API responses). Use `$state` for small interactive objects where mutation is convenient (form fields, toggles).

### $derived — Computed Values

```svelte
<script lang="ts">
  let items = $state.raw<Item[]>([]);
  let search = $state('');

  // Simple expression
  let total = $derived(items.length);

  // Complex computation with $derived.by
  let filtered = $derived.by(() => {
    const query = search.toLowerCase();
    return items.filter(item =>
      item.name.toLowerCase().includes(query)
    );
  });
</script>
```

### $effect — Side Effects Only

```svelte
<script lang="ts">
  let query = $state('');

  // ✅ CORRECT: Side effects (DOM, logging, external systems)
  $effect(() => {
    document.title = `Search: ${query}`;
  });

  // ✅ CORRECT: Cleanup with return
  $effect(() => {
    const handler = setInterval(() => tick(), 1000);
    return () => clearInterval(handler);
  });

  // ❌ WRONG: Do NOT use $effect to sync state — use $derived instead
  // let doubled = $state(0);
  // $effect(() => { doubled = count * 2 });  // ANTI-PATTERN!
  let count = $state(0);
  let doubled = $derived(count * 2);  // ✅ CORRECT
</script>
```

### Decision Tree: $derived vs $effect

```
Need a value computed from other state?
  → $derived / $derived.by

Need to trigger a side effect (DOM, fetch, timer, logging)?
  → $effect

Tempted to set state inside $effect?
  → STOP. Use $derived instead. This is the #1 Svelte 5 mistake.
```

## 2. Component Patterns

### $props with TypeScript

```svelte
<!-- Button.svelte -->
<script lang="ts">
  import type { Snippet } from 'svelte';

  interface Props {
    variant?: 'primary' | 'secondary' | 'ghost';
    disabled?: boolean;
    onclick?: (e: MouseEvent) => void;
    children: Snippet;
  }

  let {
    variant = 'primary',
    disabled = false,
    onclick,
    children
  }: Props = $props();
</script>

<button class="btn btn-{variant}" {disabled} {onclick}>
  {@render children()}
</button>
```

### $bindable for Two-Way Binding

```svelte
<!-- TextInput.svelte -->
<script lang="ts">
  interface Props {
    value: string;
    placeholder?: string;
  }

  let { value = $bindable(), placeholder = '' }: Props = $props();
</script>

<input bind:value={value} {placeholder} />

<!-- Parent.svelte -->
<script lang="ts">
  import TextInput from './TextInput.svelte';

  let name = $state('');
</script>

<TextInput bind:value={name} placeholder="Enter name" />
<p>Hello, {name}</p>
```

### Snippets for Composition

```svelte
<!-- Card.svelte -->
<script lang="ts">
  import type { Snippet } from 'svelte';

  interface Props {
    header: Snippet;
    children: Snippet;
    footer?: Snippet;
  }

  let { header, children, footer }: Props = $props();
</script>

<div class="card">
  <div class="card-header">{@render header()}</div>
  <div class="card-body">{@render children()}</div>
  {#if footer}
    <div class="card-footer">{@render footer()}</div>
  {/if}
</div>

<!-- Usage -->
<Card>
  {#snippet header()}<h2>Title</h2>{/snippet}
  <p>Card body content</p>
  {#snippet footer()}<button>Action</button>{/snippet}
</Card>
```

### Typed Snippet Props

```svelte
<!-- DataList.svelte -->
<script lang="ts" generics="T">
  import type { Snippet } from 'svelte';

  interface Props {
    items: T[];
    row: Snippet<[T, number]>;
    empty?: Snippet;
  }

  let { items, row, empty }: Props = $props();
</script>

{#if items.length === 0}
  {#if empty}{@render empty()}{:else}<p>No items</p>{/if}
{:else}
  {#each items as item, index (item.id ?? item)}
    {@render row(item, index)}
  {/each}
{/if}

<!-- Usage -->
<DataList items={users}>
  {#snippet row(user, i)}<li>{i + 1}. {user.name}</li>{/snippet}
  {#snippet empty()}<p>No users found</p>{/snippet}
</DataList>
```

## 3. Reusable Logic (.svelte.ts Modules)

### Reactive Class Pattern (Svelte's Custom Hooks)

```typescript
// lib/counter.svelte.ts
export class Counter {
  value = $state(0);
  doubled = $derived(this.value * 2);

  increment = () => { this.value++; };
  decrement = () => { this.value--; };
  reset = () => { this.value = 0; };
}

// Usage in component
// let counter = new Counter();
// <button onclick={counter.increment}>{counter.value} (doubled: {counter.doubled})</button>
```

### Extracted Reactive Logic

```typescript
// lib/debounced.svelte.ts
export class Debounced<T> {
  #value: T = $state() as T;
  current: T = $state() as T;
  #timeout: ReturnType<typeof setTimeout> | undefined;

  constructor(initial: T, private delay = 300) {
    this.#value = initial;
    this.current = initial;
  }

  get value() {
    return this.#value;
  }

  set value(v: T) {
    this.#value = v;
    clearTimeout(this.#timeout);
    this.#timeout = setTimeout(() => {
      this.current = v;
    }, this.delay);
  }
}

// Usage: let search = new Debounced('', 500);
// <input bind:value={search.value} />  — search.current updates after 500ms
```

### Factory Function Pattern

```typescript
// lib/media-query.svelte.ts
export function createMediaQuery(query: string) {
  let matches = $state(false);

  $effect(() => {
    const mql = window.matchMedia(query);
    matches = mql.matches;

    const handler = (e: MediaQueryListEvent) => { matches = e.matches; };
    mql.addEventListener('change', handler);
    return () => mql.removeEventListener('change', handler);
  });

  return { get matches() { return matches; } };
}

// Usage: let mobile = createMediaQuery('(max-width: 768px)');
// {#if mobile.matches}<MobileNav />{:else}<DesktopNav />{/if}
```

## 4. State Management

### Context for Component Trees

```typescript
// lib/theme.svelte.ts
import { setContext, getContext } from 'svelte';

export type Theme = 'light' | 'dark';

const THEME_KEY = Symbol('theme');

export function setThemeContext(initial: Theme = 'light') {
  const theme = $state({ current: initial });

  setContext(THEME_KEY, theme);
  return theme;
}

export function getThemeContext() {
  return getContext<{ current: Theme }>(THEME_KEY);
}
```

```svelte
<!-- Layout.svelte -->
<script lang="ts">
  import type { Snippet } from 'svelte';
  import { setThemeContext } from '$lib/theme.svelte';

  let { children }: { children: Snippet } = $props();
  let theme = setThemeContext('light');
</script>

<div class="app" data-theme={theme.current}>
  <button onclick={() => theme.current = theme.current === 'light' ? 'dark' : 'light'}>
    Toggle theme
  </button>
  {@render children()}
</div>

<!-- Any descendant -->
<script lang="ts">
  import { getThemeContext } from '$lib/theme.svelte';
  let theme = getThemeContext();
</script>

<p>Current theme: {theme.current}</p>
```

### When to Use What

```
Local component state       → $state / $state.raw
Computed from existing state → $derived
Share across component tree  → setContext + getContext + $state
Global singleton (careful!)  → .svelte.ts module-level $state
  ⚠️ Avoid module-level $state in SSR — causes state leakage between requests.
     Use context instead for SSR-safe shared state.
```

## 5. SvelteKit Data Loading

### Server Load Functions

```typescript
// +page.server.ts
import { error } from '@sveltejs/kit';
import * as db from '$lib/server/database';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params }) => {
  const post = await db.getPost(params.slug);

  if (!post) {
    error(404, { message: 'Post not found' });
  }

  return { post };
};
```

```svelte
<!-- +page.svelte -->
<script lang="ts">
  import type { PageProps } from './$types';

  let { data }: PageProps = $props();
</script>

<h1>{data.post.title}</h1>
<p>{data.post.content}</p>
```

### Universal vs Server Load

```
+page.server.ts — Runs ONLY on server. Use for:
  ✅ Database queries, filesystem access
  ✅ Private API keys, secrets
  ✅ Heavy computation offloaded from client

+page.ts — Runs on BOTH server and client. Use for:
  ✅ Public API calls (no secrets needed)
  ✅ Data that needs client-side re-fetching on navigation
```

### Streaming with Promises

```typescript
// +page.server.ts
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params }) => {
  return {
    // Awaited — blocks rendering until resolved
    post: await loadPost(params.slug),
    // NOT awaited — streams in, page renders immediately
    comments: loadComments(params.slug)
  };
};
```

```svelte
<!-- +page.svelte -->
<script lang="ts">
  import type { PageProps } from './$types';

  let { data }: PageProps = $props();
</script>

<h1>{data.post.title}</h1>

{#await data.comments}
  <p>Loading comments...</p>
{:then comments}
  {#each comments as comment}
    <p>{comment.content}</p>
  {/each}
{:catch error}
  <p>Failed to load comments</p>
{/await}
```

## 6. SvelteKit Form Actions

### Progressive Enhancement

```typescript
// +page.server.ts
import { fail, redirect } from '@sveltejs/kit';
import type { Actions } from './$types';

export const actions = {
  default: async ({ request }) => {
    const formData = await request.formData();
    const title = formData.get('title')?.toString() ?? '';
    const body = formData.get('body')?.toString() ?? '';

    if (!title.trim()) {
      return fail(400, { title, body, error: 'Title is required' });
    }

    const post = await db.createPost({ title, body });
    redirect(303, `/posts/${post.slug}`);
  }
} satisfies Actions;
```

```svelte
<!-- +page.svelte -->
<script lang="ts">
  import { enhance } from '$app/forms';
  import type { PageProps } from './$types';

  let { form }: PageProps = $props();
</script>

<form method="POST" use:enhance>
  <input name="title" value={form?.title ?? ''} />
  {#if form?.error}
    <p class="error">{form.error}</p>
  {/if}

  <textarea name="body">{form?.body ?? ''}</textarea>
  <button type="submit">Create Post</button>
</form>
```

### Named Actions

```typescript
// +page.server.ts
export const actions = {
  create: async ({ request }) => { /* ... */ },
  delete: async ({ request }) => { /* ... */ }
} satisfies Actions;
```

```svelte
<form method="POST" action="?/create" use:enhance><!-- ... --></form>
<form method="POST" action="?/delete" use:enhance><!-- ... --></form>
```

## 7. SvelteKit Routing

### File Conventions

```
src/routes/
├── +layout.svelte          — Root layout (wraps all pages)
├── +layout.server.ts       — Root layout data
├── +page.svelte            — / (index)
├── +error.svelte           — Error page
├── about/+page.svelte      — /about
├── blog/
│   ├── +page.svelte        — /blog
│   ├── [slug]/
│   │   ├── +page.svelte    — /blog/:slug
│   │   └── +page.server.ts — Server data for blog post
│   └── +layout.svelte      — Layout for /blog/*
├── (marketing)/            — Route group (no URL segment)
│   ├── pricing/+page.svelte — /pricing (shares marketing layout)
│   └── +layout.svelte      — Shared marketing layout
└── api/
    └── posts/+server.ts    — API endpoint: /api/posts
```

### Layout Data Passing

```svelte
<!-- +layout.svelte -->
<script lang="ts">
  import type { LayoutProps } from './$types';

  let { data, children }: LayoutProps = $props();
</script>

<nav>Welcome, {data.user.name}</nav>
<main>{@render children()}</main>
```

## 8. Error Handling

### svelte:boundary (Svelte 5 Native)

```svelte
<script lang="ts">
  function handleError(error: Error) {
    console.error('Component error:', error);
  }
</script>

<svelte:boundary onerror={handleError}>
  <RiskyComponent />

  {#snippet failed(error, reset)}
    <div class="error-fallback">
      <p>Something went wrong: {error.message}</p>
      <button onclick={reset}>Try again</button>
    </div>
  {/snippet}
</svelte:boundary>
```

### SvelteKit Error Pages

```svelte
<!-- +error.svelte -->
<script lang="ts">
  import { page } from '$app/state';
</script>

<h1>{page.status}</h1>
<p>{page.error?.message}</p>
```

## 9. Transitions & Animations

### Built-in Transitions

```svelte
<script lang="ts">
  import { fade, fly, slide, scale } from 'svelte/transition';
  import { flip } from 'svelte/animate';

  let visible = $state(true);
  let items = $state.raw<Item[]>([]);
</script>

<!-- Single element -->
{#if visible}
  <div transition:fade={{ duration: 300 }}>Fades in/out</div>
  <div in:fly={{ y: 20, duration: 400 }} out:fade>Fly in, fade out</div>
{/if}

<!-- Animated list reordering -->
{#each items as item (item.id)}
  <div animate:flip={{ duration: 300 }} transition:slide>
    {item.name}
  </div>
{/each}
```

### Custom Transition

```typescript
// lib/transitions.ts
import type { TransitionConfig } from 'svelte/transition';

export function typewriter(node: HTMLElement, { speed = 1 }): TransitionConfig {
  const text = node.textContent ?? '';
  const duration = text.length / (speed * 0.01);

  return {
    duration,
    tick(t: number) {
      const i = Math.trunc(text.length * t);
      node.textContent = text.slice(0, i);
    }
  };
}
```

## 10. Accessibility

### Svelte Compile-Time Warnings

Svelte checks a11y at compile time. These patterns avoid warnings:

```svelte
<!-- ✅ Interactive elements need keyboard support -->
<!-- Svelte 5: use native element events directly -->
<button onclick={handleClick}>Click me</button>

<!-- ✅ Images need alt text -->
<img src={url} alt="Description of image" />
<!-- Decorative images -->
<img src={bg} alt="" role="presentation" />

<!-- ✅ Form labels -->
<label>
  Email
  <input type="email" name="email" />
</label>

<!-- ✅ Focus management -->
<script lang="ts">
  let dialogRef: HTMLDialogElement;

  function openDialog() {
    dialogRef.showModal();
  }
</script>

<dialog bind:this={dialogRef}>
  <h2>Confirmation</h2>
  <button onclick={() => dialogRef.close()}>Close</button>
</dialog>
```

**Remember**: Svelte 5's core philosophy is *write less code*. Prefer `$derived` over `$effect`, `$state.raw` for immutable data, and SvelteKit's progressive enhancement for forms.
