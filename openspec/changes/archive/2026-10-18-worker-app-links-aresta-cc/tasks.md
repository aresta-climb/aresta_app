# Tasks

## 1. Contrato OpenAPI em `aresta_api` (`openapi/app_links.yaml`)

- [x] 1.1 Criar `aresta_api/openapi/app_links.yaml` especificando o servidor `https://aresta.cc`, as rotas `/health`, `/.well-known/assetlinks.json`, `/.well-known/apple-app-site-association`, `/{uid}` e `/{prefixo}/{uid}`, além do schema `ResumoEntidadeLink`, validando com `python build.py` e `pytest` em `aresta_api`.
- [x] 1.2 Sincronizar os artefatos gerados de `aresta_api` (`openapi/generated/ts/app_links.ts`, `openapi/generated/python/app_links.py` e `openapi/generated/dart/app_links.dart`) nos repositórios consumidores e atualizar o `README.md` do `aresta_api` documentando o novo contrato.

## 2. Módulos de Domínio e Resolução D1 em `aresta_backend/cloudflare/app-links`

- [x] 2.1 Criar a estrutura do Worker em `aresta_backend/cloudflare/app-links/` (`wrangler.jsonc`, `deno.json`, `package.json`) configurando o binding `DB` para o banco Cloudflare D1 `aresta-catalogo` e as rotas `aresta.cc` e `www.aresta.cc`.
- [x] 2.2 Seguindo TDD com espelhamento 1:1, implementar `src/analisador_rota_link.ts` e `test/analisador_rota_link_test.ts` para analisar URLs de `aresta.cc` (`/<uid>` e `/<prefixo>/<uid>` com `m`, `s`, `sm`, `ms`, `q`, `qm`, `mq`), validando o formato de UID de 14 caracteres alfanuméricos e inferindo `abrirMapa`, `origemLink`, `utmSource` e `utmMedium`.
- [x] 2.3 Seguindo TDD com espelhamento 1:1 e usando Fake determinístico de D1 (`test/banco_d1_fake.ts` e `test/banco_d1_fake_test.ts`), implementar `src/resolvedor_entidade_d1.ts` e `test/resolvedor_entidade_d1_test.ts` para resolver UIDs em `catalogo_croquis` e `catalogo_aresta` (com `JOIN` para croqui, setor pai e grupo pai), validando com `deno test`.

## 3. Renderizador HTML SSR + OpenGraph + Umami e Roteador do Worker

- [x] 3.1 Seguindo TDD com espelhamento 1:1, implementar `src/renderizador_pagina_link.ts` e `test/renderizador_pagina_link_test.ts` gerando o HTML SSR seguro (com escape anti-XSS), meta tags OpenGraph (`og:title`, `og:description`, `og:image` apontando para a thumbnail do croqui na CDN), botões da App Store e Google Play, link `aresta://aresta.cc/...`, página 404 amigável e script Umami (`https://analytics.arestaclimb.com/script.js`) disparando o evento `app-link-acesso` com `utm_source` e `utm_medium`.
- [x] 3.2 Seguindo TDD com espelhamento 1:1, implementar `src/index.ts` e `test/worker_test.ts` servindo `/health`, redirect `302` em `/` para `https://arestaclimb.com`, `/.well-known/assetlinks.json`, `/.well-known/apple-app-site-association` e as páginas SSR de entidades com `Cache-Control: public, max-age=3600, s-maxage=86400`.
- [x] 3.3 Documentar a arquitetura, rotas, cache e comandos de teste/deploy em `aresta_backend/cloudflare/app-links/README.md` e `aresta_backend/README.md`, validando 100% de cobertura comportamental com `deno test --coverage`.
