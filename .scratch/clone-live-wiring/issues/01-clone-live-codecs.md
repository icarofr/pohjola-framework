Type: task
Status: resolved
Blocked by:

## Question

How should auto-scaffold discover codecs and languages so a unified `routeCodec lang` or a 2- vs 3-language Dictionary does not silent-no-op, and so the fixture asserts live shape rather than `codecCount < 3` / `inSitemap: true`?

## Answer

Clone the live files. `scripts/lib/wire-live-shape.js` discovers `allLangs`, every `routeCodec LANG = root $ prefix "xx"` clause, and a unified `routeCodec lang = root $ prefix (I18n.langTag lang)` clause, then inserts there. The fixture requires `codecCount >=` live clause count (1 if unified) and `i18nCount >=` `allLangs` length; it checks `isStatic` by regex instead of baking `inSitemap: true`. `canonicalRoute` and both `routeTitle` shapes are cloned when present.

Do not add marker comments or a CST parser unless this clone still silent-no-ops.

## Comments

Landed in Pohjola, Enora, and Vog. `make generator-policy` passed in all three working trees before push.
