# Agent prompt: Pohjola stack deep audit

**Branch:** disposable — safe to delete after review.  
**Repo:** `icarofr/pohjola-framework` (public framework, PureScript 0.15.16 + Bun + Alpine AJAX MPA).  
**Live demo:** https://pohjola.icaro.fr

---

## Your mission

You are a senior systems architect and agent-ergonomics reviewer. Perform a **read-only deep audit** of this repository: architecture, documentation, agent instructions, policy/gates, and the day-to-day experience of an AI coding agent working here.

Be blunt, specific, and evidence-based. Praise what earns it. Call out convoluted indirection, doc drift, false guarantees, and places where an agent will waste tokens or ship wrong code.

**Do not implement fixes** unless explicitly asked later. Deliver a written audit.

---

## Context (read first, ~15 min)

1. `README.md` — positioning and mental model  
2. `AGENTS.md` (or `CLAUDE.md`, symlink) — agent operating manual  
3. `docs/GUARANTEES.md` — what the project claims is enforced  
4. `Makefile` — `make gate`, `make check`, `make ci-equivalent`, eval targets  
5. `src/Policy/Contract.purs` + `test/ContractSpec.purs` + `test/Gate` — policy floor  
6. `src/App/Main.purs` — request routing, fragment vs full page, caching  
7. `src/App/Alpine.purs` + `docs/conventions/alpine-contracts.md` — browser seam  
8. `src/App/Ui/Templates/` + `docs/superpowers/specs/2026-08-31-page-architectures.md` — UI contract  
9. `evals/README.md` + sample eval prompts — how agent behavior is tested  

Skim ADR index under `docs/adr/`. Sample one feature end-to-end: `src/App/Features/About/{Page,View}.purs` and how it reaches `SiteShell` / `PageHeader`.

---

## Audit dimensions

### 1. Architecture coherence

- Is the **MPA + Alpine AJAX fragments** model internally consistent, or are there places that secretly assume SPA/hydration?  
- Does the **Page / View / Service / Types** split scale, or will it collapse under real apps?  
- **Route codecs per language** (`Data/Route.purs`) — elegant or tax?  
- **Caching** (static vs dynamic, fragment `Vary`, form-status bypass) — correct and understandable?  
- **FFI allowlist** (4 modules) — sufficient boundary or paper wall?  
- **Html ADT + no unescaped HTML** — real safety or bypassable?  
- **Head sync on fragment nav** (`Scripts.purs` + `Head.pageSyncAttrs`) — sound pattern or fragility?  
- What breaks first at 10× pages, 10× agents, or a private app fork?

### 2. Documentation & instructions

Map the doc graph: which files are canonical, which overlap, which are stale or aspirational.

| Area | Starting points |
|------|-----------------|
| Agent entry | `AGENTS.md`, `docs/AGENT_CONTEXT.md`, `.cursor/rules/` |
| Conventions | `docs/conventions/*.md`, `DESIGN.md` |
| ADRs | `docs/adr/ADR-*.md` (accepted vs proposed) |
| Superpowers specs | `docs/superpowers/specs/`, `docs/superpowers/plans/` |
| Human-only | `docs/SETUP.md` (agents should skip) |
| Guarantees | `docs/GUARANTEES.md` vs what `make gate` / ContractSpec actually prove |

Questions:

- Can a **new agent** find the right doc in &lt;3 hops for: add page, add UI, Alpine interaction, FFI, deploy?  
- Where do **AGENTS.md task→doc triggers** lie or contradict the code?  
- Is there **doc debt** (README claims vs implementation, ADR-010 proposed vs policy)?  
- What should be **merged, deleted, or generated** from code?

### 3. Agent ergonomics (most important)

Answer honestly as if you will maintain this repo for 6 months via Cursor/Claude:

- **Onboarding cost:** How many concepts must an agent load before a safe first PR?  
- **Cognitive load:** PageTemplate slots, Contract markers, DaisyUI only in `App.Ui`, no `class_` in features — teaching power or ceremony?  
- **Verification path:** Is `make gate` → `make check` → evals the right ladder? What's missing?  
- **Failure modes:** Where do agents reliably fail (grep-first workflow, generator-policy, purs-tidy, e2e flakes)?  
- **Convoluted?** Name the top 5 "why is it like this?" moments. Which are justified vs accidental?  
- **Ideal agent workflow:** If you could redesign agent instructions in one page, what would it contain? What would you *remove* from `AGENTS.md`?  
- **Evals:** Do `evals/` actually shape behavior or just catch regressions? Gaps?  
- **Context efficiency:** Is the repo agent-friendly at 200k context or does every task require reading half the tree?

### 4. Comparative lens (brief)

Without fanboying or dismissing:

- vs **Next.js / React SPA** — what did Pohjola buy with complexity?  
- vs **Rails/Django hypermedia** — what's genuinely better beyond types?  
- vs **htmx** — Alpine typed seam + frozen transport (ADR-011) — better or over-fitted?  
- Is the **"compiler as contract"** story honest for contributors who mostly touch `App.Features/*`?

### 5. Risk register

Produce a short table: **risk | likelihood | impact | mitigation already in repo | gap**

Cover at least: policy bypass, CSP widening, fragment/cache bugs, i18n drift, generator drift, agent doc drift, AGPL fork friction, Bun/PS ecosystem risk.

---

## Deliverable format

Write a single markdown report (suggested path: `docs/audits/agent-stack-deep-audit-report.md` or paste in PR/issue). Structure:

```markdown
# Pohjola stack deep audit

## Executive summary (≤10 bullets)

## Architecture verdict
### Strengths
### Weaknesses / scaling cliffs
### One diagram (mermaid) of request → render → fragment swap

## Documentation & agent-instructions verdict
### Canonical map (what to read when)
### Redundant / stale / missing docs
### Proposed AGENTS.md diff (outline only)

## Agent ergonomics verdict
### How I would want to work here
### Is it convoluted? (yes/no + nuance)
### Top 10 friction points (ranked)
### Top 10 things to keep unchanged

## Risk register

## Prioritized recommendations
| P | Effort | Recommendation | Rationale |
|---|--------|----------------|-----------|
| P0/P1/P2 | S/M/L | ... | ... |

## Open questions for the maintainer
```

**Tone:** Technical blog quality. No engagement bait. Cite file paths and line ranges where possible.

---

## Constraints

- **Read-only** — audit only; no drive-by refactors.  
- **Run** `make gate` and spot-check `make test` if environment allows; note if you could not run.  
- **Do not** widen CSP, FFI, or Alpine seams as "fixes."  
- **Do not** add co-authored commit trailers.  
- Distinguish **enforced** (ContractSpec/gate) from **documented** from **aspirational** (proposed ADRs).  
- This is a **public framework** — no private app names or paths in the report.

---

## Success criteria

The audit is successful if a maintainer can:

1. Decide what to simplify vs double down on, with evidence.  
2. Rewrite agent instructions in one focused session.  
3. Prioritize a quarter of framework work from your P0/P1 list.  
4. Explain to a skeptical senior dev why agents *can* work here without hand-holding — or why they cannot yet.

---

## Optional deep dives (if time)

- Trace one **e2e** (`e2e/navigation.spec.js`, `e2e/i18n.spec.js`) to the code it protects.  
- Read `scripts/auto-scaffold.js` generator boundaries vs `make generator-policy`.  
- Compare `vendor/daisyui/skills/` agent surface to `App.Ui` reality.  
- Review recent `git log --oneline -20` for architectural direction vs doc lag.

---

*Prompt authored for handoff to a capable audit agent. Delete this branch when done.*
