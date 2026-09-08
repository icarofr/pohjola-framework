# 01: Make blog posts trilingual (En/Fr/Pt)

**What to build:** Posts currently have no language dimension — `posts(id, user_id, title, body, created_at)`, one row per post, English only. Every other page on the site is fully localized; posts aren't. This ticket adds real Fr/Pt content and wires `Lang` through the already-existing plumbing (it's threaded to the call site already, just never used).

**Requires prod DB access this session doesn't have.** Nothing here has been run against a live database.

## Recommended schema: a separate translations table, not wide columns

Matches this repo's own established pattern for the same problem (see
`migrations/003_create_users_and_oauth.sql`'s `oauth_accounts` table,
committed the same day as this ticket, chosen for the identical reason:
adding a language later needs no schema change).

```sql
-- Migration: create_post_translations
CREATE TABLE IF NOT EXISTS post_translations (
  post_id INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  lang TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  PRIMARY KEY (post_id, lang)
);
```

`lang` values: `"en"`, `"fr"`, `"pt"` — verified against `src/Data/I18n.purs`:
`langTag`/`Show Lang` both already produce exactly these strings, and
`parseLang` parses them back (`src/Data/I18n.purs:33-46`). Use `langTag`/
`show` to get the query parameter from a `Lang`, don't hand-roll a second
mapping.

**Why not just add `title_fr`, `body_fr`, `title_pt`, `body_pt` columns to
`posts` directly?** Works, but a 4th language later means an `ALTER TABLE`
plus touching every existing query; the join-table approach means a 4th
language is just new rows. Given this repo already made the identical call
for OAuth providers on the same day, do the same here for consistency,
unless whoever implements this has a concrete reason not to (e.g. if
`posts` row count and query patterns make the join genuinely costly, which
at 6 rows it obviously isn't — but say so if that reasoning changes at
production scale).

**Migrating existing English rows:** `posts.title`/`posts.body` (English)
should move into `post_translations` as the `lang = 'en'` rows, then
(separately, your call) either dropped from `posts` or left as a fallback —
decide based on whether any other code still reads `posts.title`/`body`
directly (check `Posts.Service` and anywhere else `SELECT ... FROM posts`
appears before removing the columns).

## Wiring (App.Features.Posts.Service / Page)

`src/App/Features/Posts/Service.purs` currently:

```purescript
result <- SQL.query sql "SELECT id, user_id, title, body FROM posts ORDER BY id ASC" []
-- and
result <- SQL.query sql "SELECT id, user_id, title, body FROM posts WHERE id = $1 LIMIT 1" [ SQL.SqlInt id ]
```

Needs a `Lang` parameter and a join:

```sql
SELECT p.id, p.user_id, pt.title, pt.body
FROM posts p
JOIN post_translations pt ON pt.post_id = p.id
WHERE pt.lang = $1
ORDER BY p.id ASC
```

`fetchPosts`/`fetchPost` (`Service.purs`) need a `Lang -> ...` parameter
added to their signatures; `Posts.Page.renderList`/`renderDetail`
(`src/App/Features/Posts/Page.purs`) already have `Lang` in scope — pass it
through, no new plumbing needed there. Convert `Lang` to the `"en"`/`"fr"`/
`"pt"` string via whatever function `Data.I18n` already exports for that
(check before adding a new one — it likely already exists for URL/route
codecs).

**Fallback behavior if a translation is missing for a given post+lang:**
not specified here — decide when implementing (e.g. fall back to English,
or 404). This ticket ships all 3 languages for all 6 existing posts below,
so the missing-translation case won't actually occur for current data, but
the code path should still make a deliberate choice, not an accidental one.

## Translated content

English titles/bodies below are the **corrected** versions from
`migrations/001_create_posts.sql` as of this ticket (the truthfulness pass
already removed "sub-millisecond"/"zero runtime exceptions" claims from
these — don't reintroduce them by translating from the old, uncorrected
text if you're working from git history instead of the current file).

---

### Post 1 — Why Functional SSR on Bun Matters

**EN**
> Building web applications with PureScript and Bun combines compile-time totality with a fast, native runtime.
>
> Unlike traditional Node.js runtimes that carry heavy startup and module resolution overhead, Bun serves pre-rendered HTML natively. Paired with PureScript's closed algebraic HTML data type, views are rendered as pure values with centralized escaping, closing off the common XSS path before a single byte touches the wire.

**FR** — *Pourquoi le SSR fonctionnel sur Bun change la donne*
> Construire des applications web avec PureScript et Bun combine la totalité vérifiée à la compilation avec un runtime natif et rapide.
>
> Contrairement aux runtimes Node.js traditionnels, alourdis par un démarrage lent et la résolution de modules, Bun sert du HTML pré-rendu nativement. Associé au type de données HTML algébrique et fermé de PureScript, chaque vue est rendue comme une valeur pure avec un échappement centralisé, fermant la voie XSS la plus courante avant même qu'un octet n'atteigne le réseau.

**PT** — *Por que o SSR funcional no Bun faz diferença*
> Construir aplicações web com PureScript e Bun combina totalidade verificada em tempo de compilação com um runtime nativo e rápido.
>
> Ao contrário dos runtimes Node.js tradicionais, com arranque pesado e resolução de módulos, o Bun serve HTML pré-renderizado nativamente. Combinado com o tipo de dados HTML algébrico e fechado do PureScript, cada view é renderizada como um valor puro com escaping centralizado, fechando o caminho comum de XSS antes mesmo de um byte tocar a rede.

---

### Post 2 — Eliminating the Hydration Cliff with Alpine.js

**EN**
> Single-page application frameworks require downloading megabytes of client JavaScript just to re-render markup that the server already produced.
>
> Pohjola eliminates the hydration cliff by coupling server-rendered HTML with Alpine.js morphing. Hovering over a navigation link pre-fetches the target HTML fragment in the background. On click, Alpine swaps the content container instantaneously, delivering SPA speed with zero client state drift.

**FR** — *Éliminer la falaise d'hydratation avec Alpine.js*
> Les frameworks single-page application exigent de télécharger des mégaoctets de JavaScript côté client, rien que pour ré-afficher un balisage que le serveur avait déjà produit.
>
> Pohjola élimine la falaise d'hydratation en couplant du HTML rendu côté serveur avec le morphing d'Alpine.js. Survoler un lien de navigation précharge le fragment HTML cible en arrière-plan. Au clic, Alpine remplace le conteneur de contenu instantanément, offrant la réactivité d'une SPA sans dérive d'état côté client.

**PT** — *Eliminando o penhasco de hidratação com Alpine.js*
> As frameworks single-page application exigem descarregar megabytes de JavaScript no cliente só para re-renderizar marcação que o servidor já tinha produzido.
>
> O Pohjola elimina o penhasco de hidratação ao combinar HTML renderizado no servidor com o morphing do Alpine.js. Passar o rato sobre um link de navegação pré-carrega o fragmento HTML alvo em segundo plano. Ao clicar, o Alpine substitui o contentor de conteúdo instantaneamente, entregando a reatividade de uma SPA sem deriva de estado no cliente.

---

### Post 3 — Hypermedia as the Engine of Application State (HATEOAS)

**EN**
> Why replicate complex state machines and API schemas across client and server when hypermedia already solves distributed state?
>
> In Pohjola, application state transitions are driven by hypermedia representations. The server emits semantic HTML where available actions, disabled controls, and navigation links reflect the exact server resource state. Paired with PureScript's closed algebraic Html ADT and Alpine AJAX fragment morphing, HATEOAS delivers fluid, reactive client experiences backed by the compiler's exhaustiveness checks.

**FR** — *L'hypermédia comme moteur d'état applicatif (HATEOAS)*
> Pourquoi dupliquer des machines à états complexes et des schémas d'API entre client et serveur, quand l'hypermédia résout déjà l'état distribué ?
>
> Dans Pohjola, les transitions d'état de l'application sont pilotées par des représentations hypermédia. Le serveur émet du HTML sémantique où les actions disponibles, les contrôles désactivés et les liens de navigation reflètent exactement l'état de la ressource côté serveur. Associé à l'ADT Html algébrique et fermé de PureScript ainsi qu'au morphing de fragments par Alpine AJAX, HATEOAS offre une expérience client fluide et réactive, appuyée sur les vérifications d'exhaustivité du compilateur.

**PT** — *Hipermídia como motor do estado da aplicação (HATEOAS)*
> Por que duplicar máquinas de estado complexas e esquemas de API entre cliente e servidor, quando a hipermídia já resolve o estado distribuído?
>
> No Pohjola, as transições de estado da aplicação são guiadas por representações hipermídia. O servidor emite HTML semântico onde as ações disponíveis, os controlos desativados e os links de navegação refletem exatamente o estado do recurso no servidor. Combinado com o ADT Html algébrico e fechado do PureScript e o morphing de fragmentos via Alpine AJAX, o HATEOAS entrega uma experiência de cliente fluida e reativa, apoiada nas verificações de exaustividade do compilador.

---

### Post 4 — Total Type Safety Across HTTP and HTML

**EN**
> In conventional frameworks, routing, API payloads, and HTML generation exist across loose string boundaries where typos and breaking changes hide.
>
> In Pohjola, routes are bidirectional codecs verified by routing-duplex. HTML is constructed through algebraic constructors rather than string templates. If a route or translation key changes, the compiler immediately rejects any broken references across the entire codebase.

**FR** — *Sécurité de type totale, de HTTP au HTML*
> Dans les frameworks conventionnels, le routage, les payloads d'API et la génération de HTML existent à travers des frontières de chaînes de caractères peu fiables, où fautes de frappe et changements cassants se cachent.
>
> Dans Pohjola, les routes sont des codecs bidirectionnels vérifiés par routing-duplex. Le HTML est construit via des constructeurs algébriques plutôt que des templates de chaînes. Si une route ou une clé de traduction change, le compilateur rejette immédiatement toute référence cassée dans l'ensemble du code.

**PT** — *Segurança total de tipos, do HTTP ao HTML*
> Em frameworks convencionais, o routing, os payloads de API e a geração de HTML existem através de fronteiras de strings pouco fiáveis, onde erros de digitação e mudanças que quebram o código se escondem.
>
> No Pohjola, as rotas são codecs bidirecionais verificados por routing-duplex. O HTML é construído através de construtores algébricos em vez de templates de strings. Se uma rota ou uma chave de tradução mudar, o compilador rejeita imediatamente qualquer referência quebrada em toda a base de código.

---

### Post 5 — Taming the Foreign Function Interface (FFI)

**EN**
> JavaScript interop is often the weakest link in statically typed web applications.
>
> Pohjola enforces a strict FFI safety floor: all foreign JavaScript imports are restricted to four allowlisted modules. Every FFI boundary is wrapped in PureScript types, converting untrusted runtime errors into explicit Either values that must be handled at the call site.

**FR** — *Dompter l'interface de fonctions étrangères (FFI)*
> L'interopérabilité avec JavaScript est souvent le maillon le plus faible des applications web à typage statique.
>
> Pohjola impose un socle de sécurité FFI strict : tous les imports JavaScript étrangers sont restreints à quatre modules explicitement autorisés. Chaque frontière FFI est enveloppée dans des types PureScript, convertissant les erreurs runtime non fiables en valeurs Either explicites, à traiter obligatoirement au point d'appel.

**PT** — *Domando a interface de funções estrangeiras (FFI)*
> A interoperabilidade com JavaScript é muitas vezes o elo mais fraco em aplicações web com tipagem estática.
>
> O Pohjola impõe uma base de segurança FFI rigorosa: todas as importações estrangeiras de JavaScript são restritas a quatro módulos explicitamente autorizados. Cada fronteira FFI é envolvida em tipos PureScript, convertendo erros de runtime não confiáveis em valores Either explícitos, que têm de ser tratados no local da chamada.

---

### Post 6 — Mechanical Guarantees and Zero-Drift for AI Pairs

**EN**
> Conventions rot; mechanical assertions endure.
>
> Every commit in Pohjola is validated against byte-exact Content Security Policy nonces, closed HTML ADT rules, and feature isolation constraints. Running make gate and ContractSpec verifies architectural invariants quickly enough to run on every commit. Because routes, translations, and domain effects are expressed through exhaustive types, AI coding agents and humans cannot introduce breaking changes or hallucinate missing handlers without triggering immediate compiler errors.

**FR** — *Garanties mécaniques et zéro dérive pour les agents IA*
> Les conventions se dégradent ; les vérifications mécaniques, elles, tiennent.
>
> Chaque commit dans Pohjola est validé contre des nonces de Content Security Policy exacts au caractère près, des règles d'ADT Html fermé, et des contraintes d'isolation des fonctionnalités. Exécuter make gate et ContractSpec vérifie les invariants architecturaux assez rapidement pour tourner à chaque commit. Parce que routes, traductions et effets métier sont exprimés via des types exhaustifs, agents IA comme humains ne peuvent introduire de changement cassant ou halluciner un handler manquant sans déclencher une erreur de compilation immédiate.

**PT** — *Garantias mecânicas e zero deriva para agentes de IA*
> Convenções apodrecem; verificações mecânicas resistem.
>
> Cada commit no Pohjola é validado contra nonces de Content Security Policy exatos byte a byte, regras do ADT Html fechado, e restrições de isolamento de funcionalidades. Executar make gate e ContractSpec verifica os invariantes arquiteturais rápido o suficiente para correr a cada commit. Como rotas, traduções e efeitos de domínio são expressos através de tipos exaustivos, agentes de IA e humanos não conseguem introduzir mudanças que quebrem o código, nem alucinar um handler em falta, sem disparar um erro de compilação imediato.

---

## Implementation steps

1. Use `langTag`/`show` (`src/Data/I18n.purs:33-40`) to get `"en"`/`"fr"`/`"pt"` from a `Lang` — already exists, don't hardcode a fresh mapping.
2. New migration: `post_translations` table (see schema above), plus a data migration moving the current English `posts.title`/`body` into `lang = 'en'` rows.
3. Insert the Fr/Pt rows above for post ids 1-6.
4. Decide whether `posts.title`/`posts.body` columns get dropped once `post_translations` covers `en` too, or kept as a fallback — check every `SELECT`/`INSERT` touching `posts` first (`Posts.Service`, migration scripts) before dropping anything.
5. `Posts.Service.fetchPosts`/`fetchPost`: add a `Lang` parameter, join `post_translations`, filter `WHERE pt.lang = $N`.
6. `Posts.Page.renderList`/`renderDetail`: pass the already-in-scope `Lang` through to the `Service` calls.
7. Decide and implement the missing-translation fallback behavior (English fallback vs. 404) — not specified here.
8. `make gate && make test && make check` before shipping — same ladder this repo always uses. Live-DB behavior itself still needs manual verification against the real database (no local DB available to test this ticket's SQL against, same limitation the recent auth work has).

## Acceptance criteria

- [ ] `post_translations` (or equivalent) table exists with `en`/`fr`/`pt` rows for all 6 posts
- [ ] Visiting `/fr/posts` and `/pt/posts` (list + each post detail) shows the translated title/body, not English
- [ ] `/en/posts` still shows English (regression check)
- [ ] `Posts.Service`/`Posts.Page` changes pass `make gate && make test && make check`
- [ ] Missing-translation behavior (if it ever occurs) is a deliberate, documented choice, not silent English leakage or an unhandled crash
