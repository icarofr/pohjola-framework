Type: grilling

## Question

`scripts/auto-scaffold.js` wires a new feature into five files (`Data/Route.purs`, `App/Main.purs`, `Data/I18n.purs`, `App/Layout/Head.purs`, `App/DatastarShell.purs`) via ~30 hand-written regexes that assume each file's exact current text shape. That interface has no seam into the compiler's own understanding of those files, so a shape change elsewhere (e.g. a field removed from `RouteMeta`) can leave the generator's hardcoded templates stale until the next `make new-feature`/`generator-policy` run surfaces it as a build failure — as happened twice this session (`05591c8`, `cae1da3`).

Note: `make generator-policy` (part of `make ci-equivalent`/CI) already runs this fixture on every push, so this isn't an unguarded risk — it's a recurring maintenance cost paid reactively, in whatever session happens to touch one of the five files.

Decide: is this worth deepening (e.g. anchoring insertions on explicit marker comments in the five files instead of guessing at surrounding text, or a CST-aware insertion module), and if so, what's the right seam? Or is the current regex-plus-fixture-check combination an acceptable, already-mechanically-gated cost given how rarely these five files' shape actually changes?

## Blocked by

None (can start immediately)
