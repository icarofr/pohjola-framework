<!-- Human-facing process doc — agents: skip unless explicitly asked to work on process/docs. -->

<!-- Human-facing process doc — agents: skip unless explicitly asked to work on process/docs. -->

# New App Setup

How to turn this boilerplate into an app. Follow in order. The gate, tests, and
ADRs are part of the deliverable — not the demo features they happen to cover.

## Checklist

1. **Clone, start fresh**: `git clone` (or copy), then
   `rm -rf .git && git init`. The boilerplate's history is not your app's.
2. **Update `spago.yaml`**: `package.name` → your app's name (`pohjola-framework` → yours).
3. **Update `Data.Content.siteInfo`** — title, description, email, socials.
   This is metadata only; no copy (see `Data.Content` module header).
4. **Update `Data.I18n`** — rewrite `en` and `fr`. The compiler enforces both
   stay in sync: one record type, a missing key in either is a compile error.
5. **Update `Data.Route`** — replace the demo routes with your app routes.
   Both language codecs (compiler enforces), `routeTitle`, `allRoutes` for the
   sitemap, `seoDescription` in `Head.purs`, then `pageRenderer` in `Main.purs`.
6. **Delete `src/App/Features/Posts/`** (the data-backed demo) — or keep it as
   your first template. It renders JSONPlaceholder data you don't own; don't
   ship it.
7. **Delete unneeded demo features** — About/Contact/Home/Legal are starter
   copy. Keep Contact if you ship forms (it's the static template).
8. **Update the Makefile** — `BASE_URL` (default `http://localhost:3000`) and
   `IMAGE_NAME` (default `localhost/pohjola-framework:latest`).
9. **Update `venom/*.yml` route assertions** — the routes, POST paths, and
   404/redirect expectations are demo-specific. Keep the *shapes* (security
   headers, `server.js` 404, honeypot silent success) — change the paths.
10. **Update `e2e/*.spec.js`** — navigation, i18n, theme, forms, no-js: every
    spec asserts demo routes and copy. Port the *behaviours* (JS-off parity,
    language toggle, dark mode) to your routes.
11. **Run `make check`** — gate + build + test + assets-check. It MUST PASS
    on the emptied app. This is the baseline invariant (backlog item #16):
    the skeleton enforces nothing about your routes, only that the discipline
    still runs. If `make check` fails before your first feature, you deleted
    enforcement, not content — find and fix it before adding anything.
12. **Write your first app-specific ADR** — before the first
    anything-architectural: persistence, auth, a second data feature. The
    ADR is how the next agent (or future you) learns *why*. See `docs/adr/`
    for the existing four and their shape.
13. **Update `docs/AGENT_CONTEXT.md`** — replace the boilerplate "always load"
    list with your app's core files (your `Data.*` and `App.*` modules), and
    keep the "What NOT to do" table pointing at *your* enforcement.
14. **First feature** — copy the Posts pattern (data-backed:
    `Types`/`Service`/`Page`/`View` + `App.Data.Fetch`) or the Contact pattern
    (static: `Page` + `View`). Never invent a third shape; if one is genuinely
    needed, write the ADR first (backlog #14).

## What you inherit

Forks inherit the **shapes** of the assertions, not their **content**:
the `ContractSpec` invariant that pages flow through `Layout.Page`, the gate
bans, the ADR discipline. The routes, copy, features, and tests you replace.
Keep the enforcement skeleton intact — it's the part that makes the next
feature safe to write fast.
