# ADR-008: Component architecture — two seams, Container mandatory

**Status:** Accepted
**Date:** 2026-08-09

## Context

ADR-001 chose a hand-rolled `Html` ADT over Halogen/Smolder/Flame/Deku. The
decision kept the SSR/Alpine split clean but left no component convention:
features were flat `View.purs` files with inline render helpers, and
width-constrained wrappers (`mx-auto max-w-*`) were hand-written at every
call site.

Two problems emerged:

1. **Flex-column width bug.** `<main>` is `flex-1 flex flex-col`. In a flex
   column, `margin: auto` on the cross axis overrides `align-items: stretch`,
   shrinking children to content width instead of stretching to their
   `max-w-*` value. The fix (`w-full` before `max-w-*`) was missing from
   every call site — 14 of them.

2. **No extraction seam.** Feature render helpers (`renderPostCard`,
   `renderContactForm`) lived in `View.purs` with no promotion path. A helper
   reused across features had nowhere to go except `View.purs` of whichever
   feature needed it first — hidden coupling. The `Home` feature had already
   ad-hoc split into `View/Hero.purs`, `View/Services.purs`, `View/CTA.purs`,
   but the pattern wasn't formalised and no other feature followed it.

## Decision

Components are just functions. In React they're functions; in PureScript
they're functions. The lack of a re-render lifecycle in SSR-once rendering
is irrelevant — components earn their place through **reuse, testability,
and discoverability**, not through lifecycle hooks. A `renderPostCard`
function in its own file is a component whether it re-renders or not.

Establish two seams, enforced by convention, eval, and the generator:

### 1. Feature-local components: `App/Features/<Name>/Components/`

```
src/App/Features/<Name>/
  Page.purs              # Orchestrator
  View.purs              # Page-level rendering, imports from Components/
  Components/            # Feature-local presentational components
    <ComponentName>.purs # One per file, PascalCase
  Types.purs             # Data-backed features only
  Service.purs           # Data-backed features only
```

Components are pure functions: `Lang -> Data -> Html` (props in, Html out).
One component per file, PascalCase filename. Extract any distinct visual
unit into its own file — a card, a form, a section, a sidebar. `View.purs`
is the orchestrator that composes them, not a dumping ground for inline
helpers.

A feature with only a heading and a paragraph has nothing to extract —
`View.purs` alone is fine. A feature with a list of cards, a form, and a
sidebar has three components.

### 2. Shared primitives: `App/Ui/`

`App/Ui/` holds cross-feature primitives (Button, Card, Container, Social).
A feature component promotes to `App/Ui/` when a second feature needs it.
`App/Ui/` modules must never import from `App/Features/` — the dependency
direction is one-way.

### 3. `App.Ui.Container` is mandatory

All width-constrained wrappers go through:

```purescript
container :: String -> String -> Array Html -> Html
container maxWidth extra inner
-- <div class="mx-auto w-full {maxWidth} px-4 sm:px-6 lg:px-8 {extra}">{inner}</div>
```

Hand-written `mx-auto max-w-*` in views is forbidden (enforced by eval 06).
The `w-full` is load-bearing — it lives in one place, not 14.

### What was rejected

- **A `Box`/`Stack`/`Flex` abstraction layer.** Tailwind utilities are the
  vocabulary; wrapping them in semantic names adds indirection without
  leverage. `Container` earns its place because it fixes a real bug
  centrally; generic layout primitives would not.

## Consequences

- **Reusability**: a component in `Features/Posts/Components/PostCard.purs`
  can be imported by any feature (subject to the cross-feature import ban —
  promotion to `App/Ui/` is the path for cross-feature reuse).
- **Testability**: extracted components can be unit-tested in isolation.
- **Locality**: the `w-full` fix and the container class string live in one
  module. Change once, fixed everywhere.
- **Discoverability**: `Components/` tells you the feature's building blocks
  without reading `View.purs` top to bottom.
- **Promotion path**: feature component → `App/Ui/` when shared. The
  dependency direction (`Ui/` never imports `Features/`) is one-way.
- **Cross-feature imports remain forbidden** (ContractSpec). Features
  compose through `App/Ui/` and `App.Data.Fetch`, not sibling imports.
- **Generator updated**: `make new-feature TYPE=data` scaffolds
  `Components/<Name>Card.purs` and uses `container` in `View.purs` templates.
- **Eval 06** asserts: `container` usage, no hand-written `mx-auto max-w-*`,
  no cross-feature imports.
