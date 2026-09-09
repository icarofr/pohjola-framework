# 03: Full shell-nav port for Home and About

**What to build:** Every internal link on `Home` and `About` navigates via
Datastar with full parity to the current Alpine AJAX behavior: forward
navigation swaps `#content` and updates the URL via `pushState`; browser
back/forward correctly restores the previous page's content, title, and
`<html lang>`, matching `App.Layout.Scripts`' current `restore()`/`popstate`
logic; the page scrolls to top on every navigation (forward and restore),
matching this session's existing scroll-to-top fix; document title and
language sync after every swap, matching current `TitleSync` behavior.
Datastar itself provides no `pushState`/`popstate`-based navigation (its own
docs point toward plain `<a>` tags instead), so this is hand-written glue on
top of Datastar's `@get` action and patch mechanism, using Pohjola's own
existing `pageSyncScript` `restore()` logic as the starting reference.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] Clicking any internal link on `Home` or `About` swaps `#content` via Datastar and updates the URL
- [ ] Browser back restores the previous page's content, title, and `<html lang>` correctly
- [ ] Browser forward re-restores correctly after a back
- [ ] The page scrolls to top on every forward navigation and every back/forward restore
- [ ] Document title and `<html lang>` are correct after every swap
- [ ] A spike-local raw-playwright-core script verifies all of the above against both the Datastar version and the current Alpine version of the same two pages, side by side
- [ ] `make gate && make test` pass on the branch (existing Alpine-based `ContractSpec`/`ShellSpec` assertions remain green and unmodified)

## Comments

From `.scratch/datastar-streaming-transport/spec.md`, broken down via `/to-tickets`. Runs after 02; independent of 04 (local UI port) and can proceed in parallel with it. Both 03 and 04 block 05 (measure and report).
