# Agent Evals

Agent evals for Pohjola. Each eval is a prompt + assertion pair: a
user-shaped task in `PROMPT.md`, and checks in `check.sh` that verify the agent
followed our conventions.

Structural policy lives in `policy/manifest.json` and is enforced by
`make gate` (`scripts/verify-policy.sh`) and `Test.PolicySpec` (`make test`).
Eval `check.sh` scripts should delegate to those tiers instead of duplicating
grep rules.

The point: find places where agents get the conventions wrong, then fix it by
improving the docs in `docs/conventions/` and `docs/AGENT_CONTEXT.md`.

## How it works

Each eval is a directory under `evals/evals/`:

```
evals/evals/01-add-page/
├── PROMPT.md   # what you'd type into the agent (user-shaped, not "use X")
└── check.sh    # assertions — delegate to make gate/test when possible
```

The runner is `evals/run-eval.sh`. It shows the prompt, lets the agent work,
then runs the assertions:

```bash
# Show the prompt
make eval EVAL=01-add-page

# After implementing, run the checks
make eval EVAL=01-add-page --check
```

Or directly:

```bash
./evals/run-eval.sh 01-add-page          # show prompt
./evals/run-eval.sh 01-add-page --check  # run assertions
```

## Workflow

1. **Read the prompt.** `PROMPT.md` describes a user-facing task. Write it like
   a real user would: describe the goal, not the API.

2. **Implement.** Make the change in the repo following the conventions.

3. **Check.** Run `make eval EVAL=<name> --check`. All assertions must pass.
   If any fail, read the convention doc the assertion encodes, fix, re-check.

4. **Run `make check`.** The eval checks conventions; `make check` verifies the
   build compiles, tests pass, gate is green, formatting is clean.

## Writing an eval

Copy an existing eval and take the next free number:

```bash
cp -r evals/evals/01-add-page evals/evals/06-your-thing
```

Then edit two files:

**`PROMPT.md`** — what you'd type into the agent. Write it like a real user:
"Add a /team page with a heading and placeholder text" is good. "Use
`staticPage` from `App.Layout.Page`" is not — you're testing whether the agent
knows the convention, not whether it can pattern-match a name you handed it.

**`check.sh`** — verify the agent followed conventions. Prefer delegating to
canonical enforcement instead of duplicating grep rules:

```bash
# Structural + behavioral policy (see evals/evals/10-ui-archetypes/check.sh)
make gate
make test
```

For task-specific checks (route wired, module exists), targeted greps are fine:

```bash
check "uses Layout.Page" "grep -q 'App.Layout.Page' src/App/Features/Team/Page.purs"
check "route added" "grep -q 'Team' src/Data/Route.purs"
```

## Layout

```
evals/
├── evals/          # eval fixtures (PROMPT.md + check.sh each)
├── run-eval.sh     # runner
└── README.md       # this file
```

## Why not a sandbox?

The Next.js repo runs evals in a sandbox with baseline-vs-agents-md comparison
to measure whether bundled docs improve agent outcomes. That's the gold
standard for a framework with millions of users and stale training data.

For a starter template, the repo IS the fixture. The evals serve as:

1. **Self-check for agents** — run the check after completing the task.
2. **Documentation of "correct"** — the assertions encode the conventions.
3. **Validation for doc changes** — change a convention, run the evals, see if
   they still pass.
4. **Future CI integration** — evals can be run against a reference
   implementation in CI.
