# Findings: Datastar shell-nav port spike

Branch: `spike/datastar-shell-nav-port`. Scope: `Home` + `About` only, full
Alpine → Datastar replacement (shell nav + theme/lang dropdowns + mobile
drawer), gated behind `?ds=1` so the unmodified Alpine version stays the
comparison baseline on the same branch. See `spec.md` for the full spec and
`issues/02`–`05` for the ticket breakdown this executed.

## Bundle size — real, measured

Measured from this branch's actual `make build` output (`dist/assets/js/`),
gzip — not estimated:

| File | Gzip |
|---|---|
| `alpinejs.min.js` (Alpine core) | 16,704 B |
| `alpine-ajax.min.js` (shell-nav plugin) | 3,733 B |
| **Alpine total (current production)** | **20,437 B** |
| `datastar.js` (free/core, v1.0.0-RC.7) | 12,374 B |

Confirmed via network trace (Playwright `request` events) that the
Datastar-transport page (`?ds=1`) loads **exactly one** JS file
(`datastar.js`) — no Alpine scripts fetched at all.

**Real result: 12,374 B vs 20,437 B — a 8,063 B (39.5%) reduction.**

This is better than the spec's estimated range (12,738–15,935 B, a
22–38% reduction) because the ported shell-router glue
(`dsShellRouterScript`) is inlined server-side HTML, not a separate
downloaded/cached JS asset — it adds a small amount of per-page HTML weight
(a few hundred bytes, uncompressed in this measurement) but zero separate
JS bundle cost. Trade-off worth naming: an inlined script can't be
browser-cached across page loads the way a separate file can; a production
version might reasonably extract it to its own small cached file instead,
which would add back a few hundred bytes to the "bundle" total but remove
it from every page's HTML payload.

## Parity checklist — all passing, verified via raw playwright-core

Every item checked against a live `make run` server, not just compiled:

- [x] Forward navigation (`Home` → `About`): `#content` swaps, URL updates
      via `pushState`, document title syncs, `<html lang>` syncs, page
      scrolls to top.
- [x] Browser back: restores `Home`'s content, title, and scroll-to-top —
      correctly, via the hand-rolled `popstate` handler (Datastar itself
      has no history awareness, confirmed against its own docs).
- [x] Browser forward (after back): re-restores `About` correctly.
- [x] Theme dropdown: opens, closes, "Dark" selection actually sets
      `data-theme="pohjola-dark"` on `<html>`.
- [x] Language dropdown: opens, shows all three languages.
- [x] Visual output: screenshots of both pages, both transports, are
      visually indistinguishable (same DaisyUI classes, same dark
      Level-2 header/footer, same active-nav-link emerald highlight).
- [x] Zero page errors (`pageerror` listener) across the full interaction
      sequence once the three bugs below were fixed.

## CSP — no change needed

Loaded both transport versions under the current pinned CSP
(`script-src 'nonce-...' 'self' 'unsafe-eval' 'strict-dynamic'`) and
listened for `securitypolicyviolation` events through the full interaction
sequence (nav, back, theme dropdown, theme selection, language dropdown):
**zero violations.** Datastar's expression evaluation works under the same
`unsafe-eval` the CSP already grants Alpine — no policy change required to
adopt Datastar, at least for what this spike exercises.

## Three real bugs, only found by actually running it

Compiling clean and passing unit tests caught none of these — all three
needed a live browser:

1. **`datastar.js` is an ES module** (`export function ...`), loaded via a
   classic `<script>` tag. It silently failed to parse. Every click fell
   back to native browser navigation (full reload, `?ds=1` lost from the
   URL, served the Alpine version) — which *looked* like it worked (the
   page did navigate, content did change) until the URL and title were
   checked closely. Fixed: `<script type="module">`.
2. **PureScript's own string escaping**: `'\n\n'` in the shell-router
   script's source, meant to be the literal two-character JS escape
   sequence for the SSE terminator split, was interpreted by PureScript
   itself into two real newline bytes — landing inside a JS single-quoted
   string and breaking the whole inline script with a hard parse error on
   every page load. Fixed: `'\\n\\n'`.
3. **Missing `Vary` header** (the one worth calling out for future work,
   not just a typo): `handleDatastarTransportPage`'s response carried no
   `Vary` header. The browser's own HTTP cache then served the *cached
   full-document response* to the `popstate`-restore fetch — same URL,
   different `Datastar-Request` header — instead of hitting the network.
   This is the exact bug class `Vary: x-alpine-request` already exists to
   prevent on the Alpine side; it just wasn't carried over to the new path.
   Fixed by adding `Vary: datastar-request` to both the full-page and
   SSE-fragment responses.

All three are fixed on this branch and re-verified after each fix.

## Go / no-go recommendation

**Go, conditionally** — the technical result is genuinely good: real
bundle reduction, full behavioral parity, zero CSP friction, no hydration
risk (confirmed in conversation before this spike started: Datastar reads
`data-*` attributes off real SSR HTML in place, same category as Alpine,
not a VDOM/hydration framework). The three bugs found are exactly the kind
a real spike is supposed to surface, and none of them are fundamental —
all three are fixed.

What this spike does **not** resolve, and what a production migration
decision still needs:

- **No concrete feature drives this.** The four live pages are static
  marketing/doc content; nothing today needs Datastar's actual differentiator
  (multi-target updates, live/streamed state) — this spike only proves the
  *shell-nav replacement* works, which was always the cheaper, less
  interesting half of the original "state of the art" conversation.
- **Full production migration is a much larger blast radius than this
  spike touched.** Two pages, not four; no `Guarantees`/`Docs` port; no
  test-suite rewrite (the existing `ContractSpec`/`ShellSpec`/e2e suite
  all still assert Alpine's output, untouched, because `master`'s pages
  never left Alpine). A real migration means porting the other two pages,
  writing the equivalent test coverage, and deciding whether to keep the
  inlined shell-router script or extract it to a cached file (see the
  bundle-size trade-off above).
- **The pushed URL doesn't preserve `?ds=1`** — a real gap in this spike's
  own router glue, not touched because it's out of scope for a comparison
  toggle: a production version wouldn't have this problem at all (there'd
  be no toggle, just the real route), so it's not a blocker on the go/no-go
  call itself, just a reminder that this spike's own plumbing is
  spike-shaped, not production-shaped.

Recommendation: don't merge this branch. Keep it as evidence. If a real
feature need for Datastar's actual differentiator (ticket 01's scenario)
materializes, that's the moment to decide on a full migration — informed
by this spike's real numbers, not estimates.
