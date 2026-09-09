# 02: Scaffold the Datastar spike branch and prove the wire protocol works

**What to build:** A disposable branch where Datastar (free/core tier only)
is vendored and checksummed the same way `alpinejs.min.js`/`alpine-ajax.min.js`
are today, a new `App.Datastar` PureScript module exists with typed
constructors (mirroring `App.Alpine`'s shape — no raw attribute strings at
call sites), and a mechanical gate rule (`no raw Datastar strings outside
App.Datastar`) enforces that. On the server, a new response-encoding path —
built on the already-existing `App.Server.streamResponse` /
`App.ServerBun.streamResponseImpl` (currently zero call sites) — wraps a
rendered fragment in Datastar's `datastar-patch-elements` SSE framing when
the incoming request is a Datastar action call. This detection must be a new
signal, entirely separate from the existing `isFragmentRequest`
(`x-alpine-request` header / `?_frag=1`), which stays untouched for every
page that remains on Alpine. One real link on `Home` proves the whole pipe
end-to-end: click it, the server detects the Datastar request, encodes the
fragment as an SSE patch, and Datastar's client applies it to `#content`.
Full navigation (every link, `pushState`, `popstate`, title sync,
scroll-to-top) is NOT in this ticket — that's ticket 03.

**Blocked by:** None (can start immediately)

**Status:** done (2026-09-09), commit history on branch `spike/datastar-shell-nav-port` (see findings.md)

- [x] Datastar (free/core, no Pro attributes) vendored under `static/assets/js/`, self-hosted and checksummed like the existing Alpine assets
- [x] `App.Datastar` module exists with at least the constructors this spike's first working patch needs
- [x] Gate rule added: no raw Datastar attribute strings appear outside `App.Datastar`
- [x] A new, separate "is this a Datastar request" detection signal exists on the server, independent of `isFragmentRequest`
- [x] The existing `isFragmentRequest`/`x-alpine-request`/`?_frag=1` contract is unchanged and still passes `make gate && make test`
- [x] One real link on `Home` triggers a full round trip: click -> Datastar request detected -> fragment wrapped in `datastar-patch-elements` SSE framing -> Datastar client patches `#content` -> verified via a spike-local raw-playwright-core script
- [x] `make gate && make test` pass on the branch

## Comments

From `.scratch/datastar-streaming-transport/spec.md` (published via `/to-spec`), broken down via `/to-tickets`. First of four tickets; 03 and 04 both depend on this one and can run in parallel once it lands.
