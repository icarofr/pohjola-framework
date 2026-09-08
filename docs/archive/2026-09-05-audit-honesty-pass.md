# Audit honesty pass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close every leftover from the second-audit challenge so the compiler, docs, cache headers, and CI match the story `AGENTS.md` already tells.

**Architecture:** Fixed-arity slot records stay the ceiling (a 7th About value is a type change, not an array append). Delete silent array adapters. Copy lives as a named sextuple in `Data.I18n`. `x-default` follows `defaultLang` via `data-page-href-default`. Statusful fragments share `htmlOk` with full pages. CI runs only repo-law evals.

**Tech Stack:** PureScript 0.15.16, Bun, Policy.Contract / ContractSpec, GitHub Actions, `make eval … CHECK=1`.

## Global Constraints

- Public framework only — no private app names or paths.
- Do not widen CSP, FFI allowlist, or Alpine seams.
- Do not implement ADR-010 or production auth.
- Do not add Dashboard/Settings templates.
- `defaultLang` already exists (`En`); do not hardcode `En` or `pageHrefEn` for x-default.
- Repo-law evals only in CI: `04-add-ffi`, `05-add-auth`, `08-browser-island`, `09-script-security`, `12-add-ui-component`. Do **not** CI `01`/`02`/`03` (they fail on a clean master by design).
- No `Co-authored-by` trailers.
- Feature views: no `class_`; slots via `renderPage lang route status template`.

## File map

| File | After this plan |
|---|---|
| `src/App/Ui/Templates/Types.purs` | No `valuesSlotsFromArray` / `imageTripleFromArray`. Keep `emptyValue` + `valueSextuple`. |
| `src/Data/I18n.purs` | `about.values.items` is a six-field record. |
| `src/App/Features/About/View.purs` | `valuesSlots` + `valueSextuple` from dict fields. |
| `scripts/auto-scaffold.js` | Scaffold uses explicit `emptyValue` sextuple. |
| `llms.txt` | Matches `AGENTS.md` (status, Schedule/Form, allLangs, no Hero). |
| `src/App/Main.purs` | `htmlOk`; statusful fragments `okWithNoStore`. |
| `src/App/Layout/Head.purs` | x-default + `data-page-href-default` from `defaultLang`. |
| `src/App/Layout/Scripts.purs` | TitleSync uses `pageHrefDefault`. |
| `test/Route/RouteSpec.purs` | `allRoutes` coverage + PostDetail exclusion. |
| `test/ContractSpec.purs` | `htmlOk` cache policy; href-default pin. |
| `docs/adr/ADR-011-*.md` | Tier 5 / agent table: island runtime, ADR-010 not accepted. |
| `.github/workflows/ci.yml` | `eval-repo-law` job. |
| `Makefile` | `eval-repo-law` target. |

Do **not** create: new PageTemplates, I18n file splits, App.Bun gates.

---

### Task 1: Compiler owns About values; delete silent adapters

**Files:**
- Modify: `src/App/Ui/Templates/Types.purs`
- Modify: `src/Data/I18n.purs`
- Modify: `src/App/Features/About/View.purs`
- Modify: `scripts/auto-scaffold.js`
- Modify: `README.md` About sample
- Modify: `docs/superpowers/specs/2026-08-31-page-architectures.md` Editorial row

**Interfaces:**
- Produces: `about.values.items :: { one, two, three, four, five, six :: { title, description } }`
- Produces: `emptyValue` still exported for generator placeholders
- Removes: `valuesSlotsFromArray`, `imageTripleFromArray`

- [x] Dictionary items become a sextuple (same record shape as `ValueItem`).
- [x] About calls `valuesSlots heading intro (valueSextuple items.one … items.six)`.
- [x] Delete both `*FromArray` functions.
- [x] Generator Editorial stub uses six `emptyValue`s, never `[]`.
- [x] `make test` (About still renders six values). `make generator-policy`.

---

### Task 2: `llms.txt` matches `AGENTS.md`

**Files:**
- Modify: `llms.txt`

Must include:
- `renderPage lang route status (Landing|Hub|Editorial|Feed|Article|Schedule|Form …)`
- Copy in `Data.I18n` for every `allLangs` (En, Fr, Pt)
- Do not import `App.Ui.Hero` (module does not exist)
- Schedule + Form in the page→template table
- `CHECK=1` not `--check`

---

### Task 3: `allRoutes` coverage

**Files:**
- Modify: `test/Route/RouteSpec.purs`
- Modify: `src/Data/Route.purs` (comment on `allRoutes` if needed)

- [x] Assert `allRoutes` equals `[Home, About, Contact, PostList, Fixtures]`.
- [x] Assert `staticRoutes` equals `[Home, About, Contact, Fixtures]`.
- [x] Assert no `PostDetail _` in `allRoutes` (ids are data; sitemap cannot enumerate them).
- [x] `make test`

---

### Task 4: Statusful fragments use `htmlOk`

**Files:**
- Modify: `src/App/Main.purs` (export `htmlOk`)
- Modify: `test/ContractSpec.purs`

```purescript
htmlOk :: Boolean -> Array (Tuple String String) -> String -> Server.Response
htmlOk statusful hdrs body =
  if statusful then Server.okWithNoStore hdrs body else Server.okWith hdrs body
```

`fullPage` and `handleFragment` both call `htmlOk`. Tests: statusful → `no-store`; not → `private, max-age=10`.

---

### Task 5: x-default from `defaultLang`

**Files:**
- Modify: `src/App/Layout/Head.purs`
- Modify: `src/App/Layout/Scripts.purs`
- Modify: `test/ContractSpec.purs`
- Modify: `docs/conventions/adding-a-language.md`

- Head `hreflang=x-default` href uses `routeUrl defaultLang route`.
- `pageSyncAttrs` adds `data-page-href-default` with the same URL path.
- TitleSync IIFE: `if(d.pageHrefDefault)hrefLink('link[rel="alternate"][hreflang="x-default"]',d.pageHrefDefault);` — no `pageHrefEn`.
- ContractSpec: fragment HTML / attrs contain `data-page-href-default`; TitleSync source contains `pageHrefDefault`, not `pageHrefEn`.

---

### Task 6: ADR-011 wording

**Files:**
- Modify: `docs/adr/ADR-011-alpine-ajax-frozen-transport.md`

Tier 5 and the agent-rules live/widget row: **island runtime — ADR-010 (proposed, do not implement)**. Keep Datastar rejected as **nav transport**.

---

### Task 7: Repo-law evals in CI

**Files:**
- Modify: `Makefile`
- Modify: `.github/workflows/ci.yml`
- Modify: `evals/README.md`

```makefile
## eval-repo-law: evals that must pass on a clean master
.PHONY: eval-repo-law
eval-repo-law:
	$(MAKE) eval EVAL=04-add-ffi CHECK=1
	$(MAKE) eval EVAL=05-add-auth CHECK=1
	$(MAKE) eval EVAL=08-browser-island CHECK=1
	$(MAKE) eval EVAL=09-script-security CHECK=1
	$(MAKE) eval EVAL=12-add-ui-component CHECK=1
```

CI job after unit tests (or a step in `test`). Do not add 01/02/03.

---

### Verify

```bash
export PATH="$HOME/.bun/bin:$PATH"
make format-check
make gate
make test
make generator-policy
make eval-repo-law
```

Expected: all pass.
