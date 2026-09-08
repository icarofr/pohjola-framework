# 01: Bump Playwright past the TLS-verification-bypass CVE

**What to build:** `@playwright/test`/`playwright` currently pinned at 1.48.0,
which carries a high-severity advisory (GHSA-7mvr-c777-76hp: Playwright
downloads and installs browsers without verifying the authenticity of the
SSL certificate), fixed in >=1.55.1. Unlike the `tar` advisories flagged by
`make audit` (transitively forced by spago, no fix path available), this one
is a straightforward version bump with a real fix on the other side.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] `@playwright/test` and `playwright` bumped to >=1.55.1 in `package.json` and `bun.lock`
- [ ] `bun audit` (`make audit`) no longer lists the Playwright advisory
- [ ] `make check` passes (build, gate, 244+ tests, format)
- [ ] e2e suite (`bun run test:e2e`) still passes in CI at the new version — this repo's sandboxed dev environment cannot run Playwright's test runner at all (a confirmed, unrelated environment issue — see the diagnosis in `docs/audits/agent-stack-deep-audit-report_results.md`'s addendum), so this must be verified via the GitHub Actions e2e job, not locally
- [ ] Check the Playwright 1.48 -> 1.55 changelog for breaking config/API changes that would affect `playwright.config.js` or the `e2e/*.spec.js` files, and adjust if needed
