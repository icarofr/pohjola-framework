# Static export: cache and SPA-feeling gaps

## Destination

Resolve the three findings from the 2026-10-13 `/improve-codebase-architecture` review of `App.Cli.ExportStatic` and the shell-router/prefetch machinery it reuses from the live server, focused on caching and the "SPA feeling" when there's no live server behind the exported site.

## Notes

- Execution in scope (overrides wayfinder's plan-don't-do default): the user's goal for this effort explicitly said execute and loop til fixed.
- Verify behaviorally, not just by compiling: this effort's whole point is a deployment-target-specific behavior gap, so `make gate`/`make test` passing is necessary but not sufficient — drove a real headless browser (raw `playwright-core`, per CLAUDE.md's sandbox constraint on `make test/e2e`) against both a genuinely dumb static host (Python's `http.server`, not Pohjola's own Bun server) and the live server, to actually observe forward/back navigation.
- The report: `/tmp/architecture-review-20261013-114608.html` (this machine, may not survive a reboot).

## Decisions so far

- [restore() now branches on Content-Type, not a substring search](issues/01-restore-content-type-seam.md): the original fix attempt (treat "marker not found" as "whole body is the document") was wrong — the exported page's own inlined shell-router script contains the literal marker text as source code, so naive `indexOf` found a false positive and corrupted the parse. Fixed properly using `Content-Type: text/event-stream` vs `text/html`, matching how Datastar's own client already distinguishes the two. Verified with real browser automation against both deployment targets.
- [dsPrefetch's cache-cooperation dependency documented](issues/02-dsprefetch-doc.md): named the live-server-only dependency at the interface and in ExportStatic's module doc; confirmed via a real request against a dumb static host that no Cache-Control/ETag is present at all.
- [robots.txt's no-store gap documented](issues/03-robots-no-store-doc.md): named as a third "known, accepted gap" in ExportStatic's module doc, matching its existing CSP-nonce-gap precedent.

## Not yet specified

(none)

## Out of scope

(none)
