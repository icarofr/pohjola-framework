# Adding a language

Checklist for introducing a new `Lang` without touching fragment head-sync JavaScript.

1. **`Lang` ADT** — add the constructor in `Data.I18n`, extend `allLangs`, `langTag`, and `parseLang`.
2. **`routeCodec`** — add a branch in `Data.Route.routeCodec` (and any related URL helpers) for the new prefix.
3. **Dictionary** — add a full `dict` instance for every key the existing languages provide.
4. **`ogLocale`** — add a case in `App.Layout.Head.ogLocale` (e.g. `xx_YY`).
5. **No JS edits** — do **not** edit `App.Layout.Scripts.pageSyncScript`. Href/OG alternate sync is driven by `pageSyncAttrs` (`data-page-href-*` / `data-page-og-alts` from `allLangs`, plus `data-page-href-default` from `defaultLang`) and the generic `pageHref*` / `pageOgAlts` iterators in the TitleSync IIFE. `x-default` follows `defaultLang` (`data-page-href-default` → `pageHrefDefault`); do not hardcode `pageHrefEn`.

Chrome copy (nav home, etc.) comes from the dictionary (`d.nav.home`, …), not hardcoded shell helpers.

Verify with `make test` (ContractSpec pins one `data-page-href-*` per `allLangs`, `data-page-href-default` from `defaultLang`, and that the TitleSync script mentions `pageHrefDefault` / `pageOgAlts`).
