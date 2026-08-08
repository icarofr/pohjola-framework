<!-- Human-facing process doc — agents: skip unless explicitly asked to work on process/docs. -->

<!-- Human-facing process doc — agents: skip unless explicitly asked to work on process/docs. -->

# Changelog

Semver policy for this boilerplate:

- **Major** — breaking changes to the enforcement skeleton: a removed/weakened
  gate check, a ContractSpec assertion that changed meaning, a feature-pattern
  change that breaks existing features' shape. Forks must change their code.
- **Minor** — new stubs, new ADRs, new docs, additive test coverage.
- **Patch** — clarifications, typo fixes, wording. No behaviour change.

Per-version migration steps, when any, live in `docs/MIGRATION.md`.

## 1.0.0 — 2026-08

First release. The starter's shape is now a documented, enforced contract.

- SSR MPA starter: PureScript 0.15.16, Spago 1.0.4, Bun runtime, hand-rolled
  `Html` ADT, routing-duplex per-language codecs, Alpine.js AJAX navigation.
- Discipline system: compiler totality + Makefile gate (no `unsafe*`, no
  partial modules, no unallowlisted FFI/`raw`) + `ContractSpec` behavioural
  invariants + property tests + ADRs + `AGENT_CONTEXT.md` manifest + CI on
  every push.
- `docs/GUARANTEES.md` — 19-clause table, each clause linked to the check
  that enforces it; the runtime-safety claim is explicitly scoped (not
  "no runtime errors" in the absolute).
