# Generators — scaffolding contract

## Scaffold a new feature

```bash
make new-feature NAME=Team                    # static page (default)
make new-feature NAME=Products TYPE=data      # data-backed page
make new-feature NAME=Team SLUG_FR=equipe     # custom FR slug
```

Creates `src/App/Features/<Name>/` with the right file split and prints the
manual edits needed for `Route.purs`, `Main.purs`, and `I18n/Dictionary.purs`.
The compiler guides you to every missing site.

## File layout

- **Data-backed**: `Types.purs`, `Service.purs`, `Page.purs`, `View.purs`
- **Static**: `Page.purs`, `View.purs`

ContractSpec enforces feature isolation — see `test/ContractSpec.purs`.

## Decision rule

- Presence of `Service.purs` ⇒ data-backed feature.
- Data-backed ⇒ `Types.purs` must exist.
- Example: `Posts/` (data-backed) vs `About/` (static).

## Routing

Add a constructor to `Data/Route.purs` and update both `routeCodec` branches.
Use `routeUrl`, `routeTitle`, `navItems`. Verify `Home`, `About`, `Contact`,
`Legal`, `PostList`, `PostDetail` patterns in the file.

## I18n entries

Add dictionary records for both `en` and `fr` in `Data.I18n.Dictionary`.
The `Dictionary` type requires each language to have identical keys —
missing entries cause a compile error.

## Checklist after scaffolding

- `make gate && spago build && make test` passes.
- No new cross-feature imports (ContractSpec isolation test).
- `make check` passes (lint + formatting).

**Done when**: `make check` is green and the feature renders at both
`/en/<route>` and `/fr/<route>`.
