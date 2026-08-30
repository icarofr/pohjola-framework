# Text Tone Semantic Contract — Design Spec

**Date:** 2026-08-30  
**Status:** Approved (Approach A — Ink | Copy | Meta)  
**ADR:** Amendment appended to `docs/adr/ADR-008-component-architecture.md`

## Problem

Pohjola's StyleX-analogue styling seam (`App.Ui` + DaisyUI + `make gate`) stops agents from writing raw utility soup in feature views, but **foreground opacity still drifted**: `text-base-content/60` through `/85` appeared interchangeably for similar roles. All compiled; agents could invent a sixth opacity without feedback.

The interrupted implementation (2026-08-30) added `App.Ui.TextTone`, migrated call sites, and gated `text-base-content/` outside that module — but used **six variants that map 1:1 to the old soup**. That is a string firewall, not a semantic contract. Jay Dev's question applies: type safety on property names does not stop design-token drift when five "muted" variants all compile.

## Goal

Close the **semantic** styling seam for base-content foreground text so agents have a small, named vocabulary with mechanical enforcement — without adopting StyleX, React, or another CSS compiler.

## Non-Goals

- Background opacity tokens (`bg-base-200/70`, `bg-base-100/90`)
- Replacing Tailwind or DaisyUI
- Migrating `Modal`/`Tabs`/`Accordion` slate utility classes
- External CSS / service worker (separate HTMX plan)
- Visual redesign beyond consolidating supporting text to one opacity

## Approaches Considered

### A. Three semantic roles — **Recommended**

```purescript
data TextTone = Ink | Copy | Meta

-- Ink  -> text-base-content       (headings, primary labels — usually written as bare DaisyUI token)
-- Copy -> text-base-content/80    (all supporting paragraphs, subtitles, descriptions)
-- Meta -> text-base-content/60    (telemetry, legal, section labels, timestamps)
```

`interactiveSoftClass` = `Copy` + `hover:text-base-content` for toolbar/nav controls.

**Pros:** Actually answers token drift; smallest agent vocabulary; matches Linear/StyleX *principle* (semantic contracts) not just syntax.  
**Cons:** Minor visual consolidation (/70, /75, /85 → /80 for supporting copy).

### B. Ship six-variant 1:1 map (interrupted work as-is)

Keep `Default | Soft | Subtle | Muted | Meta | Body` preserving every old opacity.

**Pros:** Zero visual change; finish verification quickly.  
**Cons:** Encodes drift into the type system; agents still pick among Soft/Subtle/Muted/Body for "muted text."

### C. Typed paragraph helpers

Add `textParagraph Copy :: Array Html -> Html` etc. so consumers never assemble class strings.

**Pros:** Strongest agent ergonomics.  
**Cons:** Scope creep; fights existing `class_` + layout utility patterns in `App.Ui.Layout.*`; defer until A is stable.

## Decision

**Approach A.** The point of the StyleX/Cursor thread is constraints that reduce valid choices, not renaming opacity strings. Three roles is the minimum useful vocabulary.

### Tone mapping (migration)

| Old variant | New variant | Notes |
|---|---|---|
| `Default` | *(removed)* | Headings keep bare `text-base-content` |
| `Soft` | `Copy` | Nav inactive, hero subcopy, footer blurb |
| `Subtle` | `Copy` | Section subtitles, card descriptions |
| `Muted` | `Copy` | Stat labels, empty-state descriptions |
| `Body` | `Copy` | Editorial/post body |
| `Meta` | `Meta` | Unchanged |

### Enforcement

| Layer | Mechanism |
|---|---|
| Opacity literals | `make gate` — `text-base-content/` only in `App.Ui/TextTone.purs` |
| Feature views | Eval 06 — no `text-base-content/` in `src/App/Features/` |
| Documentation | ADR-008 amendment + `design-system.md` scorecard item 8 |
| Discovery | Re-export `TextTone`, `toneClass`, `interactiveSoftClass` from `App.Ui` |

### API surface

```purescript
module App.Ui.TextTone where

data TextTone = Ink | Copy | Meta

toneClass :: TextTone -> String
interactiveSoftClass :: String  -- Copy + hover to Ink
```

Optional ergonomic helper (YAGNI unless call sites are noisy):

```purescript
withTone :: TextTone -> String -> String
withTone tone layout = layout <> " " <> toneClass tone
```

## Success Criteria

1. `make check` passes (gate, generator-policy, build, **all unit/property/ContractSpec tests**, format)
2. `make eval EVAL=06-component-architecture --check` passes
3. Zero `text-base-content/` outside `App.Ui/TextTone.purs`
4. ADR-008 tone table reflects three variants (`Ink`, `Copy`, `Meta`)
5. `src/App/Layout/Styles.purs` not included in the change (build artifact)
6. No new styling escape hatches in feature views

## Decision

**Approach A approved.** Three semantic roles; supporting copy consolidates to `/80`.
