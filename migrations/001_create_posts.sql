-- Migration: create_posts
-- Schema for blog posts / engineering notes with seeded content

CREATE TABLE IF NOT EXISTS posts (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL DEFAULT 1,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed initial curated posts
INSERT INTO posts (id, user_id, title, body) VALUES
(1, 1, 'Why Functional SSR on Bun Matters', 'Building web applications with PureScript and Bun combines compile-time totality with sub-millisecond execution.

Unlike traditional Node.js runtimes that carry heavy startup and module resolution overhead, Bun serves pre-rendered HTML in under a millisecond. Paired with PureScript''s closed algebraic HTML data type, views are rendered as pure values, eliminating runtime exceptions and guaranteeing XSS safety before a single byte touches the wire.'),
(2, 1, 'Eliminating the Hydration Cliff with Alpine.js', 'Single-page application frameworks require downloading megabytes of client JavaScript just to re-render markup that the server already produced.

Pohjola eliminates the hydration cliff by coupling server-rendered HTML with Alpine.js morphing. Hovering over a navigation link pre-fetches the target HTML fragment in the background. On click, Alpine swaps the content container instantaneously, delivering SPA speed with zero client state drift.'),
(3, 1, 'Hypermedia as the Engine of Application State (HATEOAS)', 'Why replicate complex state machines and API schemas across client and server when hypermedia already solves distributed state?

In Pohjola, application state transitions are driven by hypermedia representations. The server emits semantic HTML where available actions, disabled controls, and navigation links reflect the exact server resource state. Paired with PureScript''s closed algebraic Html ADT and Alpine AJAX fragment morphing, HATEOAS delivers fluid, reactive client experiences with total compile-time guarantees.'),
(4, 1, 'Total Type Safety Across HTTP and HTML', 'In conventional frameworks, routing, API payloads, and HTML generation exist across loose string boundaries where typos and breaking changes hide.

In Pohjola, routes are bidirectional codecs verified by routing-duplex. HTML is constructed through algebraic constructors rather than string templates. If a route or translation key changes, the compiler immediately rejects any broken references across the entire codebase.'),
(5, 1, 'Taming the Foreign Function Interface (FFI)', 'JavaScript interop is often the weakest link in statically typed web applications.

Pohjola enforces a strict FFI safety floor: all foreign JavaScript imports are restricted to four allowlisted modules. Every FFI boundary is wrapped in PureScript types, converting untrusted runtime errors into explicit Either values that must be handled at the call site.'),
(6, 1, 'Mechanical Guarantees and Zero-Drift for AI Pairs', 'Conventions rot; mechanical assertions endure.

Every commit in Pohjola is validated against byte-exact Content Security Policy nonces, closed HTML ADT rules, and feature isolation constraints. Running make gate and ContractSpec verifies architectural invariants in under two seconds. Because routes, translations, and domain effects are expressed through exhaustive types, AI coding agents and humans cannot introduce breaking changes or hallucinate missing handlers without triggering immediate compiler errors.')
ON CONFLICT (id) DO NOTHING;
