# ADR-014: Defer I18n splits, package splits, and Alpine CSP build

**Status:** Accepted (deferral)

## Decision
- Keep Data.I18n as one Dictionary until a private-fork merge conflict forces a split.
- Keep a single package (template copy + git upstream). No Spago split this quarter.
- Keep script-src unsafe-eval while Alpine’s standard build uses new Function (ADR-000 addendum). A CSP-build spike is allowed only as a future ADR that does not land as a silent ContractSpec change.

## Consequences
Head-sync and chrome copy already derive from allLangs / dict (Tasks 6). That is the 10×-language mitigation for this quarter.
