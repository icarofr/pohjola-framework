# 02: Give the Alpine-contract sync chain one owned source of truth

**What to build:** `docs/conventions/alpine-contracts.md` currently says,
in plain language, "if you rename any of these, grep the whole repo:
`App.Alpine`, `Main.purs`, `Layout/Page.purs`, and the inline head scripts
all participate." Four files agree on strings like the fragment target id,
the `x-alpine-request` header name, and the `data-page-title`/`data-page-lang`/
`data-page-href-*` attribute names purely by convention, verified only by
`ContractSpec`'s string-literal assertions catching drift after the fact.

Collapse this into one module (extend `App.Alpine` or add a small sibling)
that exports these shared strings as named values. The other three
participants (`Main.purs`, `Layout/Page.purs`, the inline head-sync script in
`Layout/Scripts.purs`) reference that module's exports instead of
independent literals, so renaming one of these strings becomes a single-file
compiler-checked change instead of a repo-wide grep.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] Identify every shared string in the chain (fragment target id, AJAX
      header name, `data-page-*` attribute names, any others named in
      `docs/conventions/alpine-contracts.md`)
- [ ] Move them into one module as the single source of truth
- [ ] `Main.purs`, `Layout/Page.purs`, and `Layout/Scripts.purs` (or wherever
      the inline head-sync script lives) reference that module instead of
      restating the literals
- [ ] The inline JS head-sync script — which cannot `import` a PureScript
      module — sources its copy of these strings from the same PS-side
      constants at render/codegen time (not a second hand-typed copy)
- [ ] `docs/conventions/alpine-contracts.md` updated: replace the
      "grep the whole repo" instruction with a pointer to the new owning module
- [ ] `make gate` + `make test` pass; `ContractSpec`'s existing assertions
      still pass (now checking values derived from the shared module)
- [ ] No CSP, FFI, or Alpine seam widening (ADR-000 constructors only)
