# Framework hardening: closing the last "compiler is the contract" cracks

Source: `docs/audits/agent-stack-deep-audit-report_results.md` (Comparative
lens, Risk register, Prioritized recommendations) plus its addendum. Most of
that audit's findings are already fixed on `master`. This batch is the next
tranche toward state-of-the-art: real, scoped gaps the audit named but the
prior remediation passes didn't touch.

Explicitly out of scope for this batch: wiring the agent-in-the-loop evals
(01/02/03/06/07/10/11) into CI. Those require an actual agent completing the
task, not a deterministic check — this repo's posture is compiler-enforced
correctness, not probabilistic CI verification. Not a ticket; not planned.

## Tickets

- `01-bump-playwright.md` — close the one actually-fixable dependency CVE
- `02-alpine-contract-source-of-truth.md` — collapse the 4-file grep-discipline chain into one owned module
- `03-route-metadata-table.md` — collapse Route's six independent exhaustive dispatches into one table

None block each other — different files, no shared prerequisite.
