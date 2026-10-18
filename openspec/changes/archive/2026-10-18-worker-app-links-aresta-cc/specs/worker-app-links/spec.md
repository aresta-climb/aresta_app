# Spec Delta

## Purpose

Definir o contrato OpenAPI (`openapi/app_links.yaml`) e o comportamento de borda do Cloudflare Worker `cloudflare/app-links` (`https://aresta.cc`) para verificação nativa de App Links / Universal Links, resolução de UIDs no banco Cloudflare D1 (`aresta-catalogo`), renderização de página HTML SSR com metadados OpenGraph (para preview no WhatsApp e redes sociais), links para download do aplicativo e telemetria Umami com suporte a prefixos compactos (`/s/`, `/q/`, `/m/`, `/sm/`, `/ms/`, `/qm/`, `/mq/`) e parâmetros UTM.

## ADDED Requirements

### Requirement: Especificação OpenAPI do Serviço de App Links (`aresta.cc`)
O repositório `aresta_api` DEVE (MUST) manter o contrato OpenAPI 3.1 em `openapi/app_links.yaml` descrevendo os endpoints servidos por `https://aresta.cc` (`/health`, `/.well-known/assetlinks.json`, `/.well-known/apple-app-site-association`, `/{uid}` e `/{prefixo}/{uid}`) e seus schemas estruturais, gerando automaticamente as constantes de rota e tipos para TypeScript, Python e Dart via `python build.py`.

#### Scenario: Geração dos stubs de `app_links.yaml` em `aresta_api`
- **WHEN** `python build.py` é executado no `aresta_api`
- **THEN** o gerador valida `openapi/app_links.yaml` contra o schema OpenAPI 3.1 e emite os artefatos `openapi/generated/ts/app_links.ts`, `openapi/generated/python/app_links.py` e `openapi/generated/dart/app_links.dart` com todas as constantes de rota e tipos do contrato.

### Requirement: Verificação de Domínio para Android App Links e iOS Universal Links
O Worker `cloudflare/app-links` DEVE (MUST) responder com `200 OK` e `Content-Type: application/json; charset=utf-8` aos endpoints:
- `GET /.well-known/assetlinks.json`: retornando a declaração `delegate_permission/common.handle_all_urls` para o pacote Android `app.escalada.croquis` e suas impressões digitais SHA-256 oficiais.
- `GET /.well-known/apple-app-site-association`: retornando a configuração `applinks` para o identificador `Z74K7R3WU7.app.escalada.croquis` cobrindo `/*`.

#### Scenario: Verificação automática pelo sistema operacional Android
- **WHEN** o Android requisita `GET https://aresta.cc/.well-known/assetlinks.json`
- **THEN** o Worker responde `200 OK` com JSON válido contendo `package_name: "app.escalada.croquis"` e os fingerprints SHA-256 de produção/debug, além de `Cache-Control: public, max-age=86400, s-maxage=86400`.

#### Scenario: Verificação automática pelo sistema operacional iOS
- **WHEN** o iOS requisita `GET https://aresta.cc/.well-known/apple-app-site-association`
- **THEN** o Worker responde `200 OK` com JSON válido contendo `appIDs: ["Z74K7R3WU7.app.escalada.croquis"]` e `paths: ["/*"]`, além de `Cache-Control: public, max-age=86400, s-maxage=86400`.

### Requirement: Redirecionamento da Raiz e Healthcheck Operacional
O Worker `cloudflare/app-links` DEVE (MUST) redirecionar acessos à raiz `GET /` com status `302 Found` para `https://arestaclimb.com` e responder `200 OK` em `GET /health` indicando disponibilidade operacional.

#### Scenario: Acesso direto à raiz `https://aresta.cc/`
- **WHEN** um navegador requisita `GET https://aresta.cc/`
- **THEN** o Worker responde com status `302` e cabeçalho `Location: https://arestaclimb.com`.

#### Scenario: Consulta ao endpoint de saúde `GET /health`
- **WHEN** um monitor requisita `GET https://aresta.cc/health`
- **THEN** o Worker responde `200 OK` em texto plano informando que o serviço de App Links está operacional.

### Requirement: Resolução de UIDs no Cloudflare D1 e Renderização SSR com OpenGraph
Para requisições `GET /{uid}` ou `GET /{prefixo}/{uid}` (onde `prefixo` $\in \{\text{'m'}, \text{'s'}, \text{'sm'}, \text{'ms'}, \text{'q'}, \text{'qm'}, \text{'mq'}\}$ e `uid` possui 14 caracteres alfanuméricos `[A-Za-z0-9]{14}`), o Worker DEVE (MUST) consultar as tabelas `catalogo_croquis` e `catalogo_aresta` no banco Cloudflare D1 (`aresta-catalogo`) e retornar uma página HTML (`200 OK`, `Content-Type: text/html; charset=utf-8`, `Cache-Control: public, max-age=3600, s-maxage=86400`) contendo:
1. Meta tags OpenGraph (`og:title`, `og:description`, `og:image`, `og:url`, `twitter:card`) com o título, resumo contextualizado em português (Croqui, Grupo, Setor ou Escalada com graduação, modalidade e localização) e URL da thumbnail do croqui (`https://serving.arestaclimb.com/v4/thumbnails/<id_slug>.webp`).
2. Cartão visual resumindo a entidade, botões oficiais de download na Apple App Store e Google Play e link de abertura direta no aplicativo via esquema `aresta://aresta.cc/...`.
3. Caso o `uid` não seja encontrado no D1 ou o caminho seja inválido, DEVE retornar status `404 Not Found` com página HTML amigável contendo os links para baixar o aplicativo.

#### Scenario: Compartilhamento de Escalada no WhatsApp (`GET /s/<uid>`)
- **WHEN** o crawler do WhatsApp ou um navegador requisita `GET https://aresta.cc/s/<uid>` para um UID de escalada existente no D1 (ex.: via `"Aresta Clássica"`, grau `"6ºsup"`, setor `"Setor Principal"`, croqui `"Pedra Grande"`, cidade `"Igarapé"`, estado `"MG"`, slug `"br_mg_igarape_pedra_grande"`)
- **THEN** o Worker responde `200 OK` com HTML contendo `og:title` com o nome e grau da via, `og:description` mencionando o setor e o croqui (`Pedra Grande — Igarapé, MG`), `og:image` apontando para `https://serving.arestaclimb.com/v4/thumbnails/br_mg_igarape_pedra_grande.webp` e botão `"Abrir no aplicativo"` apontando para `aresta://aresta.cc/s/<uid>`.

#### Scenario: Resolução de Croqui diretamente por `croqui_uid` (`GET /<uid>`)
- **WHEN** uma requisição `GET https://aresta.cc/<croqui_uid>` corresponde a um registro na tabela `catalogo_croquis`
- **THEN** o Worker responde `200 OK` com HTML resumindo o croqui (nome, cidade e estado), sua thumbnail em `og:image` e os botões das lojas.

#### Scenario: UID inexistente no banco D1
- **WHEN** uma requisição `GET https://aresta.cc/s/UidInexistente` não encontra correspondência em `catalogo_croquis` nem em `catalogo_aresta`
- **THEN** o Worker responde `404 Not Found` com HTML amigável e links para a App Store, Google Play e `https://arestaclimb.com`.

### Requirement: Telemetria Umami Client-Side com Extração de Prefixos e Parâmetros UTM
A página HTML renderizada pelo Worker `cloudflare/app-links` DEVE (MUST) incluir o script oficial do Umami (`https://analytics.arestaclimb.com/script.js` com `data-website-id="3ba79f5e-e49f-42d4-9283-586976189124"`) e despachar no navegador um evento estruturado `app-link-acesso` contendo `uid`, `tipo`, `abrir_mapa` e os valores efetivos de `utm_source` e `utm_medium` (priorizando os query parameters explícitos `?utm_source=...&utm_medium=...` e usando como fallback os valores derivados dos prefixos `/s/`, `/sm/`, `/ms/` $\rightarrow$ `utm_source: "compartilhamento", utm_medium: "social"` e `/q/`, `/qm/`, `/mq/` $\rightarrow$ `utm_source: "placa_rocha", utm_medium: "qrcode"`).

#### Scenario: Acesso no navegador via link de compartilhamento `/s/<uid>`
- **WHEN** um usuário abre `https://aresta.cc/s/hv7YWgTBQGyWOX` no navegador
- **THEN** o script da página registra o acesso no Umami com `uid: "hv7YWgTBQGyWOX"`, `utm_source: "compartilhamento"` e `utm_medium: "social"` (mesmo que o HTML tenha sido servido pelo cache da CDN da Cloudflare).

#### Scenario: Acesso no navegador com parâmetros `utm_source` e `utm_medium` explícitos
- **WHEN** um usuário abre `https://aresta.cc/q/hv7YWgTBQGyWOX?utm_source=setor_igarameca&utm_medium=qrcode_placa` no navegador
- **THEN** o script da página registra o evento no Umami preservando `utm_source: "setor_igarameca"` e `utm_medium: "qrcode_placa"`.
