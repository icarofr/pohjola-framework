# ADR-014: Defer I18n splits, package splits, and a CSP-safe build

**Status:** Accepted (deferral) — the Alpine-specific framing below is moot since ADR-015 removed Alpine entirely; the unsafe-eval deferral itself carries over to Datastar unchanged (Datastar's expression evaluation has the same new-Function requirement — see ADR-000's Datastar addendum)

## Decision
- Keep Data.I18n as one Dictionary until a private-fork merge conflict forces a split.
- Keep a single package (template copy + git upstream). No Spago split this quarter.
- Keep script-src unsafe-eval while Datastar's expression evaluation uses new Function (ADR-000 addendum). A CSP-safe-build spike is allowed only as a future ADR that does not land as a silent ContractSpec change — no such build has been evaluated for Datastar, unlike Alpine's now-moot `@alpinejs/csp` variant this ADR originally deferred against.

## Consequences
Head-sync and chrome copy already derive from allLangs / dict (Tasks 6). That is the 10×-language mitigation for this quarter.
