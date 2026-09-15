Type: grilling
Status: resolved

## Question

`App.Layout.Page.renderErrorPage` (live: `App.Main:74`, `:146`) hand-builds its own `<head>`/`<body>` instead of composing through the canonical `renderDocumentExtraHead` seam. This isn't accidental duplication in the way `renderShellOpen`/`renderShellClose` was (that was dead and got deleted — see Decisions so far in `map.md`): `renderHead` requires a `Route` and renders a full SEO head (canonical link, hreflang alternates per `Data.Route.allLangs`, Open Graph, JSON-LD) that doesn't make sense for an arbitrary error status with no single canonical route.

Decide: is a second, deliberately-minimal document construction the right shape for "there is no Route to be canonical about," or should `renderDocumentExtraHead` grow a mode/parameter that lets a caller opt out of `renderHead`'s Route-dependent content — and if so, does that cheapen the interface for every other (non-error) caller, all of which do have a real Route?

## Blocked by

None (can start immediately)

## Answer

Kept the two head *contents* separate — `renderErrorPage`'s minimal head is a legitimate, deliberate difference (no Route to be canonical/hreflang about), not a bug to dedupe away. Adding a mode-switch to `renderDocumentExtraHead` would have cheapened its interface for every other caller, all of which do have a real Route.

Instead extracted the shared *skeleton* both were independently rebuilding (doctype/html/head/body/scripts) into one `renderShell :: Lang -> String -> Html -> Html -> String`, taking head content and body content as plain `Html` values. `renderDocumentExtraHead` now computes `extraHead <> renderHead ...` and hands it to `renderShell`; `renderErrorPage` hands its minimal head. One seam knows what a Pohjola document IS structurally; the two callers only differ in content, which was always the correct difference.

Verified: `make gate` (19/19), `make test` (234/234), a live smoke test (200 on `/en`, 404 with correct title/single-doctype on an unknown route). Commit `373b471`.
