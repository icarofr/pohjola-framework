# Posts are English-only in a trilingual site

Every other page (Home, About, Contact, Fixtures, all chrome) is fully
localized via `Data.I18n`'s `Dictionary` (En/Fr/Pt). Blog posts are not:
`posts` has no language dimension at all, and `App.Features.Posts.Service`'s
queries never filter by `Lang` even though `Lang` is already threaded
through the call site (`Posts.Page.renderList`/`renderDetail` both take
`Lang` as a parameter today — it's just never passed to `fetchPosts`/
`fetchPost`). Every visitor sees the same English post content regardless
of which language they've selected.

Separately: the seed post text itself repeated the same unverified
performance claims ("sub-millisecond", "zero runtime exceptions") the
README/website truthfulness pass just fixed elsewhere. Post 1's English
text below is already the corrected version — use it as the translation
source, not the original migration content.

Requires a real Postgres connection this session doesn't have (`DATABASE_URL`
unset here, no live DB available). One ticket, for whoever has prod access.

## Ticket

1. `01-trilingual-posts.md` — schema + wiring + all translated content
