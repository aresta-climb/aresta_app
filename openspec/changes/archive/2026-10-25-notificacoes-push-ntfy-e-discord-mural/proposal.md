# Proposal

## Why

O aplicativo Desktop do Discord no Windows suprime notificações push nos celulares (Android/iOS) sempre que o computador detecta atividade de mouse ou teclado, tornando a entrega de alertas operacionais pouco confiável para desenvolvedores que deixam o computador ligado. Separar os papéis de modo que o **Discord funcione como um mural de histórico somente-leitura** (sem menções `@everyone` e sem discussões paralelas nos canais, concentrando 100% das conversas nas Issues/PRs do GitHub) e o **`ntfy.sh` funcione como o *pager* móvel oficial de notificações push em tempo real** (com níveis de prioridade sonora distintos para Emergências vs. Bugs e botões de ação direta para abrir a Issue no GitHub) garante entrega imediata e confiável no bolso a custo zero.

## What Changes

- **Integração Nativa com `ntfy` (`ClienteNtfyHttp` + `ClienteNtfyFake`) no `aresta-alertas-worker`**:
  - Adição do contrato `InterfaceClienteNtfy` e do fake determinístico `ClienteNtfyFake` em `cliente_notificacao_fake.ts` (+ testes unitários espelhados).
  - Implementação do `ClienteNtfyHttp` enviando notificações push estruturadas (`POST ${NTFY_BASE_URL}/${topico}`) para dois tópicos dedicados (`NTFY_TOPICO_EMERGENCIAS` e `NTFY_TOPICO_BUGS`), com suporte opcional a autenticação por token (`NTFY_API_TOKEN` via `Authorization: Bearer ...`):
    - **Emergências (`🚨`)**: Prioridade máxima (`priority: 5`), tags `["rotating_light", "emergencia"]`, título com o *gist* do incidente, clique principal (`click`) e botão de ação (`actions`) apontando diretamente para a Issue no GitHub e segundo botão apontando para o Sentry/Logs.
    - **Bugs & PRs (`🛠️`)**: Prioridade padrão (`priority: 3`), tags `["hammer_and_wrench", "bug"]`, título com o *gist* da issue/PR e clique/botão apontando diretamente para a Issue ou PR no GitHub.
- **Transformação do Discord em Mural Silencioso (Remoção de `@everyone`)**:
  - Remoção da menção automática `@everyone` e de `allowed_mentions: { parse: ["everyone"] }` no `ClienteDiscordHttp`, mantendo o *gist* na primeira linha para leitura limpa nos canais bloqueados (`#🚨-emergencias` e `#🛠️-bugs-e-feedbacks`) enquanto o `ntfy` assume a responsabilidade pelas notificações push sonoras no celular.
- **Enfileiramento de Retentativas para `ntfy` e Atualização da Documentação**:
  - Inclusão de falhas de envio ao `ntfy` na fila persistente `FILA_RETENTATIVAS_ALERTAS` (Cloudflare KV + Cron Trigger `*/5 * * * *`).
  - Atualização de `docs/guia_configuracao_observabilidade_e_alertas.md` documentando os tópicos do `ntfy`, a proteção opcional por `NTFY_API_TOKEN` (inclusive auto-hospedado na VM gratuita `e2-micro`) e o bloqueio de mensagens humanas nos canais do Discord para centralizar discussões no GitHub.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capability isolada; evolução direta do roteador de alertas existente. -->

### Modified Capabilities
- `roteador-alertas-whatsapp-e-fallback`: Substituição da menção `@everyone` no Discord por despacho silencioso em mural somente-leitura combinado com notificações push móveis dedicadas via `ntfy` (`NTFY_TOPICO_EMERGENCIAS` com prioridade 5 e `NTFY_TOPICO_BUGS` com prioridade 3, botões de ação direta para GitHub/Sentry e suporte a `NTFY_API_TOKEN`).

## Impact

- **`aresta_backend`**:
  - `cloudflare/alertas/src/cliente_notificacao_fake.ts` e `cloudflare/alertas/test/cliente_notificacao_fake.test.ts` (adição de `InterfaceClienteNtfy`, `OpcoesEnvioNtfy`, `ResultadoEnvioNtfy` e `ClienteNtfyFake`).
  - `cloudflare/alertas/src/index.ts` e `cloudflare/alertas/test/index.test.ts` (implementação de `ClienteNtfyHttp`, remoção de `@everyone` no Discord, despacho paralelo Discord + ntfy e retentativas no Cron Trigger).
  - `cloudflare/alertas/wrangler.jsonc` (variável `NTFY_BASE_URL: "https://ntfy.sh"` e documentação das secrets `NTFY_TOPICO_EMERGENCIAS`, `NTFY_TOPICO_BUGS` e `NTFY_API_TOKEN`).
- **`aresta_app` (Documentação)**:
  - `docs/guia_configuracao_observabilidade_e_alertas.md` (documentação do `ntfy` e configuração dos canais somente-leitura no Discord).
