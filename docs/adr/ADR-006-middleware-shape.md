# ADR-006: Middleware shape – composition before Main

**Status:** Accepted
**Date:** 2026-08-04

## Context

The router lives in `src/App/Main.purs`. Cross‑cutting concerns are currently added inline – e.g. a `rateGate` check is hard‑coded in the request handler. As features grow, `Main.purs` risks becoming a mega‑module, and we need a clear seam for composable middleware before each app accumulates its own.

## Decision

* Define middleware as a function type:
  ```purescript
  type Middleware = Request -> (Request -> Aff Response) -> Aff Response
  ```
* All middleware modules reside under `src/App/Middleware/` (e.g. `RateLimit.purs`). They export a value of type `Middleware` and are imported by `Main.purs`.
* The router composes middleware via a simple left‑fold over a list of `Middleware` values, producing the final handler:
  ```purescript
  handler = foldl (flip apply) baseHandler middlewareList
  ```
  – No monad‑transformer stack; keep it plain and idiomatic.
* The order of `middlewareList` is explicit in `Main.purs`; document that order matters (e.g. rate‑limit before body parsing, logging outermost).
* Today we only **note** where future middleware will go; we do **not** refactor the existing `rateGate` into a middleware module yet – YAGNI until a second cross‑cutting concern appears.

## Consequences

* When a third cross‑cutting concern (e.g. tracing, auth) is needed, the shape is already agreed upon, making the migration straightforward.
* `Main.purs` stays readable; cross‑cutting logic is isolated in dedicated modules.
* No runtime impact today; the composition is a zero‑cost abstraction until additional middleware is added.
