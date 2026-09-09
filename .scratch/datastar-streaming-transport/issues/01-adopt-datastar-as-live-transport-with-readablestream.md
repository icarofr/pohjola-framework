# 01: Adopt Datastar as a complementary live/streaming transport, backed by Bun ReadableStream

**What to build:** Add Datastar (SSE-driven hypermedia) as a second, narrowly-scoped
client runtime alongside Alpine + Alpine AJAX — Alpine AJAX keeps owning shell
navigation everywhere; Datastar owns one bounded, feature-owned region that needs
live/streaming updates (multi-target patches, server-pushed state) that Alpine
AJAX's single-target shell-swap model cannot do. Server-side, wire
`App.Server.streamResponse` (currently built — `App.ServerBun.streamResponseImpl`
exists, has zero call sites — see `docs/conventions/server.md`) to emit
`text/event-stream` framing for whatever route hosts the island.

This is filed because the user asked for it directly, not because a concrete
need has been identified yet — see Comments for the full reasoning trail. Read
this ticket as "here is the shape of the work," not "this is ready to build."

**Blocked by:** None (can start immediately) — but see the prerequisites below;
none of them are implementation work an agent can just do.

**Status:** ready-for-human

- [ ] **Name a real candidate feature.** `ADR-010`'s own example is a
      Wordle-style live-statistics page. Nothing in the current tree (`Home`,
      `About`, `Guarantees`, `Docs` — all static) has a live/real-time need.
      Without one, this ticket has no route to attach to and no way to write a
      meaningful acceptance test.
- [ ] **Formally accept or amend `ADR-010`** (`docs/adr/ADR-010-browser-island-integration.md`,
      currently **"Proposed — not accepted. Do not implement."**) naming
      Datastar specifically as the answer to its open question #1 ("Should the
      first browser runtime be a feature-local imperative adapter, an existing
      PureScript client runtime, or a conventional client component bundle?").
      This is a human architectural decision, not something to default into.
- [ ] **Amend or extend `ADR-011`** (`docs/adr/ADR-011-alpine-ajax-frozen-transport.md`)
      to record that Datastar, not HTMX, was chosen for the "in-page hypermedia
      beyond shell nav" case its own spike criterion names — the ADR currently
      only evaluated HTMX and Datastar as *alternatives to* Alpine AJAX for nav,
      never as a complement scoped to one island.
- [ ] **CSP/asset review** for a self-hosted, checksummed Datastar bundle,
      matching how `alpine-ajax.min.js`/`alpinejs.min.js` are vendored today
      (`ADR-000`'s "no unreviewed browser framework" constraint) — bundle-size
      line item in the same table shape `ADR-011` already uses.
- [ ] **Verify the SSE framing** Datastar's client expects lines up with what
      `streamResponseImpl`'s `ReadableStream` can actually emit from Bun — this
      is the one piece that's pure implementation, but only worth doing against
      a real feature's actual data shape, not speculatively.
- [ ] **Confirm the island contract** matches `ADR-010`'s proposed constraints
      (stable `data-island` root, meaningful no-JS SSR fallback, explicit
      mount/dispose lifecycle, Alpine must not mutate inside the island's root).

## Comments

Filed 2026-09-09 after a conversation that started with "do we use
ReadableStream?" (no — built, zero call sites) and worked through "should we
enable streaming," "should we adopt HTMX for multi-target updates," and
"should we complement Alpine AJAX with Datastar for live updates." Each step
surfaced that the framework's own docs had already thought about this:
`ADR-011`'s spike criterion names exactly the multi-target-update gap Alpine
AJAX has, and `ADR-010` already drafts the "second runtime, one island, do not
implement yet" shape this ticket describes — nobody had pulled the trigger on
either.

Recommended read on urgency: this is real, well-scoped future work, not a fix
for anything currently broken. Nothing in the live tree needs it today. Treat
the first checkbox (naming a real feature) as the actual frontier — the rest
falls into place once that exists.
