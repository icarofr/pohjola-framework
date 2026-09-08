# 01: Bump Playwright past the TLS-verification-bypass CVE

**What to build:** `@playwright/test`/`playwright` currently pinned at 1.48.0,
which carries a high-severity advisory (GHSA-7mvr-c777-76hp: Playwright
downloads and installs browsers without verifying the authenticity of the
SSL certificate), fixed in >=1.55.1. Unlike the `tar` advisories flagged by
`make audit` (transitively forced by spago, no fix path available), this one
is a straightforward version bump with a real fix on the other side.

**Blocked by:** None (can start immediately)

**Status:** done (e2e-in-CI check unverifiable from here, see below)

- [x] `@playwright/test` and `playwright` bumped to 1.63.0 (latest, past >=1.55.1) in `package.json` and `bun.lock`
- [x] `bun audit` (`make audit`) no longer lists the Playwright advisory — only the unfixable `tar` advisories remain
- [x] `make check` passes (build, gate, 244/244 tests, format)
- [ ] e2e suite (`bun run test:e2e`) still passes in CI at the new version — cannot verify from this sandboxed dev environment (Playwright's test runner hangs here regardless of version, a confirmed unrelated environment issue — see the diagnosis in `docs/audits/agent-stack-deep-audit-report_results.md`'s addendum). `playwright --version` works fine at 1.63.0. Needs a human/CI check of the next GitHub Actions e2e job run.
- [x] Checked `e2e/*.spec.js` and `playwright.config.js` for deprecated/removed APIs across the 1.48->1.63 jump: only standard `defineConfig`/`test`/`expect`/`devices`/`AxeBuilder` usage, no `waitForNavigation`, snapshot APIs, or other flagged patterns found. No changes needed.

## Comments

Done except the CI verification checkbox, which requires seeing an actual GitHub Actions run — flagging for the user/next session to confirm once pushed.
