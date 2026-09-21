## Destination

Feature wiring clones the live Route / I18n / Main / Head shape. A fork that unifies `routeCodec` or drops a language still wires and still fails the fixture for the right reason. Landed in Pohjola, Enora, and Vog; CI green on all three.

## Notes

Domain: Pohjola Feature wiring. Skills: codebase-design (clone-from-live, not a new port). Execution is in this map: the user asked for the fix in all autonomy, not a planning-only chart.

Do not introduce marker comments or a CST parser unless clone-from-live fails.

## Decisions so far

- [Clone live codecs and langs, not Enora-shaped regex](issues/01-clone-live-codecs.md): discover live `routeCodec` clauses and `allLangs`; fixture asserts those counts, not 2/3/`inSitemap: true`.

## Not yet specified

I18n `{ heading, body }` still duplicates Dictionary; left unless this landing exposes it.

## Out of scope

Hexagonal folder rewrite. Generating atelier-plates.js (ADR-015).
