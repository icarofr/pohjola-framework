# ADR-011: Freeze Alpine AJAX as shell transport; defer HTMX

**Status:** Accepted  
**Date:** 2026-08-30  
**Amends:** ADR-000 (client seam tiers), ADR-007 (fragment protocol — reaffirmed)  
**Deferred:** HTMX 4 migration — see spike criterion below

## Context

Pohjola needs uniform SPA-feel shell navigation, strict typed client seams, and
agent conventions written once so agents cannot drift from the bedrock model.

We evaluated three stacks:

| Stack | Gzip (approx.) | Shell nav | Local UI | Agent drift risk |
|---|---:|---|---|---|
| **Alpine + Alpine AJAX** (current) | ~20 KB | Works (`spaLink`, `TitleSync`, `x-sync`) | Alpine | Low — closed `App.Alpine` ADT + gate |
| **HTMX 4 + Alpine + hx-alpine-compat** | ~33 KB | Native (`hx-history-elt`) | Alpine | Low — closed `App.Htmx` + gate |
| **Datastar** | ~13 KB | Not designed for it (docs: use `<a>`, avoid `pushState`) | Signals | N/A for nav bedrock |

HTMX 4.0.0 (released 2026-08-28) and Datastar were reviewed. Key findings:

1. **HTMX convention familiarity does not justify +12 KB** when agents only ever
   call closed PureScript constructors (`spaLink`, `shellLink`) — gate and evals
   enforce the seam either way.
2. **HTMX +12 KB is justified only when** in-page hypermedia beyond shell nav
   (form partial swaps, multi-target updates, validation 422 fragments) becomes
   routine — otherwise Alpine AJAX + owned glue is the smaller correct choice.
3. **Pure HTMX + hx-live** is rejected — conflicts with Alpine, ceiling below
   Pohjola Header (`@click.outside`, nested scopes).
4. **Datastar** is rejected as primary nav transport — no history API, SSE-first
   server contract, philosophy opposes shell partial navigation. Reserved for
   ADR-010 tier-5 live/island features.

## Decision

### Freeze Alpine + Alpine AJAX as the bedrock transport layer

| Layer | Owner | Convention |
|---|---|---|
| Shell navigation | `App.Alpine.spaLink` / `navLink` | Internal links → `spaLink`; lang switch → `navLink` (Header only) |
| Local UI | `App.Alpine` (`Flag`, `Expr`, menus, theme) | All chrome through typed builders |
| Glue (owned) | `TitleSync`, `x-sync`, `x-alpine-request` | Documented; tested in ContractSpec + E2E |
| Server fragment | `isFragmentRequest` | `x-alpine-request: true` OR `?_frag=1`; `Vary: x-alpine-request` |

**Do not ship HTMX** until the spike criterion fires.

**Do not ship Datastar** for shell navigation or as a global transport replacement.

### Client runtime (pinned, self-hosted)

| Script | Role |
|---|---|
| `alpine-ajax.min.js` | Shell swap transport (`x-target.push`) |
| `alpinejs.min.js` | Local UI (`x-data`, `x-show`, theme, menus) |

### Interactivity tiers (amended)

| Tier | Tool |
|---|---|
| 0 | CSS-native (`<details>`, `:focus-within`) in `App.Ui` |
| 1 | `App.Alpine` — menus, theme, modals, dismiss |
| 2 | `App.Alpine.spaLink` — shell navigation (Alpine AJAX transport) |
| 3 | `HeadScript` ADT — `DarkModeInit`, `TitleSync`, `DevLiveReload` |
| 4 | Server — forms, mutations (POST → redirect or full/shell page) |
| 5 | Datastar island — ADR-010, explicit per feature (live/SSE widgets) |

### Spike criterion — when to open HTMX migration ADR

Adopt HTMX 4 + Alpine + `hx-alpine-compat` **only when** a bedrock feature
requires **in-page hypermedia without full shell navigation**, for example:

- Form submit → partial re-render with field errors (422) inside a card/region
- Multi-target response (list + toast + counter) in one round-trip
- Tab panel or filter region updated via `hx-get` without navigating away

**Not** triggered by: shell link clicks, theme/menu chrome, or “HTMX is popular.”

When triggered: write ADR-011 amendment or ADR-012; follow deferred migration
research in `docs/plans/htmx-4-migration.md` (planning artifact, not active).

### Agent rules (frozen)

| Situation | Use |
|---|---|
| Internal navigation | `App.Alpine.spaLink` |
| Language switch | `App.Alpine.navLink` in `Header` only |
| Menu / theme / modal | `App.Alpine` builders |
| Form submit (default) | Server POST → redirect or shell/full page |
| In-page partial (until HTMX spike) | **Do not invent** — escalate to spike criterion |
| Live/real-time widget | ADR-010 Datastar island (explicit, per feature) |

Raw `x-target`, `x-alpine-request`, `fetch(` in feature views remain **banned**
(gate + ContractSpec).

## Consequences

### Gains

- ~20 KB gzip client bundle — no speculative +12 KB HTMX premium
- Zero migration cost; existing ContractSpec, Venom, Playwright matrix preserved
- Agent conventions stay in one module (`App.Alpine`) for transport + chrome
- Clear, testable spike criterion for future HTMX — no ambiguous “maybe later”

### Accepted costs

- Own `TitleSync` popstate glue and `x-sync` re-init contract
- `x-alpine-request` is Pohjola-specific (not industry `HX-*`) — acceptable
  because agents never emit it raw
- In-page hypermedia before HTMX spike = full navigation or server redirect

### Rejected alternatives

| Alternative | Why rejected (for now) |
|---|---|
| HTMX 4 + Alpine now | +12 KB without proven in-page hypermedia need; conventions don't need it |
| Pure HTMX + hx-live | Ceiling below Header; conflicts with Alpine |
| Datastar as nav bedrock | No history; SSE-first; opposes shell SPA model |
| Essay full-MPA only (no shell) | User chose uniform shell SPA UX |

## Related

- [`docs/plans/htmx-4-migration.md`](../plans/htmx-4-migration.md) — deferred migration plan
- [`docs/adr/ADR-007-bun-serve.md`](ADR-007-bun-serve.md) — fragment protocol
- [`docs/adr/ADR-010-browser-island-integration.md`](ADR-010-browser-island-integration.md) — Datastar tier
