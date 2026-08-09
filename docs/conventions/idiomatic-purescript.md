# Idiomatic PureScript — FP lessons for this codebase

The project docs cover architecture and runtime safety. This doc fills the
gap: general FP idioms that keep PureScript code clean and correct. Drawn
from the two reference books (`research/book.txt`, `research/purescript-book/`).
Every rule here would have prevented a real bug or review finding in this repo.

## Errors and effects

- **Errors are values (`Either` / `AppError`), never thrown.** `throw` across
  the FFI boundary is the one exception — caught by `makeFetch` or `attempt`.
- **`ExceptT` for composable error flows.** When a function chains multiple
  `Aff (Either e a)` steps, write it in `ExceptT e Aff a` and `runExceptT` at
  the end. Linear `do` notation beats nested `case … of Left → …; Right → …`
  staircases. Reference: `App.Migration.migrate`.
- **Lift `Either` into `ExceptT` with a helper, not inline `either`.** Define
  `liftEither :: Aff (Either e a) -> ExceptT e Aff a` once; `lift m >>= either throwError pure`
  repeated 5× is a smell. Reference: `App.Migration.liftEither`/`liftSql`.
- **`Effect` for sync side-effects, `Aff` for async.** `Bun.file().exists()`
  is `Effect Boolean`; `Bun.file().text()` is `Aff`. Don't fake async with
  `Effect` + callbacks.
- **`bracket` for every acquired resource.** `bracket acquire release use`
  guarantees release on failure. A bare `acquire; …; release` leaks on throw.
  Reference: `App.Migration.migrate` wraps `connect`/`close`.

## Traversable and folds

- **`traverse_` / `traverse` in `ExceptT` short-circuits effects on first
  error.** `for xs f` then `sequence` runs **all** effects then short-circuits
  the **value** — a failed step 3 still runs steps 4/5/6. This corrupted
  schemas before we caught it. Use `traverse_ (runSingleMigration sql) pending`.
- **Prefer `foldl`/`foldr`/`foldMap` over explicit recursion.** If a function
  is "process a list with an accumulator", it's a fold. Name the fold, don't
  hand-roll recursion.
- **`sequence` turns `t (m a)` into `m (t a)`; `traverse` is `map` + `sequence`.**
  Don't `map f xs` then `sequence` when `traverse f xs` says it in one word.
- **`Data.Array.find` over `filter … head`.** `find` short-circuits; the
  filter version scans the whole array then throws away the work.

## Types and modeling

- **`newtype` for domain distinctions over raw `String`/`Int`.** Zero runtime
  cost, compile-time safety. `EmailAddress` not `String`; `MigrationId` not
  `Int`. The tell: two values of the same primitive type that must never mix.
- **Smart constructors hide data constructors.** Export `mkEmailAddress ::
  String -> Maybe EmailAddress`, not the `EmailAddress` constructor. Illegal
  states become unrepresentable at the type level.
- **Closed ADTs for known sums; exhaustive pattern match.** `AppError`,
  `FormStatus`, `Html` are closed sums — adding a variant breaks every
  handler until updated. `make gate` enforces exhaustiveness.
- **Derive `Eq`/`Ord`/`Show` when free.** `derive instance eqX :: Eq X` costs
  nothing and enables test assertions. Don't hand-write what the compiler
  derives — except for learning (see `docs/examples/`).
- **`Maybe` for absence, `Either` for failure with a reason.** `Nothing` is
  "no value"; `Left err` is "here's what went wrong". Don't collapse them —
  `readTextFile` returning `Maybe String` hid whether the file was missing
  or unreadable.

## Pattern matching and control flow

- **One `case` returning a record beats three `case`s on the same scrutinee.**
  Pattern-match once, bind all fields. Three separate cases on
  `finalResponse.body` is a smell — they can drift out of sync.
- **Guards (`| cond = …`) over nested `if then else`.** A row of guards reads
  like a truth table; nested `if` reads like a maze.
- **Array comprehensions over nested `foldl` with shadowed accumulators.**
  `[ Tuple k v | l <- langs, r <- routes ]` beats
  `foldl (\acc l -> foldl (\acc' r -> …) acc …) …`.

## FFI seam

- **Callback double-application: `onSuccess(result)()`, not `onSuccess(result)`.**
  PS `Effect a` is `() -> a` at runtime; a PS callback returns a thunk that
  must be applied to `()`. Single application hangs `makeAff` silently — no
  error, no crash. See `docs/ffi-taming-guide.md` Step 2.
- **`makeAff` for callback-based JS; `Canceler` when abort is meaningful.**
  `App.Data.Fetch` is the reference: `makeAff` + real `Canceler` (AbortController).
  `pure mempty` as canceler is fine for local disk reads.
- **Keep JS to plumbing.** No `if` about behaviour, no decisions. The PS side
  decides; JS calls library functions and returns primitives.

## Anti-patterns

- **Staircase of `case`** — three or more nested `case … of Left → pure (Left
  …); Right → …`. The tell: indentation drifts right. The fix: `ExceptT` +
  `liftEither`, `runExceptT` once at the end.
- **Run-then-sequence** — `for xs f` followed by `case sequence results of …`
  inside `ExceptT`. The tell: effects run after the failure point. The fix:
  `traverse_ f xs` — `throwError` short-circuits effects.
- **Unguarded acquire** — `res <- acquire; …; release res` without `bracket`.
  The tell: `release` is the last line of the happy path. The fix: `bracket
  acquire release \res -> …`.
- **Identity wrapper** — `f = fImpl` with no type lifting or naming benefit.
  The tell: the wrapper adds a line and does nothing. The fix: drop it, or
  make it earn its keep (lift `Nullable` → `Maybe`, rename for clarity).
- **Boolean blindness** — a `Boolean` that means "is the user logged in" with
  no type. The tell: callers can't tell what `true` means without context.
  The fix: `newtype Authenticated = Authenticated User`, or a sum
  `Authed User | Guest`.
