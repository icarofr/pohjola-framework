# 02: Is PureScript+Bun over Haskell+IHP a terminal preference?

**What to build:** No code — a decision. Depends on 01's answer for how much weight to give it (a "production framework" answer makes this higher-stakes than a "research vehicle" answer).

Verified live (not assumed) on 2026-09-08: IHP's own site now reads *"IHP is the Haskell web framework for agentic engineering. Your agent writes the code; typed SQL, generated schema types and compile-checked views prove it works."* That is Pohjola's "Built for AI Agents: Zero-Drift by Construction" pitch, in IHP's own words — and IHP ships it alongside a working ORM, schema designer, code generators, and built-in signup/login auth, none of which Pohjola has yet (see ticket 03).

The README already rejects IHP explicitly — but on Nix/GHC build-overhead grounds, not on missing features (`README.md`'s Landscape Comparison table). `ADR-013` goes further: it borrows IHP's core philosophy (policy lives in types/compiler, not a JSON manifest) by name, while still rejecting the stack.

The question: is the Nix/GHC rejection **terminal** (true regardless of what IHP ships — you already know you don't want Haskell/Nix, full stop), or was it **contingent** on IHP not yet covering the agent-safety niche (in which case this new fact should reopen the question)?

Recommended answer from the grilling session: terminal — the README's rejection reads like a stack preference, not a feature gap, so this is likely "yes I know, doesn't change anything." But this is the one ticket in the batch where a different answer would be the whole ballgame, so it's worth actually sitting with rather than rubber-stamping.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] Answer recorded here or in a follow-up comment
- [x] Terminal — no further action beyond recording the reasoning here

## Answer

Terminal, not contingent. User's reasoning: "agent safety but hard to deploy with nix, long compile times, less guards than we do."

Assistant's independent verdict (asked for directly): keep the PureScript+Bun stack. Two of the three reasons hold up under scrutiny — Nix is a verified hard requirement for IHP with no documented bypass (a real onboarding tax against exactly this project's target audience), and Haskell's npm/SDK ecosystem interop (Stripe etc.) is genuinely thinner than Bun's native npm compatibility. The third reason ("less guards than we do") was NOT independently verified with the same rigor applied to the RasenganJS comparison (ticket "05"/Q7 area) — flagged as an unverified claim that should not be repeated in any public doc without actually reading IHP's enforcement mechanism (Haskell typeclasses, closed view surfaces, `nix flake check`, and IHP's own 2026 "agentic engineering" positioning around compile-checked views) as closely as RasenganJS's was read this session.

The stronger argument for staying the course, not on the user's original list: **switching cost.** A working private app already exists on this foundation; a full-stack rewrite onto Haskell is a materially bigger bet than continuing, independent of which stack is abstractly better. This also isn't a new decision — `ADR-013` already made this exact call (borrow IHP's philosophy, reject its stack) with recorded reasoning; this ticket re-confirms it rather than reopening it.

**Actionable follow-through:** treat IHP as a design reference for closing Pohjola's own real gap (ADR-002 auth implementation) rather than as a fork target — it already shipped the thing Pohjola hasn't.

## Comments
