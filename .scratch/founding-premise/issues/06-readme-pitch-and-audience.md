# 06: Rewrite the README's core pitch — "safest," not "easiest," for both audiences on purpose

**What to build:** A `README.md` rewrite of the opening pitch and possibly a new short section, once the decisions below are settled.

Two related decisions from the founding-premise grilling, both resolved:

**Audience (was Q5):** Both devs and vibe-coders — the README's job is to communicate "the conclusions I reached, so other devs and vibe coders alike can benefit," not just to onboard one or the other. User's own words: "both? just the conclusions i reached... evidence isnt bad i guess" (partially agreeing the README currently reads more like a technical-evaluator pitch than a vibe-coder one).

**Claim (was Q6):** "Easiest" is the wrong word. User's own words: "safest. the goal is to produce good non slop code." The current README leads with "the easiest way to vibe code a project" energy without saying so explicitly, and never states the safety-over-speed trade plainly.

Open question this ticket needs to resolve, not yet asked/answered: if the README is meant to serve **both** a vibe-coder (who won't read dense ADT/HATEOAS jargon before starting) **and** a skeptical technical evaluator (who needs the rigor to trust it), does one document actually serve both today, or does it need a structural split — e.g. a short, plain-language "what this actually is and why" pitch at the top (safety-adjusted ease, stated as such), with the current dense technical case kept below for the evaluator who reads further? A single paragraph currently tries to do both jobs and arguably does neither optimally.

**What Pohjola actually solves (from the grilling session, for the rewrite to draw on):** not based on any other PureScript framework — built directly on Bun. Combines: real safety contracts (`Policy.Contract`'s compiler-enforced chain) specifically aimed at preventing AI-agent slop; conclusions drawn from HATEOAS/htmx (server-authoritative hypermedia, not a client-state duplicate); genuine Node.js/npm ecosystem interop (SDKs like Stripe work normally — not locked out by an exotic runtime); DaisyUI chosen deliberately as the best available way to guarantee UI polish without hand-rolled utility-class soup, specifically because "if im advertising pohjola as a tight bulletproof framework the ui should also be tight." The `Policy.Contract` enforcement chain remains the sharpest, most specific differentiator — but DaisyUI-for-UI-consistency is a second, concrete, non-marketing answer to "what does this actually solve that a from-scratch build wouldn't."

**Grounding for the softened "slop" framing (evidence, not vibes):** the user's original trigger for building Pohjola was seeing another AI-era web framework as low-effort "slop." An empirical check of that specific framework's real GitHub source (not its marketing) found a mixed picture worth stating precisely in any public comparison, rather than repeating the blanket "slop" label:
- It has real test coverage (100+ unit/integration test files) — the blanket "slop" label overclaims on code volume/effort.
- But: **no CI step runs that test suite at all** — its release/publish workflow ships to its package registry without running tests first. 100+ tests exist and none of them gate a release.
- Its core package has strict type-checking **disabled** in its own compiler config — the language's own safety net is off for the flagship package.
- No mechanism anywhere comparable to `Policy.Contract` — no compile-time or gate-level enforcement of its own conventions, just (non-strict) typechecking + unenforced tests, the same protection level as most of the ecosystem it competes in, not a different category.
- A donation link is real and confirmed present in the repo.
- It's effectively solo-maintained (one contributor vastly outweighs all others) despite an organization name/branding — worth remembering as a mirror, since Pohjola has the same bus-factor risk without the org veneer.
- The specific "glaring UI problems" characterization could **not** be verified from a structural read of the live site — soften or drop that specific claim rather than assert it without visual proof.

The honest, specific, defensible version of the critique: **not** "it's slop," but "it has some enforcement (types, tests) — it's just unenforced, since nothing gates a merge or release on it." Pohjola's own honest self-critique this session was the mirror of that: "the enforcement chain is real but has a verified gap" (ticket 05's auth-bypass finding), not "the enforcement chain doesn't exist." That's the actual, stateable difference — sharper and more credible than a vague "slop" swipe, and it survives someone checking your homework the way this session checked it. (Per explicit user instruction, the specific framework isn't named in this file — this is a public repo.)

**Blocked by:** 01 (done — purpose confirmed), 04 (SaaS claim scoping — same section of the README, should land together)

**Status:** resolved

- [x] Decide: single document serving both audiences as-is, or structural split? — **single document**, confirmed ("fine with single doc").
- [x] Rewrite opening pitch to state the safety-adjusted claim explicitly
- [x] Landed together with ticket 04's SaaS-claim edit — same README pass

## Answer / what landed

Opening pitch rewritten in place (no structural split): the bold lead sentence now reads "Pohjola is the safest way to vibe code a web app," followed by one new paragraph stating the actual thesis plainly ("A lot of what gets shipped as an AI-assisted 'framework' today is unsafe slop held together by convention alone. Pohjola is a deliberate bet on the opposite...") before continuing into the existing denser technical paragraph. Vibe-coder gets the plain hook in sentence one; the technical evaluator keeps reading into the same doc for the rigor. Nothing was removed or forked into a second document.

## Comments
