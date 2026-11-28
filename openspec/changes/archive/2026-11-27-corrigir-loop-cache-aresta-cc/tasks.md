# Tasks

## 1. Correção de Redirecionamentos e Isolamento de Cache no Worker `app-links`

- [x] 1.1 Atualizar e expandir os testes comportamentais em `aresta_backend/cloudflare/app-links/test/worker_test.ts` (fase Red do TDD) cobrindo redirect `301` em 1 pulo na raiz `/` e em `www.aresta.cc/<prefixo>/<uid>`, redirect privado (`private, max-age=86400`) em domínios não-canônicos de `/croquis*` e o invariante anti-loop de cache, confirmando que `deno test -A test/` falha antes da implementação.
- [x] 1.2 Implementar o roteamento sem colisão de cache em `aresta_backend/cloudflare/app-links/src/index.ts` (fase Green/Refactor) mantendo 100% de cobertura de linhas, funções e branches verificada via `deno test -A --coverage` e `deno coverage`.
- [x] 1.3 Atualizar a documentação de rotas e cache em `aresta_backend/cloudflare/app-links/README.md` refletindo os redirects `301` em 1 pulo e o cabeçalho `private` em `/croquis*` fora de `arestaclimb.com`.

## Workflow follow-up

- Sincronizar `worker-app-links` e arquivar a change após validação e cobertura 100%.
- Realizar commit e push em `aresta_backend` e `aresta_app`, publicar via `npx wrangler deploy` e verificar em produção com `curl.exe -I` em cache frio.
