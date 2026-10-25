# Design

## Context

Durante os testes reais de entrega no celular com o Discord, constatamos que o aplicativo Desktop do Discord no Windows monitora a atividade global de mouse e teclado do sistema operacional (`GetLastInputInfo`) e suprime notificações push nos celulares Android/iOS enquanto o computador não permanece ocioso pelo tempo mínimo configurado. Para um sistema de alertas de engenharia e produção, essa supressão torna as notificações móveis pouco confiáveis.

Para resolver isso de forma definitiva, dividimos a responsabilidade entre:
1. **GitHub Issues / PRs**: Único local oficial de discussão e resolução de incidentes e bugs (sincronizado bidirecionalmente com o Sentry).
2. **Discord (`#🚨-emergencias` e `#🛠️-bugs-e-feedbacks`)**: Mural / histórico visual somente-leitura para a equipe (bloqueado para mensagens humanas e sem `@everyone`).
3. **`ntfy` (`ntfy.sh` ou instância própria com `NTFY_API_TOKEN`)**: Pager móvel oficial que entrega notificações push imediatas no celular mesmo com o computador em uso, com prioridade sonora diferenciada (`5` vs `3`) e botões de ação direta (`actions`) para abrir a Issue no GitHub ou o painel do Sentry.

## Goals / Non-Goals

**Goals:**
- Implementar `InterfaceClienteNtfy`, `ClienteNtfyFake` e `ClienteNtfyHttp` para envio de notificações push estruturadas ao `ntfy` (`POST ${NTFY_BASE_URL}` com JSON).
- Suportar autenticação opcional via `NTFY_API_TOKEN` (`Authorization: Bearer <token>`) para tópicos protegidos por controle de acesso.
- Remover `@everyone` e definir `allowed_mentions: { parse: [] }` no `ClienteDiscordHttp` para que o Discord opere como mural silencioso.
- Incluir botões de ação clicáveis (`actions: [{ action: "view", label: "Abrir no GitHub", url: ... }]`) e link de clique (`click`) nas notificações do `ntfy`.
- Enfileirar falhas do `ntfy` na `FILA_RETENTATIVAS_ALERTAS` (Cloudflare KV + Cron Trigger `*/5 * * * *`).
- Manter 100% de cobertura comportamental de testes unitários com Fakes determinísticos sem uso de mocks.

**Non-Goals:**
- Remover os Webhooks do Discord (eles permanecem ativos como mural de histórico visual).
- Remover o suporte ao WAHA em standby ou o fallback de e-mail via Resend.

## Decisions

### 1. Payload JSON do `ClienteNtfyHttp` com Prioridades e Botões de Ação
- **Decisão**: O `ClienteNtfyHttp` enviará `POST ${urlBase}` (onde `urlBase` tem como padrão `https://ntfy.sh`) com corpo JSON seguindo a especificação oficial do `ntfy`:
  ```json
  {
    "topic": "<NTFY_TOPICO_EMERGENCIAS | NTFY_TOPICO_BUGS>",
    "title": "🚨 [EMERGÊNCIA] Crash Fatal em aresta-backend",
    "message": "• Serviço: aresta-backend\n• Erro: ...\n• Discussão GitHub: https://github.com/...",
    "priority": 5,
    "tags": ["rotating_light", "emergencia"],
    "click": "https://github.com/aresta-climb/...",
    "actions": [
      { "action": "view", "label": "Discord", "url": "https://discord.com/channels/..." },
      { "action": "view", "label": "GitHub", "url": "https://github.com/..." },
      { "action": "view", "label": "Sentry", "url": "https://aresta-climb.sentry.io/..." }
    ]
  }
  ```
- **Racional**: Enviar JSON na raiz do servidor `ntfy` permite caracteres UTF-8 e emojis diretamente no `title` (o envio por cabeçalhos HTTP `X-Title` sofre limitações de codificação ASCII/MIME em proxies HTTP) e habilita os botões nativos `actions` na barra de notificações do Android/iOS.

### 2. Discord como Mural Silencioso (Remoção de `@everyone`)
- **Decisão**: A função `formatarTextoDiscordMural(texto)` removerá eventuais prefixos/sufixos `@everyone`, truncará com segurança em 1990 caracteres e enviará `allowed_mentions: { parse: [] }`.
- **Racional**: Com os canais do Discord bloqueados para conversas humanas e o `ntfy` encarregado do push móvel, remover `@everyone` evita alertas duplicados no Desktop e mantém o mural do Discord visualmente limpo.

### 3. Suporte Transparente a `NTFY_API_TOKEN`
- **Decisão**: Caso `env.NTFY_API_TOKEN` esteja definido, o `ClienteNtfyHttp` adicionará o cabeçalho `Authorization: Bearer ${env.NTFY_API_TOKEN}`.
- **Racional**: Permite tanto usar tópicos com sufixo criptográfico aleatório no `https://ntfy.sh` gratuito quanto usar tópicos autenticados por token (no `ntfy.sh` ou em container `binwiederhier/ntfy` na VM gratuita `e2-micro` do Google Cloud com `NTFY_AUTH_DEFAULT_ACCESS=deny-all`).

## Risks / Trade-offs

- **[Segurança de tópicos públicos no `ntfy.sh`]** → No `ntfy.sh` público gratuito, o nome do tópico funciona como chave compartilhada; por isso utilizamos sufixos hexadecimais aleatórios de 128 bits (`aresta-emergencias-<hex>`) ou a opção de rodar `binwiederhier/ntfy` na VM `e2-micro` com `NTFY_API_TOKEN` obrigatório.

## Migration Plan

1. Adicionar `InterfaceClienteNtfy` e `ClienteNtfyFake` em `cliente_notificacao_fake.ts` com testes unitários (*Red-Green-Refactor*).
2. Implementar `ClienteNtfyHttp`, remover `@everyone` do `ClienteDiscordHttp` e integrar o despacho e retentativas em `src/index.ts` com 100% de cobertura.
3. Atualizar `docs/guia_configuracao_observabilidade_e_alertas.md` e realizar deploy no Cloudflare Worker.
