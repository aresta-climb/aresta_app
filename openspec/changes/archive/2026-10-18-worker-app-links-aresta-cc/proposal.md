# Proposal

## Why

O aplicativo `aresta_app` já gera e interpreta links curtos `https://aresta.cc/[m|s|q|sm|ms|qm|mq]/<uid>` para compartilhamento de croquis, grupos, setores e escaladas, bem como para leitura de placas físicas QR Code na rocha. Contudo, o domínio `aresta.cc` ainda não possui seu Worker de borda (`cloudflare/app-links`) no `aresta_backend` nem sua especificação OpenAPI no `aresta_api`, o que impede a verificação nativa de App Links / Universal Links (`/.well-known/assetlinks.json` e `/.well-known/apple-app-site-association`), a pré-visualização OpenGraph no WhatsApp/redes sociais e a página de fallback SSR consultando o banco Cloudflare D1 para usuários que ainda não possuem o aplicativo instalado.

## What Changes

- **Especificação OpenAPI (`aresta_api/openapi/app_links.yaml`) e Geração de Contratos**:
  - Definir o contrato OpenAPI 3.1 para o serviço `https://aresta.cc` (`cloudflare/app-links`), incluindo:
    - `GET /health`: Healthcheck operacional do Worker.
    - `GET /.well-known/assetlinks.json`: Manifesto Digital Asset Links para verificação automática de Android App Links (`app.escalada.croquis`).
    - `GET /.well-known/apple-app-site-association`: Manifesto Apple App Site Association (AASA) para verificação automática de iOS Universal Links (`Z74K7R3WU7.app.escalada.croquis`).
    - `GET /{uid}` e `GET /{prefixo}/{uid}` (com `prefixo` $\in \{\text{'m'}, \text{'s'}, \text{'sm'}, \text{'ms'}, \text{'q'}, \text{'qm'}, \text{'mq'}\}$): Renderização SSR de página HTML enriquecida com metadados OpenGraph (`og:title`, `og:description`, `og:image` apontando para a thumbnail do croqui na CDN), resumo da entidade consultada no Cloudflare D1 (`catalogo_croquis` e `catalogo_aresta`), links para App Store / Google Play, botão de abertura direta via custom scheme (`aresta://aresta.cc/...`) e telemetria Umami client-side registrando `utm_source` e `utm_medium`.
  - Executar `python build.py` no `aresta_api` para gerar os stubs em TypeScript, Python e Dart e sincronizar o submódulo quando aplicável.
- **Cloudflare Worker `cloudflare/app-links` (`aresta_backend`)**:
  - Criar o Worker `aresta-app-links` em `aresta_backend/cloudflare/app-links/` conectado ao banco Cloudflare D1 `aresta-catalogo` (`binding: DB`).
  - Redirecionar `GET /` (raiz sem UID) com `302 Found` para `https://arestaclimb.com`.
  - Servir `/.well-known/assetlinks.json` e `/.well-known/apple-app-site-association` com `application/json` e cache na borda.
  - Consultar as tabelas `catalogo_croquis` e `catalogo_aresta` no D1 para qualquer `<uid>` válido de 14 caracteres alfanuméricos, montando o resumo da entidade (Croqui, Grupo, Setor ou Escalada com grau, modalidade e localização) e retornando HTML SSR estilizado com cache na CDN (`Cache-Control: public, max-age=3600, s-maxage=86400`) e script do Umami (`https://analytics.arestaclimb.com/script.js`) que registra no navegador o acesso e os parâmetros `utm_source` / `utm_medium` (explícitos na query string ou inferidos dos prefixos `/s/`, `/q/`, `/m/`).
  - Retornar página HTML 404 amigável com links de download do aplicativo quando o `<uid>` ou rota não existir no catálogo D1.
  - Garantir espelhamento 1:1 de testes e 100% de cobertura comportamental via `deno test` em `cloudflare/app-links/`.

## Capabilities

### New Capabilities
- `worker-app-links`: Especificação OpenAPI (`app_links.yaml`) e Cloudflare Worker (`cloudflare/app-links`) para o domínio `aresta.cc`, cobrindo verificação `.well-known` (Android App Links e iOS Universal Links), redirecionamento da raiz para `arestaclimb.com`, resolução de entidades no Cloudflare D1 com geração de página HTML SSR + OpenGraph para preview em redes sociais/WhatsApp e telemetria Umami com suporte a prefixos compactos e parâmetros UTM.

### Modified Capabilities

## Impact

- **`aresta_api`**:
  - Novo arquivo `openapi/app_links.yaml` e contratos gerados em `openapi/generated/{ts,python,dart}/app_links.*`.
- **`aresta_backend`**:
  - Novo Cloudflare Worker em `cloudflare/app-links/` (`wrangler.jsonc`, `deno.json`, `package.json`, ` README.md`, `src/` e `test/`).
- **`aresta_app`**:
  - Atualização da referência/contratos de `aresta_api` e documentação arquitetural da mudança.
