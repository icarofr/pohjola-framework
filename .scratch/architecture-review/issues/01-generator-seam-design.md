Type: grilling
Status: resolved

## Question

`scripts/auto-scaffold.js` wires a new feature into five files (`Data/Route.purs`, `App/Main.purs`, `Data/I18n.purs`, `App/Layout/Head.purs`, `App/DatastarShell.purs`) via ~30 hand-written regexes that assume each file's exact current text shape. That interface has no seam into the compiler's own understanding of those files, so a shape change elsewhere (e.g. a field removed from `RouteMeta`) can leave the generator's hardcoded templates stale until the next `make new-feature`/`generator-policy` run surfaces it as a build failure — as happened twice this session (`05591c8`, `cae1da3`).

Note: `make generator-policy` (part of `make ci-equivalent`/CI) already runs this fixture on every push, so this isn't an unguarded risk — it's a recurring maintenance cost paid reactively, in whatever session happens to touch one of the five files.

Decide: is this worth deepening (e.g. anchoring insertions on explicit marker comments in the five files instead of guessing at surrounding text, or a CST-aware insertion module), and if so, what's the right seam? Or is the current regex-plus-fixture-check combination an acceptable, already-mechanically-gated cost given how rarely these five files' shape actually changes?

## Blocked by

None (can start immediately)

## Answer

Neither full CST-parsing nor marker comments, once the actual failure was re-examined: both historical incidents (`05591c8`'s `RouteMeta.prefetch`, and the earlier `articleSlots` one) were never an anchoring/insertion-point problem — the regexes found the right place every time. The bug was that the generator wrote a **hardcoded literal record** (`{ isStatic: ..., inSitemap: true, prefetch: [ Home ] }`) that duplicates a shape declared by a real PureScript type (`RouteMeta`), so it silently drifted whenever that type's fields changed elsewhere.

Fix applied: `routeMeta`'s new-arm generation no longer writes a hardcoded template. It **clones the last existing arm's record text** and patches only the `isStatic` value. Since `RouteMeta` is a closed record, anyone who changes its shape must already update every existing arm to compile — so the last arm is always current by construction, and the clone inherits that for free. Also made the assumption itself fail loud: if the last arm has no `isStatic` field to patch, the generator throws immediately with a clear message instead of writing invalid PureScript for `spago build` to catch three files later.

Not done, and left as future work if it recurs elsewhere: the same "hardcoded literal duplicates a type's shape" risk likely exists in the I18n dictionary section templates too (`{ heading: "...", body: "..." }`) — not yet a confirmed bug, so left alone rather than speculatively rewritten.

Verified: ran `make new-feature NAME=WayfinderTestFixture TYPE=static WIRE=1` against the real repo (the `/tmp` fixture copy `generator-policy` uses can't execute in this sandbox — `/tmp` is mounted `noexec` here, unrelated to this fix) — `routeMeta`'s generated arm read `WayfinderTestFixture -> { isStatic: true, inSitemap: true }`, correctly cloned. Build succeeded with zero errors. Reverted the scaffolded fixture files afterward. Commit: (see map.md).
