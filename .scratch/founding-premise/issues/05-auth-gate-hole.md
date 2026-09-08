# 05: Close the mechanical gap that lets ad-hoc auth bypass the gate entirely

**What to build:** A real `Policy.Contract` check, or a decision that this risk is acceptable until ADR-002 ships.

Empirically verified (2026-09-08, working tree left clean afterward, no commits): `make gate`'s `isForbiddenAuthImport` check blocks importing `App.Auth.Scaffold` into `Main`/`Features` — exact failure: `"no forbidden auth imports in Main or Features"` names the offending file, e.g. `["src/App/Features/Contact/Page.purs"] ≠ []`. Clean, actionable, but the message never mentions ADR-002 or points anywhere to go instead.

But a from-scratch bypass — a feature file defining its own session type via `Effect.Ref (Map String String)` and manually parsing a `session=` cookie, **never importing `App.Auth` at all** — compiles clean and passes `make gate` 21/21, zero warnings. No hashing, no expiry, no `HttpOnly`/`SameSite`, a trivially guessable in-memory map, and nothing in the enforcement chain objects. This is exactly the "10 auth wrappers" drift pattern `ADR-002` exists to prevent, currently unenforced — the gate stops one specific known-bad import, not the general shape of "auth logic living outside `App.Auth`."

This matters regardless of ticket 03's answer (whether the private app needs auth today): the hole exists *right now*, for any fork, the moment an agent is asked to "add login" without being told to read ADR-002 first.

Two honest paths, not one right answer:

- **(a)** Add a real structural check: feature-view/feature-service files scanned for session/cookie/password-shaped primitives (a `Ref (Map ...)` holding a value read from a cookie header, `Bun.password`/hashing calls, anything with "session"/"auth"/"login" in a type or function name) outside `App.Auth`. Harder than the current substring scan — real risk of false positives (e.g. a legitimate non-auth `Ref (Map ...)` cache) — but closes the actual gap.
- **(b)** Accept the risk as acceptable for now: the gate already does the one cheap, zero-false-positive thing (block the known scaffold), and the real fix is implementing ADR-002 for real (ticket 03) rather than trying to out-scan every possible hand-rolled auth shape — a determined-enough agent can always route around a scan-based check (the same honest limitation `GUARANTEES.md` already admits for the Alpine attribute-name scan and the `el (` tag-concat hole).

Recommended: (b) as the near-term stance, but with one cheap addition regardless of which path: make the *existing* gate failure message actually name ADR-002 (`"see docs/adr/ADR-002-auth-shape.md — auth implementation is pending; do not hand-roll session logic"`), so the one path that IS caught gives a vibe-coding agent (or a human) an actual next step instead of a bare assertion failure. That's a five-minute fix independent of the bigger (a)/(b) decision.

**Blocked by:** None directly, but the (a)/(b) decision is easier once ticket 03 (auth urgency) is answered — if nothing is blocked yet, (b) is clearly fine for now; if something is blocked, (a) or just shipping ADR-002 for real becomes more urgent.

**Status:** resolved — closed by ticket 08 (2026-09-08)

- [x] Decision: neither (a) nor (b) as originally framed — **overtaken by real implementation.** Ticket 08 built the real `App.Auth` module the same day, which is the actual fix: the incentive to hand-roll ad-hoc auth mostly disappears once the correct, easy-to-use thing exists. The scan-based approach (a) was never built (still a real, if narrower, residual gap for the *specific* pattern of a fresh hand-rolled `Ref`-based session outside `App.Auth` — a determined agent could still do this; nothing scans for it). Accepted as (b)'s residual risk, consistent with the original recommendation.
- [x] The gate failure message fix (interim step, landed first) is superseded: the check it improved (`isForbiddenAuthImport`/`findForbiddenAuthImports`, which banned *all* `App.Auth` imports, not just the scaffold) has been removed entirely — it would now incorrectly block the real, correct usage ticket 08 built. See `test/Policy/Scan.purs`/`test/Policy/GateSpec.purs`.
- [ ] Not built, and not planned unless a concrete incident justifies it: a structural scan for hand-rolled session/cookie/password-shaped code outside `App.Auth`. Noted here for whoever revisits this if it ever becomes a real problem in practice.

## Comments

Closed as part of implementing ticket 08 (real `App.Auth`, Lucia pattern, per explicit user instruction "full lucia on auth, no compromises"). The empirical bypass this ticket documented is now moot in the sense that mattered — a real, easy-to-use, correct `App.Auth` module exists to import instead of hand-rolling.

## Comments

Found via an empirical test dispatched during the founding-premise grilling session, not via code review — the working tree was verified clean before and after, no commits made.
