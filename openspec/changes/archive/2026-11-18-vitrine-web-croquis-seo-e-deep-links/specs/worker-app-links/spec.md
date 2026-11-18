# Spec Delta

## MODIFIED Requirements

### Requirement: Especificação OpenAPI do Serviço de App Links (`aresta.cc`)
O repositório `aresta_api` DEVE (MUST) manter o contrato OpenAPI 3.1 em `openapi/app_links.yaml` descrevendo os endpoints de borda atendidos pelo Worker unificado em `https://aresta.cc` (`/health`, `/.well-known/assetlinks.json`, `/.well-known/apple-app-site-association`, `/og/{id_slug}.webp`, `/{uid}` e `/{prefixo}/{uid}`) e na vitrine canônica `https://arestaclimb.com/croquis` (`/croquis`, `/croquis/busca.json`, `/croquis/sitemap.xml`, `/croquis/{uid}` e `/croquis/{uid}/{slug}`), gerando automaticamente as constantes de rota e tipos para TypeScript, Python e Dart via `python build.py`.

#### Scenario: Geração dos stubs de `app_links.yaml` em `aresta_api`
- **WHEN** `python build.py` é executado no `aresta_api`
- **THEN** o gerador valida `openapi/app_links.yaml` contra o schema OpenAPI 3.1 e emite os artefatos `openapi/generated/ts/app_links.ts`, `openapi/generated/python/app_links.py` e `openapi/generated/dart/app_links.dart` com todas as constantes de rota e tipos do contrato.

### Requirement: Redirecionamento da Raiz, de `www.aresta.cc` e Healthcheck Operacional
O Worker `cloudflare/app-links` DEVE (MUST) redirecionar requisições em `www.aresta.cc` com status `301 Moved Permanently` para `https://aresta.cc` preservando caminho e query string, redirecionar acessos à raiz `GET https://aresta.cc/` com status `302 Found` para `https://arestaclimb.com/croquis` e responder `200 OK` em `GET /health` indicando disponibilidade operacional.

#### Scenario: Acesso direto à raiz `https://aresta.cc/`
- **WHEN** um navegador requisita `GET https://aresta.cc/`
- **THEN** o Worker responde com status `302` e cabeçalho `Location: https://arestaclimb.com/croquis`.

#### Scenario: Acesso via subdomínio `www.aresta.cc`
- **WHEN** um navegador requisita `GET https://www.aresta.cc/s/hv7YWgTBQGyWOX`
- **THEN** o Worker responde com status `301` e cabeçalho `Location: https://aresta.cc/s/hv7YWgTBQGyWOX`.

#### Scenario: Consulta ao endpoint de saúde `GET /health`
- **WHEN** um monitor requisita `GET https://aresta.cc/health`
- **THEN** o Worker responde `200 OK` em texto plano informando que o serviço de App Links está operacional.

### Requirement: Resolução de UIDs no Cloudflare D1 e Renderização SSR com OpenGraph
Para requisições `GET /{uid}` ou `GET /{prefixo}/{uid}` em `https://aresta.cc` com prefixo válido (`m`, `s`, `sm`, `ms`, `q`, `qm`, `mq`) e `uid` alfanumérico de 14 caracteres, o Worker DEVE (MUST) consultar `catalogo_croquis` e `catalogo_aresta` no Cloudflare D1 (`aresta-catalogo`) e, se encontrado, responder `301 Moved Permanently` (`Cache-Control: public, max-age=86400, s-maxage=2592000, stale-while-revalidate=86400`) redirecionando para `https://arestaclimb.com/croquis/<uid>/<slug>` preservando todos os CGI args existentes e injetando `?mapa=1` (quando o prefixo contiver `m`) e `utm_source`/`utm_medium` derivados do prefixo (quando não fornecidos explicitamente), ou `404 Not Found` se inexistente. Na rota destino `GET https://arestaclimb.com/croquis/<uid>/<slug>`, o Worker DEVE retornar o HTML SSR (`200 OK`, `Cache-Control: public, max-age=14400, s-maxage=604800, stale-while-revalidate=86400`) com meta tags OpenGraph (`og:title`, `og:description`, `og:image` via `https://aresta.cc/og/<id_slug>.webp`), resumo hierárquico, botão do Google Maps, subentidades filhas e links para as lojas e para `aresta://arestaclimb.com/croquis/<uid>/<slug>`.

#### Scenario: Compartilhamento de Escalada no WhatsApp (`GET /s/<uid>`)
- **WHEN** o crawler do WhatsApp ou um navegador requisita `GET https://aresta.cc/s/<uid>` para um UID de escalada existente no D1 (ex.: via `"Aresta Clássica"`, grau `"6ºsup"`, modalidade `"esportiva"`, setor `"Setor Principal"`, croqui `"Pedra Grande"`, cidade `"Igarapé"`, estado `"MG"`, slug `"br_mg_igarape_pedra_grande"`)
- **THEN** o Worker em `aresta.cc` redireciona com `301 Moved Permanently` para `https://arestaclimb.com/croquis/<uid>/<slug>?utm_source=compartilhamento&utm_medium=social`, e a rota canônica responde `200 OK` com HTML contendo `og:title` com o nome e grau da via, `og:description` mencionando `Modalidade: Esportiva`, `Setor: Principal` e o croqui, `og:image` apontando para `https://aresta.cc/og/br_mg_igarape_pedra_grande.webp` e link `"Abrir no aplicativo"` apontando para `aresta://arestaclimb.com/croquis/<uid>/<slug>`.

#### Scenario: Resolução de Croqui diretamente por `croqui_uid` (`GET /<uid>`)
- **WHEN** uma requisição `GET https://aresta.cc/<croqui_uid>` corresponde a um registro na tabela `catalogo_croquis`
- **THEN** o Worker redireciona com `301 Moved Permanently` para `https://arestaclimb.com/croquis/<croqui_uid>/<slug>`, onde a página HTML resume o croqui (nome, cidade, estado, setores e botão do Google Maps quando disponível), sua thumbnail em `og:image` e os botões das lojas.

#### Scenario: UID inexistente no banco D1
- **WHEN** uma requisição `GET https://aresta.cc/s/UidInexistente` não encontra correspondência em `catalogo_croquis` nem em `catalogo_aresta`
- **THEN** o Worker responde `404 Not Found` com HTML amigável seguindo o Design System do Aresta Climb e links para a App Store, Google Play e `https://arestaclimb.com/croquis`.

### Requirement: Telemetria Umami Client-Side com Extração de Prefixos e Parâmetros UTM
A página HTML renderizada pelo Worker em `https://arestaclimb.com/croquis*` DEVE (MUST) incluir o script do Umami (`https://analytics.arestaclimb.com/script.js`, `data-website-id="3ba79f5e-e49f-42d4-9283-586976189124"`) e despachar no navegador o evento `app-link-acesso` (nas páginas de entidade) lendo `window.location.search` para capturar dinamicamente `mapa`, `utm_source`, `utm_medium` e demais CGI args mesmo quando o HTML for entregue pelo cache da CDN da Cloudflare com query string ignorada na chave de cache.

#### Scenario: Acesso no navegador via link de compartilhamento `/s/<uid>`
- **WHEN** um usuário abre `https://aresta.cc/s/hv7YWgTBQGyWOX` no navegador e é redirecionado (`301`) para `https://arestaclimb.com/croquis/hv7YWgTBQGyWOX/<slug>?utm_source=compartilhamento&utm_medium=social`
- **THEN** o script da página lê `window.location.search` e registra o acesso no Umami com `uid: "hv7YWgTBQGyWOX"`, `utm_source: "compartilhamento"` e `utm_medium: "social"` (mesmo que o HTML tenha sido servido pelo cache da CDN da Cloudflare).

#### Scenario: Acesso no navegador com parâmetros `utm_source` e `utm_medium` explícitos
- **WHEN** um usuário abre `https://aresta.cc/q/hv7YWgTBQGyWOX?utm_source=setor_igarameca&utm_medium=qrcode_placa` no navegador e chega em `https://arestaclimb.com/croquis/hv7YWgTBQGyWOX/<slug>?utm_source=setor_igarameca&utm_medium=qrcode_placa`
- **THEN** o script da página registra o evento no Umami preservando `utm_source: "setor_igarameca"` e `utm_medium: "qrcode_placa"`, anexando a query string também ao link mobile `aresta://`.

### Requirement: Botões Clássicos das Lojas com Logotipo e Abertura Nativa Restrita ao Mobile
O banner de download DEVE (MUST) apresentar os botões `.store-badge` da Apple App Store e da Google Play contendo seus respectivos ícones vetoriais SVG oficiais, incluir a meta tag `<meta name="apple-itunes-app">` apontando para a URL canônica da entidade e exibir o link secundário `"Já tem o Aresta instalado? Abrir no aplicativo →"` (`aresta://arestaclimb.com/croquis/<uid>/<slug>`) exclusivamente em viewports móveis, ocultando-o em viewports desktop.

#### Scenario: Exibição dos botões das lojas com SVG e ocultação do link nativo no desktop
- **WHEN** a página da entidade é renderizada em `/croquis/<uid>/<slug>`
- **THEN** os botões da App Store e da Google Play contêm os ícones `<svg>` oficiais com os rótulos `"Disponível na / App Store"` e `"Disponível no / Google Play"`, e o bloco com o link `aresta://arestaclimb.com/croquis/...` possui regra responsiva que o oculta em telas desktop (`min-width: 820px`).
