# Design

## Context

Veja `proposal.md` para a motivação e escopo funcional.

Atualmente no ecossistema Aresta:
1. O aplicativo Flutter (`aresta_app`) já está preparado para gerar links `https://aresta.cc/s/<uid>` (`ServicoCompartilhamento`) e interceptar URLs `https://aresta.cc/[m|s|q|sm|ms|qm|mq]/<uid>` (`AnalisadorRotasDeepLink` e `LocalizadorDestinoUid`), além de declarar `aresta.cc` no `AndroidManifest.xml` e `Runner.entitlements`.
2. O pipeline `aresta_db/serving/sincronizar_d1_lib.py` já sincroniza e popula as tabelas `catalogo_croquis` e `catalogo_aresta` no banco Cloudflare D1 `aresta-catalogo` (`database_id: 7368d2d3-c69b-4cd5-9e2a-5ecc0ee3c830`).
3. O repositório `aresta_backend` já possui o Worker `cloudflare/catalogo` (`catalogo.arestaclimb.com`), mas ainda não possui o Worker `cloudflare/app-links` para responder pelo domínio `aresta.cc`, nem o contrato OpenAPI correspondente em `aresta_api/openapi/app_links.yaml`.

## Goals / Non-Goals

**Goals:**
- Formalizar o contrato HTTP de `https://aresta.cc` em `aresta_api/openapi/app_links.yaml` e gerar automaticamente os stubs tipados para TypeScript, Python e Dart.
- Implementar o Cloudflare Worker `cloudflare/app-links` em `aresta_backend` com arquitetura modular (separando analisador de rota/UTM, consulta ao D1 e renderizador HTML SSR/OpenGraph).
- Servir `/.well-known/assetlinks.json` e `/.well-known/apple-app-site-association` com paridade aos certificados e App IDs de produção de `arestaclimb.com`.
- Renderizar páginas HTML SSR rápidas na borda consultando o D1 (`catalogo_croquis` e `catalogo_aresta`), com meta tags OpenGraph completas (incluindo a thumbnail do croqui em `https://serving.arestaclimb.com/v4/thumbnails/<id_slug>.webp`), links para App Store / Google Play e telemetria Umami client-side.
- Garantir que o cache HTTP na CDN da Cloudflare (`Cache-Control: public, max-age=3600, s-maxage=86400`) conviva de forma transparente com o registro de 100% dos acessos humanos no Umami.

**Non-Goals:**
- Alterar o esquema SQL do Cloudflare D1 (as tabelas `catalogo_croquis` e `catalogo_aresta` já contêm todas as colunas necessárias: `croqui_uid`, `id_slug`, `nome`, `cidade`, `estado`, `uid`, `tipo`, `escalada_grau`, `escalada_tipo`, `setor_uid`, `grupo_uid`).
- Realizar chamadas bloqueantes de rede server-side do Worker para o Umami (o próprio `<script>` do Umami na página HTML executa no navegador do usuário mesmo em respostas servidas pela CDN).

## Decisions

### 1. Arquitetura Modular do Worker `cloudflare/app-links`
- **Decisão**: Estruturar `aresta_backend/cloudflare/app-links/` seguindo rigorosamente os Princípios I a VIII do `AGENTS.md` de `aresta_backend`, dividindo a responsabilidade em módulos puros e testáveis com espelhamento 1:1:
  - `src/analisador_rota_link.ts` (`test/analisador_rota_link_test.ts`): Analisa o `pathname` e `searchParams` de `aresta.cc`, extraindo `prefixo` (`m`, `s`, `sm`, `ms`, `q`, `qm`, `mq`), `uid` (14 caracteres alfanuméricos), `abrirMapa` (`boolean`), `origemLink` (`'compartilhamento' | 'qrcode' | null`), `utmSource` e `utmMedium`.
  - `src/resolvedor_entidade_d1.ts` (`test/resolvedor_entidade_d1_test.ts`): Consulta o banco D1 (`env.DB`) para resolver o `uid`:
    1. Tenta localizar em `catalogo_croquis WHERE croqui_uid = ?`.
    2. Se não for um croqui, consulta `catalogo_aresta e JOIN catalogo_croquis c ON c.croqui_uid = e.croqui_uid LEFT JOIN catalogo_aresta s ON s.uid = e.setor_uid LEFT JOIN catalogo_aresta g ON g.uid = e.grupo_uid WHERE e.uid = ?`.
    3. Retorna um objeto `ResumoEntidadeLink` tipado (do contrato gerado `app_links.ts`).
  - `src/renderizador_pagina_link.ts` (`test/renderizador_pagina_link_test.ts`): Pura função determinística que recebe `ResumoEntidadeLink` (ou `null` para 404) e os metadados da rota, escapando HTML com segurança (anti-XSS) e gerando o documento HTML completo com:
    - Meta tags OpenGraph (`og:title`, `og:description`, `og:image`, `og:url`) e Twitter Cards.
    - Cartão visual estilizado com a identidade visual do Aresta Climb, trilha de localização (`Cidade, UF › Croqui › Grupo › Setor`), badge de modalidade/graduação (quando aplicável), botões para App Store / Google Play e botão `"Abrir no aplicativo"` (`aresta://aresta.cc/...`).
    - Script do Umami (`https://analytics.arestaclimb.com/script.js`, `data-website-id="acafa0de-17ce-402b-a249-876ca5722659"`) + pequeno script inline que lê `window.location.search` e os atributos de rota para disparar `window.umami.track('app-link-acesso', { uid, tipo, abrir_mapa, origem_link, utm_source, utm_medium })`.
  - `src/index.ts` (`test/worker_test.ts`): Roteador HTTP principal orquestrando `/health`, `/`, `/.well-known/assetlinks.json`, `/.well-known/apple-app-site-association` e as rotas de UID.

### 2. Estratégia de Cache na CDN Combinada com Telemetria Umami no Cliente
- **Decisão**:
  - Respostas `200 OK` de páginas de entidades válidas recebem `Cache-Control: public, max-age=3600, s-maxage=86400`.
  - Como o script inline de telemetria dentro do HTML lê `new URLSearchParams(window.location.search)` em tempo de execução no navegador (com fallback para os valores derivados do prefixo `/s/` ou `/q/`), **mesmo que a Cloudflare CDN sirva o HTML em cache sem acionar o Worker**, o navegador do visitante executa o script do Umami e registra a visualização de página e o evento `app-link-acesso` com `utm_source` e `utm_medium` exatos.
- **Alternativa considerada**: Usar `Cache-Control: no-store` e enviar telemetria pelo servidor do Worker via `ctx.waitUntil(fetch(...))`. Descartada porque aumentaria desnecessariamente a latência (consulta ao D1 em todo acesso), consumiria cota de invocações do Worker para bots repetitivos (como pré-visualizações em grupos de WhatsApp) e perderia a detecção nativa de navegador/dispositivo do script oficial do Umami.

## Risks / Trade-offs

- **[Risk] Injeção de HTML via nomes de entidades no banco** $\rightarrow$ **Mitigation**: Toda string oriunda do D1 ou da URL (`nome`, `cidade`, `estado`, `escalada_grau`, `uid`) passa obrigatoriamente por uma função pura `escaparHtml()` antes de ser interpolada nas meta tags e no corpo HTML.
- **[Risk] Thumbnail ausente para algum croqui específico** $\rightarrow$ **Mitigation**: O campo `og:image` aponta para `https://serving.arestaclimb.com/v4/thumbnails/<id_slug>.webp` quando `id_slug` está presente, com fallback para `https://arestaclimb.com/og.png`.

## Migration Plan

1. Criar `openapi/app_links.yaml` em `aresta_api` e rodar `python build.py` + `pytest` para validar 100% dos testes do gerador.
2. Implementar `cloudflare/app-links` em `aresta_backend` seguindo TDD com `deno test --coverage` atingindo 100% de cobertura.
3. Publicar o Worker com `npx wrangler deploy` em `cloudflare/app-links` (que configura automaticamente as rotas `aresta.cc` e `www.aresta.cc` na zona Cloudflare).
