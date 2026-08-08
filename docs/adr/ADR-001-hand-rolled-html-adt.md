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

A ~200-line closed sum type (`Element | Text | Raw | Fragment | Empty`) with
`render :: Html -> String`. Escaping by construction: `text` always escapes;
`raw` is the only bypass and is restricted to 5 allowlisted modules
(gate + ContractSpec filesystem scan).

## Consequences

- The module is auditable in one read — the point, for a starter.
- No component model, no VDOM, no hydration: the SSR/Alpine split stays clean.
- Accepted cost: attribute strings aren't type-checked against tag names.
- Known perf ceiling: `escape` does sequential `replaceAll` passes.
  Correctness is fine; optimise only if SSR throughput demands it.
- Do not re-propose replacing this module without a new ADR addressing the
  evaluation above.
