# Tasks

## 1. Contrato e Fake Determinístico do `ntfy` (`cloudflare/alertas`)

- [x] 1.1 Escrever os testes comportamentais (*Red*) em `aresta_backend/cloudflare/alertas/test/cliente_notificacao_fake.test.ts` validando o contrato de `ClienteNtfyFake` (registro de notificações push enviadas com prioridade, botões de ação e token opcional, além de simulação determinística de falha) e verificar que falham antes da implementação.
- [x] 1.2 Implementar `InterfaceClienteNtfy`, `OpcoesEnvioNtfy`, `AcaoNtfy`, `ResultadoEnvioNtfy` e `ClienteNtfyFake` em `aresta_backend/cloudflare/alertas/src/cliente_notificacao_fake.ts` (*Green*) e verificar que `deno test` passa em `test/cliente_notificacao_fake.test.ts`.

## 2. Implementação do `ClienteNtfyHttp`, Discord como Mural Silencioso e Fila de Retentativas (`cloudflare/alertas`)

- [x] 2.1 Escrever os testes comportamentais (*Red*) em `aresta_backend/cloudflare/alertas/test/index.test.ts` cobrindo: (a) envio ao Discord como mural silencioso (sem `@everyone` e com `allowed_mentions: { parse: [] }`); (b) envio ao `ntfy` via `ClienteNtfyHttp` com `priority: 5` para emergências e `priority: 3` para bugs, botões de ação apontando para a Issue/PR no GitHub e suporte a `NTFY_API_TOKEN`; (c) enfileiramento em `FILA_RETENTATIVAS_ALERTAS` quando o `ntfy` falhar e reprocessamento no Cron Trigger (`scheduled`).
- [x] 2.2 Implementar `ClienteNtfyHttp`, remover `@everyone` do `ClienteDiscordHttp` e integrar o despacho e retentativas em `aresta_backend/cloudflare/alertas/src/index.ts` (*Green*) + atualizar `wrangler.jsonc`, validando 100% de aprovação em `deno test`.

## 3. Documentação e Deploy Operacional

- [x] 3.1 Atualizar `docs/guia_configuracao_observabilidade_e_alertas.md` no `aresta_app` documentando a configuração dos tópicos do `ntfy` (`NTFY_TOPICO_EMERGENCIAS`, `NTFY_TOPICO_BUGS` e `NTFY_API_TOKEN`), a instrução para o aplicativo móvel e o bloqueio de mensagens nos canais do Discord para centralizar discussões no GitHub.
- [x] 3.2 Realizar o deploy do Worker atualizado para produção (`npx wrangler deploy`) e orientar o cadastro das secrets `NTFY_TOPICO_EMERGENCIAS` e `NTFY_TOPICO_BUGS`.
