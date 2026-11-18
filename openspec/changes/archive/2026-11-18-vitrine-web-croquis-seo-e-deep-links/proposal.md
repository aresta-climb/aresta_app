# Proposal

## Why

Atualmente o acervo do Aresta Climb (~42 croquis, ~637 setores e ~4.318 escaladas) não é indexável pelo Google nem navegável no computador porque as páginas SSR de `aresta.cc` são ilhas órfãs sem `sitemap.xml`, sem links internos entre picos/setores/vias e em um domínio separado de `arestaclimb.com`. Ao mesmo tempo, portar o aplicativo Flutter para Web não resolveria SEO (devido à renderização opaca em Canvas/WASM) e traria alto custo de manutenção. Construir uma vitrine web leve, cacheável na CDN e indexável em `https://arestaclimb.com/croquis` — integrada nativamente aos Deep Links do aplicativo móvel — maximiza a descoberta orgânica no Google e o planejamento básico no desktop com custo operacional zero, convertendo visitantes diretamente para o aplicativo offline.

## What Changes

- **Extensão Geográfica do Catálogo (`aresta_api` + `aresta_db` + `aresta_app`)**: Adição das colunas opcionais `latitude_e7`, `longitude_e7` e `url_google_maps` na tabela `catalogo_croquis` (`sql/catalogo.sql` e `openapi/catalogo.yaml`), populadas a partir de `croqui.picos[0]` no compilador do catálogo, sincronizadas automaticamente com o Cloudflare D1 e migradas de forma transparente no `RepositorioCatalogo` local do aplicativo.
- **Centralização da Vitrine Web em `arestaclimb.com/croquis` (`aresta_backend`)**:
  - Configuração de Worker Route `arestaclimb.com/croquis*` no `wrangler.jsonc` do Worker `cloudflare/app-links` compartilhando o mesmo binding D1 (`aresta-catalogo`).
  - Nova página índice `GET /croquis` unindo **Mapão Nacional leve** (Leaflet + tiles gratuitos OpenFreeMap com 1 pino por croqui), **busca textual instantânea client-side** alimentada sob demanda por um índice JSON compacto (`GET /croquis/busca.json`, cacheado na CDN) e **diretório HTML agrupado por estado** para indexação integral e planejamento em desktop.
  - Endpoint `GET /croquis/sitemap.xml` listando `/croquis` e todas as URLs canônicas de croquis, grupos, setores e escaladas.
  - Páginas SSR de teaser `GET /croquis/<uid>/<slug>` (com redirecionamento `301` automático caso falte o `<slug>` ou o `<slug>` esteja desatualizado após renomeação) exibindo breadcrumbs clicáveis + JSON-LD (`BreadcrumbList`), listagem clicável de filhos (setores do pico / vias do setor com graus e modalidades, preservando fotos de croquis traçados e betas escritos exclusivos para o aplicativo), botão de localização no Google Maps e CTAs de abertura/instalação do app.
- **Redirecionamento `301` de `aresta.cc` Preservando CGI Args (`aresta_backend`)**: Rotas de entidades em `aresta.cc/<uid>` e `aresta.cc/<prefixo>/<uid>` passam a responder `301 Moved Permanently` (com cache longo na borda) para `https://arestaclimb.com/croquis/<uid>/<slug>` preservando todos os query parameters existentes e convertendo prefixos de origem/mapa em CGI args (`?mapa=1`, `utm_source`, `utm_medium`), mantendo `/.well-known/*` e `/og/<id_slug>.webp` com resposta direta `200 OK`.
- **Deep Links Unificados para `/croquis/<uid>/...` (`aresta_app` + `arestaclimb.com`)**:
  - Suporte nativo no `DeepLinkRouteParser`, `AndroidManifest.xml` e `Runner.entitlements` para interceptar `https://arestaclimb.com/croquis/<uid>` e `https://arestaclimb.com/croquis/<uid>/<slug>` (além de `?mapa=1` e parâmetros UTM), abrindo diretamente a entidade correspondente no aplicativo móvel quando instalado.
  - Escopo restrito a `/croquis/*` no `apple-app-site-association` de `arestaclimb.com`, adição de atalho de navegação para `/croquis` no site institucional e referência a `https://arestaclimb.com/croquis/sitemap.xml` em `public/robots.txt`.

## Capabilities

### New Capabilities
- `vitrine-web-croquis`: Vitrine pública SSR indexável em `https://arestaclimb.com/croquis` contendo Mapão nacional de picos, índice compacto de busca client-side (`/croquis/busca.json`), `sitemap.xml` dinâmico e páginas de teaser hierárquicas (`/croquis/<uid>/<slug>`) com dados estruturados de SEO, botão do Google Maps e cache agressivo na CDN da Cloudflare.

### Modified Capabilities
- `worker-app-links`: Evolução do Worker `cloudflare/app-links` para redirecionar (`301`) acessos de entidades em `aresta.cc` para `https://arestaclimb.com/croquis/<uid>/<slug>` preservando CGI args/UTMs e servir conjuntamente a rota `arestaclimb.com/croquis*`.
- `qr-deep-linking`: Ampliação do analisador de rotas e dos manifestos nativos Android/iOS para abrir diretamente URLs `https://arestaclimb.com/croquis/<uid>[/<slug>]` no aplicativo móvel preservando modo mapa (`?mapa=1`) e parâmetros UTM.
- `catalogo-sqlite-sync`: Inclusão dos metadados geográficos (`latitude_e7`, `longitude_e7` e `url_google_maps`) em `catalogo_croquis`, com migração não-destrutiva no SQLite local do app e atualização automática no Cloudflare D1.

## Impact

- **`aresta_api`**: `sql/catalogo.sql`, `openapi/catalogo.yaml`, `openapi/app_links.yaml` e stubs gerados em Dart, Python e TypeScript.
- **`aresta_db`**: `scripts/gerar_catalogo_sqlite_lib.py`, `scripts/gerar_deltas_catalogo.py`, `serving/sincronizar_d1_lib.py` e regeneração do `generated/catalogo.db`.
- **`aresta_backend`**: `cloudflare/app-links/` (`wrangler.jsonc`, roteador HTTP, consultas D1 em lote, gerador de slugs, renderizadores SSR do índice/mapão/teasers, `busca.json`, `sitemap.xml` e suíte de testes 100% coberta).
- **`arestaclimb.com`**: Cabeçalho/navegação com link para `/croquis`, `public/.well-known/apple-app-site-association` restrito a `/croquis/*` e `public/robots.txt` apontando para `/croquis/sitemap.xml`.
- **`aresta_app`**: `frontend/lib/navigation/analisador_rotas_deep_link.dart`, `frontend/lib/services/catalogo/repositorio_catalogo.dart`, `AndroidManifest.xml`, `Runner.entitlements` e testes unitários espelhados.
