# 05: Measure the real bundle delta and report findings

**What to build:** With both the shell-nav port (03) and local-UI port (04)
complete, produce a real measurement in place of every estimate this spike
was built to test: run an actual `make build` on the branch and record the
real gzip size of whatever ships under `dist/assets/js/`, compared against
the conversation's estimated range (12,738–15,935 B, versus today's measured
20,437 B). Run the full parity checklist from tickets 03 and 04 one more
time, end to end, comparing the Datastar-powered `Home`/`About` against
their unmodified Alpine versions on the same branch. Load the Datastar
pages under Pohjola's current pinned CSP and record whether anything is
blocked (expression evaluation in particular — the same reason Alpine needs
`unsafe-eval` today). Write all three findings up in one place, with a clear
go/no-go recommendation on whether this becomes a real production migration
ticket.

**Blocked by:** 03, 04

**Status:** ready-for-agent

- [ ] Real gzip bundle size measured from an actual `make build`, recorded against the estimated range
- [ ] Full parity checklist (shell-nav + local UI, from tickets 03/04) re-run and passing, Datastar version vs. Alpine version, both pages
- [ ] CSP check performed against the Datastar-powered pages; any blocked behavior (especially expression evaluation) recorded
- [ ] Findings written up in one document (bundle delta, parity results, CSP results, go/no-go recommendation) — placed in this feature directory, e.g. `findings.md`
- [ ] No changes made to `master`; the branch and its findings are left for a separate, later decision

## Comments

From `.scratch/datastar-streaming-transport/spec.md`, broken down via `/to-tickets`. Last ticket in the sequence — depends on both 03 and 04 landing first. This ticket's own output (the findings doc) is what determines whether a real production-migration ticket gets filed next, not this ticket itself.
