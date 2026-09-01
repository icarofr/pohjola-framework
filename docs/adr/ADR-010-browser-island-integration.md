# ADR-010: Browser-island integration for browser-heavy features (proposal)

**Status:** Proposed — under discussion; **not accepted**
**Date:** 2026-08-11

> This is a discussion draft, not an accepted architectural decision. It does
> not authorize implementation, does not amend ADR-000/001/003, and does not
> change the current Alpine-only browser policy. Until this proposal is
> accepted or superseded, the existing accepted ADRs remain authoritative.

## Context

The starter is an SSR MPA:

```text
request → typed route → Page/Service → Html ADT → Bun response
```

Alpine provides small progressive-enhancement behaviours such as menus, theme
state, and fragment navigation. The server-rendered HTML remains meaningful
without JavaScript.

Some future features may contain browser-heavy regions that do not fit the
current Alpine seam. A Wordle-style statistics page is an example: Leaflet
maps, canvas word clouds, animation frames, timers, audio, resize observers,
and third-party browser libraries all require explicit mount and cleanup
lifecycle.

The current repository does not provide a generic client-rendering or islands
runtime. ADR-000 permits Alpine assets and tightly constrained seams only;
ADR-001 chose the server-rendered `Html` ADT over a client VDOM/hydration
framework; ADR-003 restricts FFI to reviewed modules and boundaries.

The question is how to accommodate one such feature without turning every page
into a client application or introducing an unreviewed browser framework.

## Problem statement

We need a future path for a feature that has:

- a meaningful server-rendered representation;
- browser-only behaviour in a bounded region;
- third-party or imperative browser APIs;
- explicit lifecycle and cleanup requirements;
- the existing server security, auth, routing, and testing guarantees.

The path must not make Alpine and a second client runtime mutate the same DOM,
must not require a global client store for unrelated pages, and must not allow
browser JavaScript to bypass the repository's FFI and escaping rules.

## Scope

This proposal concerns a **feature-owned browser island** inside the existing
SSR monolith. It does not propose:

- converting the whole application to an SPA;
- replacing `App.Html` for ordinary pages;
- adding a public JSON API or OpenAPI document;
- adding a generic island registry or hydration scheduler;
- choosing React, Deku, TEA, or another client runtime in advance;
- relaxing the server FFI allowlist;
- moving authentication tokens into browser storage.

## Options considered

### 1. Keep the feature entirely server-rendered

Render useful statistics, tables, SVG, and accessible fallbacks through the
existing `Html` ADT. Use Alpine only for small local behaviour.

This remains the default and should be attempted first. It has the smallest
maintenance surface and preserves no-JavaScript behaviour completely.

### 2. Add one feature-owned browser island

Render a useful fallback on the server and mount one client-owned root for
browser-heavy behaviour. The island may use an existing client library/runtime
or narrowly scoped browser FFI; the choice is deliberately left open.

This is the proposed future path when exact browser behaviour is a product
requirement. It is an islands architecture, but not a framework-wide islands
system.

### 3. Adopt a whole-application client runtime

Use a unified TEA, Deku, React, or similar client application for multiple
routes and shared browser state.

This is explicitly out of scope for this proposal. It becomes a separate
architectural decision only if several features demonstrate that isolated
islands create repeated coordination problems.

## Proposed constraints (under discussion)

If this proposal is accepted, the first island must satisfy the following.

### Stable server root

The server emits a stable root through the `Html` ADT:

```html
<main data-island="feature-name" data-island-version="1">
  <!-- useful SSR fallback -->
</main>
```

The marker, version, and fallback are part of the feature contract and are
tested. Arbitrary raw HTML is not permitted.

### Meaningful SSR fallback

The page must remain useful with JavaScript disabled. The fallback should
contain the important content, headings, labels, values, errors, and an
accessible representation of visual data where practical.

For a statistics page, this may be server-rendered summary data, an SVG map,
an HTML/SVG word representation, and native audio controls rather than empty
client placeholders.

### One feature-owned root

The first island owns exactly one root and all descendants. Alpine must not
own or mutate elements inside that root. The island must not be placed inside
an Alpine `x-target` subtree that can be replaced without lifecycle handling.

The first pilot should use one page-level island rather than one island per
visual component. The map, word cloud, timers, and audio can share a feature
bootstrap and lifecycle. Splitting them later requires independent state,
failure behaviour, lifecycle, and a measurable loading benefit.

### Explicit lifecycle

The feature entrypoint has the conceptual contract:

```text
mount(root, bootstrap) → dispose
```

Requirements:

- mount at most once per root;
- validate the root and bootstrap version;
- leave the SSR fallback visible if mount fails;
- make `dispose` idempotent;
- clear timers, animation frames, listeners, observers, requests, media, and
  third-party instances;
- prevent callbacks from updating a disposed root.

### Navigation

The proposed default is full-document navigation for a route containing a
browser island. This avoids making the existing Alpine fragment protocol
understand arbitrary client-runtime teardown.

If fragment navigation is later required, it must gain an explicit lifecycle
contract and tests for mount-before-swap, disposal, replacement, and remount.
An island must not rely on accidental DOM garbage collection.

### Bootstrap and transport

The browser receives a closed, versioned feature bootstrap type such as
`StatisticsBootstrapV1`. It must not receive secrets, API keys, or bearer
tokens.

The physical encoding is an implementation choice to be made per pilot:

- an escaped embedded data block;
- a same-origin bootstrap request;
- a form/URL representation;
- another reviewed codec.

Shared PureScript types and codecs may be used. A private same-repository
transport does not require OpenAPI. Whatever encoding is chosen must be
decoded at the browser boundary and covered by round-trip/invalid-input tests.

### Browser code and FFI

The application logic, state transitions, lifecycle, and feature decisions
remain in PureScript. Third-party browser libraries and low-level browser APIs
may be reached only through a separately reviewed browser adapter.

The adapter must expose semantic operations rather than leaking arbitrary DOM
or library calls throughout the feature, for example:

```text
mountMap(config, element) → cleanup
mountWordCloud(words, element) → cleanup
```

The current server FFI allowlist is not widened implicitly. A browser adapter,
library, dynamic import, map tile source, or asset pipeline requires a separate
review and an explicit update to the relevant ADR/gate/asset contract.

### Assets and security

- Browser bundles are public assets under `dist/`; server bundles remain under
  `dist-server/`.
- Third-party scripts are self-hosted and checksum-verified where permitted.
- Map tile and image origins require explicit CSP and privacy review.
- Browser code does not read authentication tokens from `localStorage`.
- Personalized statistics are fetched through the server auth/session boundary
  and are not inserted into a shared public cache.
- Raw popup HTML, `innerHTML`, and general-purpose HTML escape hatches remain
  prohibited.

## Proposed feature shape

The first candidate should preserve the normal server feature structure:

```text
src/App/Features/Statistics/
  Types.purs
  Service.purs
  Page.purs
  View.purs
  Components/
  Browser/             # only if exact interaction is approved
    Main.purs
    Effects.purs
    Map.purs
    WordCloud.purs
```

`Types`, `Service`, `Page`, `View`, and server components remain governed by
the existing conventions. `Browser/` is a feature-local client seam, not a
new application-wide architecture.

## Implementation sequence if accepted

1. Port the feature's domain types, service, auth, errors, and pure metrics.
2. Render a complete useful SSR page with typed fallbacks and no browser
    library dependencies.
3. Add pure tests for distance, dates, word weighting, decoding, and localized
    output.
4. Prototype the exact browser behaviour behind one feature-owned root only if
    the fallback is insufficient.
5. Add the browser adapter, asset/CSP review, bootstrap codec, mount/dispose
    tests, and browser integration tests.
6. Measure bundle cost, mount time, failures, and disposal behaviour before
    considering a second island.

## Verification requirements

The pilot must add or update:

- SSR tests for every language in `allLangs` and fallback content;
- root/version marker assertions;
- bootstrap escaping and invalid-version tests;
- auth, cache, and upstream-failure integration tests;
- no-JavaScript browser coverage;
- mount-once and dispose-once browser tests;
- navigation/back-forward lifecycle tests;
- asset checksum and CSP assertions;
- FFI and forbidden-HTML gates for the browser seam.

## Promotion criteria

Add another island only when it has:

- independent browser state;
- a real client-only behaviour;
- independent loading/failure/lifecycle needs;
- a useful SSR fallback;
- a measurable reason to load separately.

Consider a whole-application client runtime only when several routes require
shared browser state and the island contract is repeatedly producing
coordination or lifecycle bugs. That decision requires a new ADR or an
accepted amendment to this one.

## Open questions

This proposal intentionally leaves these undecided:

1. Should the first browser runtime be a feature-local imperative adapter, an
    existing PureScript client runtime, or a conventional client component
    bundle?
2. Should bootstrap data be embedded or fetched through a same-origin route?
3. Are map tiles and third-party visualization libraries acceptable under the
    project's privacy, CSP, and asset policy?
4. Should the first island route always use full-document navigation, or is a
    tested fragment lifecycle worth the added complexity?
5. Does the first candidate justify browser code at all after SVG/HTML fallback
    quality is evaluated?

## Consequences if accepted

Positive:

- browser-heavy features have a documented escape hatch;
- SSR, accessibility, and no-JavaScript behaviour remain defaults;
- client complexity is isolated to the feature that needs it;
- mount/dispose and ownership become explicit rather than accidental;
- no generic island framework is introduced prematurely.

Negative:

- the repository gains a second browser integration path in addition to
  Alpine;
- the first island requires additional build, asset, FFI, and browser tests;
- shared state between Alpine and an island is intentionally discouraged;
- a feature may need full-document navigation instead of the Alpine SPA-feel
  optimisation;
- current ADR-000/001/003 would need explicit amendments before code can ship.

## Decision

**Not decided.** This ADR remains under discussion. No island implementation,
browser FFI addition, CSP change, or amendment to the accepted ADRs follows
from this document until the open questions are answered and this proposal is
explicitly accepted or replaced.
