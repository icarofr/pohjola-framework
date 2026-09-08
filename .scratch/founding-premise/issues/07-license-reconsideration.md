# 07: Reconsider AGPL — it may work against the stated goal, not for it

**What to build:** A licence decision, then a `LICENCE.md` swap + README badge update if it changes.

User's own words on this: "would love for it to get adopted, accept outside prs and stuff. and would agpl even fit here? worth pushing. i dont mind for profit companies using pohjola."

This is a real tension worth spelling out mechanically, not just as a vibe:

- **AGPL's actual mechanic** is network copyleft: if a company runs a modified (or even unmodified, in the stricter reading debate aside — the safe assumption is "any use that offers the software's functionality to users over a network") Pohjola-based app as a service, AGPL requires them to make **the complete corresponding source of that running service** available to its users — not just changes to Pohjola itself, the whole application built on top. This is stricter than plain GPL (which only triggers on distributing a binary, not on running a network service).
- **Consequence:** many companies have blanket policies banning AGPL-licensed dependencies specifically because of this clause — it's one of the most commonly denylisted licences in corporate open-source-usage policy, precisely because it can force disclosure of proprietary application code built on top. If the goal is "for-profit companies adopt this," AGPL is one of the licences most likely to get Pohjola vetoed before an engineer even reads the framework.
- **What AGPL does NOT do:** it does not enforce code quality, prevent "slop," or require attribution beyond standard notice-preservation. The original frustration (a competing framework felt low-effort, monetized early via a tip jar) is a **quality and governance** complaint, not a **licensing** complaint — no licence, AGPL included, prevents someone from building something low-quality on top of a well-built dependency, or from asking for donations while doing it.

Given "I don't mind for-profit companies using Pohjola" is the explicit intent, AGPL is arguably solving the wrong problem while creating real adoption friction the user says they don't want. Options, roughly ordered by how much they preserve "prevent low-effort resale/hosting" while still allowing normal for-profit adoption:

- **MIT / Apache-2.0** (permissive) — maximizes adoption, zero share-back requirement. Apache-2.0 adds an explicit patent grant MIT lacks, worth having for a framework (protects users if a contributor later asserts a patent claim). This is what "I don't mind for-profit companies using it, I want it adopted" most directly implies.
- **MPL-2.0** (weak/file-level copyleft) — a middle ground: modifications to Pohjola's own files must be shared back if distributed, but an application built using Pohjola as a dependency stays proprietary freely. Closer to "contribute back changes to the framework itself" without AGPL's whole-application network trigger.
- **Stay AGPL, deliberately** — only makes sense if the actual goal is closer to "I'm fine with for-profit *use*, but not fine with a for-profit *fork that competes as a closed, hosted alternative without contributing back*" — i.e. specifically targeting the SaaS-wrapper-resale pattern the original frustration was about. If that's the real target, say so explicitly and accept the adoption friction as the deliberate cost, rather than defaulting to AGPL without weighing it against MIT/Apache-2.0/MPL-2.0.

None of these actually solve the *quality* complaint — that's an unrelated axis (governance: contribution guidelines, review standards, a visible "here's what makes this different" doc) that a licence choice can't carry.

**Blocked by:** None — pure decision, independent of every other ticket in this batch.

**Status:** resolved

- [x] Licence decision recorded here
- [x] `LICENCE.md`, README badge/section, `AGENTS.md`'s licence line updated to match

## Resolution

User's explicit call, twice clarified: keep `LICENCE.md` exactly as the short joke text it was ("woke software licence is not legally binding, just swap agpl for mit or apache and keep the as long as youre woke, this is a joke, its my repo and i think its hilarious" — then, correcting an over-literal first pass that inserted real Apache License 2.0 boilerplate into the file: "dont swap the licence.md, just swap the agpl string by apache or other model"). Landed: `LICENCE.md`'s one reference to "AGPL" changed to "Apache," nothing else in that file touched; `README.md`'s badge + `## Licence` section and `AGENTS.md`'s licence line updated from "AGPL" to "Apache" to match. The file remains, by design, a non-binding joke rather than real licence text — the user is aware of this and wants it that way.

## Answer (partial — mechanics settled, exact license not yet picked)

User: "ok whichever licence is fine as soon as its called licence with brit spelling and the tongue in cheek as long as youre woke remains."

**Bigger finding surfaced while checking this:** `LICENCE.md`'s actual current content is not AGPL at all — it's a custom "WOKE SOFTWARE LICENCE" ("Do whatever the fuck you want as long as you're woke. Basically the AGPL licence but only when you're woke."). This is not a recognized OSI license, "woke" is not a legally definable condition, and no company's legal team can approve adopting a dependency under it — this conflicts directly with "would love for it to get adopted... accept outside prs" more severely than the AGPL-vs-permissive question does, since it's not just stricter, it may not be a valid/clear grant of rights at all.

**Resolution direction (not yet finalized):** keep the tongue-in-cheek "woke" framing as flavor text (a header note, a comment above the real license text, something like "Licenced under the spirit of: do whatever the fuck you want, as long as you're woke — legally, that's the [MIT/Apache-2.0] text below"), while the actual operative grant is a real, standard license text a company's lawyer can recognize and approve. British spelling of "Licence" (the filename and all references) stays regardless of which license body text is chosen.

Still open: which real license (MIT vs Apache-2.0 vs MPL-2.0) — see the option analysis above, recommendation was MIT/Apache-2.0 given "I don't mind for-profit companies using Pohjola."

## Comments
