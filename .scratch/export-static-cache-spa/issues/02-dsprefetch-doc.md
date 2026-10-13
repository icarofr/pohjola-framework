Type: task
Status: resolved

## Question

`App.Datastar.dsPrefetch`'s entire reason to exist — the click reusing the hover-prefetch's HTTP cache entry — depends on `App.Server.patchCacheControl` (`private, max-age=180` + a matching ETag), computed only by the live server. Nothing at `dsPrefetch`'s own interface says so, and `App.Cli.ExportStatic` reuses the exact same chrome/nav markup on a static host with no such cooperation. Document the real dependency rather than leave it a silent, three-file trace.

## Blocked by

None (can start immediately)

## Answer

Added a doc comment directly on `dsPrefetch` naming the dependency explicitly (`App.Server.patchCacheControl`) and naming `App.Cli.ExportStatic` as the adapter that doesn't get it. Added a matching "Known, accepted gap" paragraph to `ExportStatic`'s own module doc, in the same style as its existing CSP-nonce-sharing gap.

Verified the gap is real, not hypothetical: curled a hover-prefetch-shaped request (`?datastar={}` + `datastar-request: true` header) against a real dumb static host (Python's `http.server`) and confirmed the response carries no `Cache-Control` or `ETag` at all — only `Last-Modified`. The prefetch still fires harmlessly there; it just warms nothing reusable.

No code behavior change — this was a documentation/interface-visibility fix, not a functional one. `make gate`/`make test` unaffected (doc-only diff in this file).
