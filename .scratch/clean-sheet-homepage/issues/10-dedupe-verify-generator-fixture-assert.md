# 10: Dedupe the inline assert-log-exit shape in `verify-generator-fixture.js`

**What to build:** `scripts/verify-generator-fixture.js` reimplements its own `assertIncludes(haystack, needle, label)` helper's check-log-exit shape inline for the two-needle Head-insertion check:

```js
if (!head.includes(...) && !head.includes(...)) {
  console.error(`Missing Head insertion (${name}): ...`);
  process.exit(1);
}
```

Add an `assertIncludesAny(haystack, needles, label)` helper next to the existing `assertIncludes` and use it here instead of the hand-rolled duplicate.

**Blocked by:** None (can start immediately)

**Status:** done (2026-09-09), commit `9fdd516` on branch `master`

- [x] `assertIncludesAny` exists alongside `assertIncludes` in `scripts/verify-generator-fixture.js`
- [x] The Head-insertion check uses it instead of the inline `if`/`console.error`/`process.exit`
- [x] `make gate` (which runs the generator fixture check) still passes

## Comments

Found by the Standards-axis code review of `dadcfe3..HEAD` (5 post-push commits on `master`, reviewed 2026-09-09). Judgement-call smell (Duplicated Code), not a hard standards violation.
