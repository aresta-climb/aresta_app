# Tasks

## 1. Contratos SQL e OpenAPI (`aresta_api`)

- [x] 1.1 Adicionar colunas opcionais `latitude_e7`, `longitude_e7` e `url_google_maps` em `sql/catalogo.sql` e no schema `CatalogoCroqui` em `openapi/catalogo.yaml`, validando paridade 1:1 via `pytest`
- [x] 1.2 Atualizar `openapi/app_links.yaml` com as rotas da vitrine (`/croquis`, `/croquis/busca.json`, `/croquis/sitemap.xml`, `/croquis/{uid}`, `/croquis/{uid}/{slug}`), os campos hierárquicos/geográficos e o redirecionamento `301` de `aresta.cc`, regenerar os stubs via `python build.py` e verificar 100% de cobertura na suíte do `aresta_api`

## 2. Compilação do Catálogo e Sincronização D1 (`aresta_db`)

- [x] 2.1 Atualizar o submodule `aresta_api` em `aresta_db` e evoluir `scripts/gerar_catalogo_sqlite_lib.py` (com TDD em `gerar_catalogo_sqlite_lib_test.py`) para extrair `latitude_e7`, `longitude_e7` e `url_google_maps` de `croqui.picos[0]` e migrar bancos locais legados, verificando 100% de cobertura
- [x] 2.2 Atualizar `scripts/gerar_deltas_catalogo.py` e `serving/sincronizar_d1_lib.py` (com TDD nos respectivos `*_test.py`) para propagar as novas colunas nos deltas e disparar bootstrap automático no Cloudflare D1 quando ausentes, atualizar `docs/catalogo_sqlite_e_delta_sync.md` e regenerar `generated/catalogo.db`

## 3. Worker SSR da Vitrine, Mapão, Busca JSON e Redirects `301` (`aresta_backend`)

- [x] 3.1 Atualizar o submodule `aresta_api` em `aresta_backend` e criar módulo utilitário puro de geração de slugs e URLs canônicas (`/croquis/<uid>/<slug>`) com espelhamento 1:1 de testes Deno e 100% de cobertura
- [x] 3.2 Evoluir `resolvedor_entidade_d1.ts` e `banco_d1_fake.ts` (com seus testes espelhados) para consultar coordenadas/Google Maps, subentidades filhas (grupos, setores e escaladas), diretório agregado por estado para `/croquis`, índice compacto para `/croquis/busca.json` e listagem para `/croquis/sitemap.xml`, verificando 100% de cobertura
- [x] 3.3 Evoluir `analisador_rota_link.ts` e os renderizadores SSR (`renderizador_pagina_link.ts` + página índice `/croquis` com Mapão Leaflet/OpenFreeMap e busca client-side lazy + `sitemap.xml`) e atualizar `src/index.ts` e `wrangler.jsonc` (`arestaclimb.com/croquis*` + redirect `301` de `aresta.cc` preservando CGI args/UTMs), validando `README.md`, cabeçalhos SPDX e 100% de cobertura no `deno test --coverage`

## 4. Integração no Site Institucional (`arestaclimb.com`)

- [x] 4.1 Restringir `public/.well-known/apple-app-site-association` ao escopo `/croquis/*`, adicionar `Sitemap: https://arestaclimb.com/croquis/sitemap.xml` em `public/robots.txt`, incluir link de navegação `"Croquis"` (`/croquis`) nas páginas institucionais e atualizar `README.md`, verificando `npm run coverage` (100%) e `npm run build`

## 5. Deep Links e Migração do Catálogo no Aplicativo Móvel (`aresta_app`)

- [x] 5.1 Atualizar o submodule `aresta_api` em `frontend/lib/aresta_api` (e `assets/preload/catalogo.db`) e evoluir `RepositorioCatalogo` (com TDD em `repositorio_catalogo_test.dart`) para migrar automaticamente `latitude_e7`, `longitude_e7` e `url_google_maps` via `ALTER TABLE` e persistir nos deltas, verificando `flutter test` com 100% de cobertura no arquivo
- [x] 5.2 Estender `DeepLinkRouteParser` (com TDD em `analisador_rotas_deep_link_test.dart`), `AndroidManifest.xml` (`android:pathPrefix="/croquis/"` em `arestaclimb.com` e `www.arestaclimb.com` + esquema `aresta://arestaclimb.com`) e `Runner.entitlements` (`applinks:arestaclimb.com`), atualizar `frontend/README.md` e validar toda a suíte de testes do `frontend`
