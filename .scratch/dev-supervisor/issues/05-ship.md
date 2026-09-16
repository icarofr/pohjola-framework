# Ship the supervisor

Type: task
Status: resolved
Blocked by: 04

## Question

Apply the locked answers, verify gate/test, commit on top of origin/master, and push without rewriting the remote tip.

## Answer

Ported onto `origin/master` (`9f9a5a3b`). `make gate` 20/20, `make test` 235/235 plus 6 pick-port tests. Pohjola `renderDsDocument` kept and given `productionChrome`. No fonts route (this tree has none).

## Comments

Porting onto pohjola-framework origin/master.
