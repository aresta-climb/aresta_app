# Proposal

## Why

O Worker `cloudflare/app-links` (`aresta_backend`) ativa `"cache": { "enabled": true }` (Cloudflare Workers Caching), cuja chave de cache inclui apenas `(entrypoint, versão, pathname + search)` e ignora o `hostname`. Quando uma requisição em cache frio chegava primeiro por `https://www.aresta.cc/`, o redirecionamento `301 -> https://aresta.cc/` emitido com `Cache-Control: public, max-age=86400, s-maxage=31536000` era gravado na chave compartilhada `/`, fazendo acessos subsequentes a `https://aresta.cc/` redirecionarem para si mesmos em loop (`ERR_TOO_MANY_REDIRECTS`) — risco idêntico existente em `www.aresta.cc/<uid>` e `www.arestaclimb.com/croquis*`. Além disso, adotar `301 Moved Permanently` em um único salto direto para `https://arestaclimb.com/croquis` (inclusive na raiz `/`) consolida integralmente o sinal de SEO (*PageRank*) sem cadeias de redirecionamento.

## What Changes

- **Unificação de `aresta.cc` e `www.aresta.cc` com `301` em 1 salto**: Remoção do redirecionamento intermediário `www.aresta.cc -> aresta.cc` para que tanto a raiz (`/` $\rightarrow$ `301` para `https://arestaclimb.com/croquis` preservando query string) quanto links curtos (`/[<prefixo>/]<uid>` $\rightarrow$ `301` para `https://arestaclimb.com/croquis/<uid>/<slug>`) redirecionem diretamente em um único salto `301`.
- **Isolamento de cache em rotas `/croquis*` fora do host canônico**: Qualquer acesso a `/croquis` ou `/croquis/*` em domínio diferente de `arestaclimb.com` (`www.arestaclimb.com`, `aresta.cc`, `www.aresta.cc`) responde `301` para `https://arestaclimb.com` com `Cache-Control: private, max-age=86400` (após a normalização de `/croquis/` para `/croquis`), garantindo `BYPASS` no cache compartilhado do Worker e preservando o HTML `200 OK` da vitrine contra envenenamento por host.

## Capabilities

### New Capabilities

### Modified Capabilities
- `worker-app-links`: Redirecionamento `301` em um pulo para `aresta.cc` e `www.aresta.cc` (incluindo raiz `/`) e isolamento de cache (`private`) em redirecionamentos de domínio não-canônico para `/croquis*`.

## Impact

- `aresta_backend/cloudflare/app-links/src/index.ts`: Remoção dos desvios `www.aresta.cc` / `www.arestaclimb.com` na raiz do roteador, conversão de `GET /` para `301` preservando query string e adição de guarda de host canônico `private` em `processarRotaVitrineCroquis`.
- `aresta_backend/cloudflare/app-links/test/worker_test.ts`: Atualização e ampliação dos testes comportamentais cobrindo redirect `301` em 1 pulo e invariante anti-loop de cache com 100% de cobertura.
- `aresta_backend/cloudflare/app-links/README.md`: Atualização da tabela de rotas e documentação da estratégia de cache na borda.
