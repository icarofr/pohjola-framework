Type: grilling

## Question

`App.Layout.Page.renderErrorPage` (live: `App.Main:74`, `:146`) hand-builds its own `<head>`/`<body>` instead of composing through the canonical `renderDocumentExtraHead` seam. This isn't accidental duplication in the way `renderShellOpen`/`renderShellClose` was (that was dead and got deleted — see Decisions so far in `map.md`): `renderHead` requires a `Route` and renders a full SEO head (canonical link, hreflang alternates per `Data.Route.allLangs`, Open Graph, JSON-LD) that doesn't make sense for an arbitrary error status with no single canonical route.

Decide: is a second, deliberately-minimal document construction the right shape for "there is no Route to be canonical about," or should `renderDocumentExtraHead` grow a mode/parameter that lets a caller opt out of `renderHead`'s Route-dependent content — and if so, does that cheapen the interface for every other (non-error) caller, all of which do have a real Route?

## Blocked by

None (can start immediately)
