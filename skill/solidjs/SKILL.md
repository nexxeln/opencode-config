---
name: solidjs
description: >
  Best practices and idiomatic patterns for SolidJS development. Use when writing, reviewing, or
  refactoring SolidJS components, signals, stores, effects, or reactive primitives. Triggers on:
  SolidJS, Solid.js, solid-js, createSignal, createEffect, createMemo, createStore, createResource,
  or when the project uses SolidJS as its UI framework.
---

# SolidJS Best Practices

## Reactivity Model

SolidJS components run once as setup code. The component body is **not** reactive. Reactivity only
occurs inside reactive scopes: JSX expressions, `createEffect`, `createMemo`, and `createResource`.

All guidance below follows from this core principle.

## Rules

### 1. Call signal accessors when passing to JSX props

Pass `id={id()}` not `id={id}`. Components should not need to know whether a prop came from a
signal or a static value. Calling the accessor at the call site keeps prop types uniform.

```tsx
// correct
<User id={id()} name="Brenley" />

// wrong — forces User to accept Accessor<number> for id
<User id={id} name="Brenley" />
```

### 2. Never destructure props

Props are reactive via getters. Destructuring extracts the value and breaks tracking.

```tsx
// broken — name is no longer reactive
function User(props: { name: string }) {
  const { name } = props;
  return <h1>{name}</h1>;
}

// correct
function User(props: { name: string }) {
  return <h1>{props.name}</h1>;
}
```

Use `splitProps` when prop splitting is genuinely needed.

### 3. Wrap derived values in functions or createMemo

A signal read in the component body runs once and never updates.

```tsx
// broken — doubled is a static number
const doubled = count() * 2;

// reactive — function wrapper defers the read to a reactive scope
const doubled = () => count() * 2;

// reactive + cached — createMemo avoids redundant recalculation
const doubled = createMemo(() => count() * 2);
```

Use a plain function wrapper when the computation is trivial. Use `createMemo` when the derived
value is read in multiple places or the computation is expensive.

### 4. Use `<Show>` and `<For>` instead of JS conditionals/map

Solid provides control-flow components that integrate with its reactive system.

```tsx
// prefer
<Show when={open()} fallback={<EmptyState />}>
  <SidebarMenu />
</Show>

// instead of
{open() && <SidebarMenu />}
```

```tsx
// prefer
<For each={items()}>{item => <Item item={item} />}</For>

// instead of
{items().map(item => <Item item={item} />)}
```

`<For>` preserves item identity and applies minimal DOM updates. `<Show>` gives explicit
conditional rendering with fallback support.

### 5. Use createEffect sparingly

`createEffect` is for side effects that interact with the outside world (DOM APIs, third-party
libraries). It is not for derived state or data fetching.

**Anti-pattern — derived state via effect:**

```tsx
const [count, setCount] = createSignal(0);
const [double, setDouble] = createSignal(0);
createEffect(() => setDouble(count() * 2)); // don't

// instead, derive it
const double = createMemo(() => count() * 2);
```

**Anti-pattern — data fetching via effect:**

```tsx
const [posts, setPosts] = createSignal([]);
createEffect(async () => {
  const data = await fetch("/api/posts").then(r => r.json());
  setPosts(data); // don't — race conditions, no loading/error state
});

// instead, use createResource
const [posts] = createResource(() => fetch("/api/posts").then(r => r.json()));
```

`createResource` integrates with Suspense and handles loading, error states, and race conditions.

### 6. Derive state instead of syncing it

When one value is a pure function of another, express that relationship directly instead of syncing
via effects.

```tsx
// anti-pattern — manual sync
const [firstName, setFirstName] = createSignal("John");
const [lastName, setLastName] = createSignal("Doe");
const [fullName, setFullName] = createSignal("");
createEffect(() => setFullName(`${firstName()} ${lastName()}`));

// correct — derived value
const fullName = () => `${firstName()} ${lastName()}`;
```

Derived values keep the dependency graph explicit. Effects hide relationships and add unnecessary
indirection.

### 7. Use stores for complex/nested objects

Signals replace the entire value on update. Stores provide fine-grained reactivity at the property
level.

```tsx
// prefer stores for objects
const [board, setBoard] = createStore({
  boards: ["Board 1", "Board 2"],
  notes: ["Note 1", "Note 2"],
});

// granular update — only notes subscribers react
setBoard("notes", notes => [...notes, "Note 3"]);
```

```tsx
// avoid signals for objects — replaces entire value, all readers react
const [board, setBoard] = createSignal({
  boards: ["Board 1", "Board 2"],
  notes: ["Note 1", "Note 2"],
});
setBoard({ ...board(), notes: [...board().notes, "Note 3"] });
```

Stores are deeply reactive. Accessing `board.settings.theme` in JSX tracks only that path.

## Summary Checklist

When writing or reviewing SolidJS code, verify:

- [ ] Signal accessors are called at JSX call sites (`signal()` not `signal`)
- [ ] Props are accessed via `props.x`, never destructured
- [ ] Derived values use function wrappers or `createMemo`, not bare reads in component body
- [ ] `<Show>` and `<For>` are used instead of inline JS conditionals and `.map()`
- [ ] `createEffect` is only used for genuine side effects (DOM, external APIs)
- [ ] State relationships are expressed as derivations, not effect-based sync
- [ ] Complex/nested objects use `createStore` instead of `createSignal`
