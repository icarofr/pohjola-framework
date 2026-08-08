<!-- Human-facing process doc — agents: skip unless explicitly asked to work on process/docs. -->

<!-- Human-facing process doc — agents: skip unless explicitly asked to work on process/docs. -->

# Quarterly Convention Review

**Purpose: tests encode what you thought of; this review catches what you
didn't.** ContractSpec, the gate, and property tests are the enforced layer;
this is the human layer above it.

## Cadence

- **30 minutes**, once per quarter.
- **60 minutes** after a quarter with heavy feature work.
- If a review runs **>90 minutes**, tighten the cadence (quarterly is too
  loose for the current rate of change).

## Inputs (gather before the session)

- `git log --stat` since the last review — what actually changed
- 20 largest `.purs` files:
  `find src -name '*.purs' | xargs wc -l | sort -rn | head -20`
- `docs/adr/` listing — decision set drift
- Gate sanity: `make gate` — does it still fire, and on the right things?
- Tail of `spago test` — what the suite asserts today
- Module headers of new files — conventions declared on arrival

## Outputs

Every review must produce at least one of:

- New `ContractSpec` assertions (patterns seen in 2+ files, promoted to enforced)
- New ADRs (decisions made implicitly during the quarter, now recorded)
- New stubs for foreseeable domains (auth/persistence/search/real-time — stub
  before the first request forces a shape)
- `AGENTS.md` / `AGENT_CONTEXT.md` updates (convention docs that drifted from code)
- `HANDOFF.md` update (current state as of the review)

## Off-cycle triggers

Run a review early when any of these lands:

- **A new domain lands** (auth, persistence, search, real-time) — review the
  FIRST implementation before it becomes the template.
- **A production bug** — review the convention that should have caught it,
  then fix the convention, not just the bug.
- **A refactor touching `App.Server`, `App.Html`, `App.Form`, or `App.Error`**
  — these are the enforcement-critical seams; every other convention hangs
  off them.

## Agent-assist

The diff-reading is delegable; the judgment is not. Have an agent produce the
raw findings with this prompt (verbatim), then review its output yourself:

> You are reviewing a PureScript codebase for convention drift. Read: git log --stat since {date}; all new files under src/App/Features/; all changes to src/App/Server.purs, App/Html.purs, App/Form.purs, App/Error.purs; docs/adr/; test/ContractSpec.purs. Identify: (1) new patterns in 2+ files not in ContractSpec/AGENTS.md; (2) existing conventions being violated; (3) architectural decisions made without an ADR; (4) modules growing beyond 300 lines. Output proposed ContractSpec assertions (as code), ADRs (as markdown), AGENTS.md updates (as diff). Do not implement. Propose only.

## Humans must

- Accept or reject proposed ADRs
- Decide on new stubs (don't auto-approve; a stub is a commitment)
- Approve `ContractSpec` additions (they become build-failing enforcement)
- Do off-cycle reviews when a new domain lands — the first implementation
  becomes the template everyone copies
