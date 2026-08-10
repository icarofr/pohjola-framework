# ADR-001: Hand-rolled Html ADT, not Halogen/Smolder/Flame

**Status:** Accepted
**Date:** 2026-08

## Context

The server needs to produce HTML as `String` for SSR. Options evaluated:

- **Halogen** — component framework with VDOM, effects, lifecycle. Designed
  for client-side SPAs; SSR is not first-class. Wrong shape for an SSR MPA
  where Alpine owns interactivity.
- **Smolder** (`bodil/purescript-smolder`) — markup DSL, the closest
  off-the-shelf match. Effectively unmaintained ("low maintenance mode" per
  the author). Adopting it means owning an orphaned dependency.
- **Flame** — actively maintained Elm-architecture framework with SSR.
  Imposes its update/view architecture on the whole app; interactivity here
  is Alpine's job, not a PS VDOM's.
- **Deku** — FRP UI framework; a different programming model entirely.

## Decision

A closed sum type (`Doctype | Element | Text | Fragment | Empty`) with
`render :: Html -> String`. Escaping is structural: `text` escapes in normal
HTML content, while `<script>` and `<style>` use the HTML specification's
unescaped-text context. `doctype` is the only way to emit a document type
declaration. There is no general-purpose unescaped HTML constructor.

Inline SVG is built with the same `el` tree as the rest of the document.
JSON-LD remains domain-escaped before entering a script element
(`escapeJson`, including `\\u003c` for `<`).

## Consequences

- The module is auditable in one read — the point, for a starter.
- The former general-purpose escape hatch is gone; the gate and ContractSpec
  reject `raw`/`Raw` source words entirely.
- No component model, no VDOM, no hydration: the SSR/Alpine split stays clean.
- The streaming shell still concatenates controlled opening tags because a
  partial document cannot be represented by an auto-closing `el`; interpolated
  attribute values are escaped explicitly.
- Accepted cost: attribute strings aren't type-checked against tag names.
- Known perf ceiling: `escape` does sequential `replaceAll` passes.
  Correctness is fine; optimise only if SSR throughput demands it.
- Do not re-propose replacing this module without a new ADR addressing the
  evaluation above.
