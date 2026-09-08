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

**Status:** done

- [x] Identify every shared string in the chain — turned out `Main.purs`/
      `Layout/Page.purs` don't independently duplicate these (they go through
      `SiteShell`, which already imported `contentTarget`); the real
      duplication was `data-page-*` attribute-name literals in
      `SiteShell.purs`/`Head.purs`, plus the inline JS's hand-typed copies
      of `'content'` (x2) and `'data-page-title'` (x1)
- [x] Added `dataPageTitleAttr`, `dataPageLangAttr`, `dataPageDescriptionAttr`,
      `dataPageOgLocaleAttr`, `dataPageOgAltsAttr`, `dataPageHrefPrefix` to
      `App.Alpine`, next to the existing `contentTarget`/`alpineRequestHeader`
- [x] `SiteShell.purs` and `Head.purs`'s `pageSyncAttrs` reference these
      instead of restating the literals
- [x] The inline JS head-sync script in `Layout/Scripts.purs` now
      interpolates `contentTarget`/`dataPageTitleAttr` via `<>` at the 3
      call sites that previously hand-typed `'content'`/`'data-page-title'`
      — confirmed byte-identical rendered output via a live `curl` diff
      before/after
- [x] `docs/conventions/alpine-contracts.md` updated: replaced "grep the
      whole repo" with a pointer to the `App.Alpine` constants and an
      explicit note that the JS `dataset` camelCase names are the DOM's own
      spec-defined mapping, not a second hand-typed copy
- [x] `make gate` + `make test` (244/244) + `make eval-repo-law` (5/5) pass;
      `ContractSpec`'s existing literal assertions (`data-page-title`,
      `pageHrefDefault`, etc.) still pass unchanged
- [x] No CSP, FFI, or Alpine seam widening — only `App.Alpine`'s existing
      "plain String constant" pattern extended, no new constructors, no CSP
      hash pinning affected (CSP here is nonce-based, not content-hashed)
