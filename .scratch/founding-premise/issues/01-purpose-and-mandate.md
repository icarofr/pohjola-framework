# 01: Decide what Pohjola is actually for

**What to build:** No code — a decision, recorded here, that the other three tickets in this batch read differently depending on the answer.

The README pitches Pohjola as a general-purpose production framework ("Content, dashboard, commerce, and SaaS platforms," "Teams partnering with AI coding agents"). But it's one person, one month old (2026-08-09 to 2026-09-08), 225 commits, and git history shows at least one private app was already forked from it then scrubbed from this public tree (`56e2ab4`, `2b4b140`).

Pick one (or state the real mix, if it's genuinely more than one):

- **(a) Production framework** you intend other people/teams to eventually adopt — README's claims should be held to that standard.
- **(b) Private-app base**, publicized as a portfolio/framework artifact — the README is marketing for work that's really about the app(s), not the framework as a product.
- **(c) Research vehicle** for the idea itself — "can a compiler-enforced contract actually stop an AI agent from drifting" — where the app(s) are a test bed, not the point.

Recommended answer from the grilling session: (b) leaning (c) — a real private app exists, but the intensity of the self-documentation (ADRs, `GUARANTEES.md`, an unprompted deep-audit report) reads like the agent-safety mechanism is the actual object of study.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] Answer recorded here or in a follow-up comment
- [x] If the answer isn't "(a) production framework held to that standard," note whether the README's framing (badges, Landscape Comparison table, "Right Fit" list) should change to match — feeds directly into ticket 04

## Answer

Neither pure (a) nor (b)/(c) as originally framed — the real answer is sharper than any of the three options offered:

Pohjola is the foundation for all of the user's own personal apps ("its supposed to be the solution to the problems i personally face based on the apps i coined from scratch"), released open source because the user believes the conclusions are broadly useful. The specific trigger: seeing an existing framework built with what the user characterizes as low-quality, AI-assisted ("vibe coded") output, monetized via a tip jar, and concluding he could do it properly.

The actual positioning, in the user's own words: **"pohjola is intended to be the easiest way to vibe code a project, and since theres a lot of bad unsafe slop out there, pohjola is by design built to make the slop less sloppy."**

This reframes the whole batch: Pohjola's core claim isn't "generic production framework" (README's current framing) or "private tool" — it's specifically **a safety layer for AI-agent-driven ("vibe coded") development**, aimed at anyone using AI agents to build web apps, with the explicit bet that mechanical guardrails (compiler + `Policy.Contract` + ADRs) make agent output safer than the unguarded alternative. This is narrower and more specific than the README currently sells, and it's a claim that can actually be tested, not just asserted — see tickets 05-08.

## Comments
