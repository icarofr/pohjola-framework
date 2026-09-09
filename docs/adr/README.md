# ADRs

| ADR | Title | Status |
|-----|-------|--------|
| [000](ADR-000-no-custom-browser-js.md) | No custom browser JS — Alpine only | Accepted (amended by 015: seam constructors now `App.Datastar`, not `App.Alpine`; CSP threat-model story updated) |
| [001](ADR-001-hand-rolled-html-adt.md) | Hand-rolled Html ADT | Accepted |
| [002](ADR-002-auth-shape.md) | Auth shape | Accepted — session lifecycle implemented; CSRF (ADR-005) still pending |
| [003](ADR-003-ffi-taming.md) | FFI taming | Accepted |
| [004](ADR-004-sessions.md) | Sessions | Accepted (superseded by 002's Amendment — different, incompatible shape; implemented) |
| [005](ADR-005-csrf.md) | CSRF | Accepted — decision amended to Lucia's header-based hierarchy (Sec-Fetch-Site/Origin, token demoted to optional legacy fallback); Sec-Fetch-Site check itself still pending |
| [006](ADR-006-middleware-shape.md) | Middleware shape | Accepted |
| [007](ADR-007-bun-serve.md) | Bun.serve | Accepted |
| [008](ADR-008-component-architecture.md) | Component architecture | Accepted (Layout amendment superseded by 012) |
| [009](ADR-009-bun-sql-data-layer.md) | Bun.sql data layer | Accepted — Phase 3A; 3B pending |
| [010](ADR-010-browser-island-integration.md) | Browser-island integration | Proposed — do not implement |
| [011](ADR-011-alpine-ajax-frozen-transport.md) | Alpine AJAX frozen transport | Superseded by 015 |
| [012](ADR-012-semantic-ui-contracts.md) | Semantic UI contracts | Accepted |
| [013](ADR-013-compiler-first-policy.md) | Compiler-first policy | Accepted |
| [014](ADR-014-deferred-splits-and-csp.md) | Defer I18n splits, package splits, and a CSP-safe build | Accepted (deferral) — Alpine-specific framing moot post-015 |
| [015](ADR-015-datastar-transport-migration.md) | Datastar transport migration | Accepted |
