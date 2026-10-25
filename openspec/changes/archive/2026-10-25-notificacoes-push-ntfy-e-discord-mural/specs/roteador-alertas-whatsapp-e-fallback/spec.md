# Spec Delta: roteador-alertas-whatsapp-e-fallback

## ADDED Requirements

### Requirement: Notificações Push Móveis Dedicadas via ntfy com Prioridade e Ações Diretas
Quando os tópicos do `ntfy` (`NTFY_TOPICO_EMERGENCIAS` para emergências ou `NTFY_TOPICO_BUGS` para bugs/feedbacks/PRs) estiverem configurados no ambiente do Worker, o sistema SHALL enviar uma notificação push estruturada via HTTP (`POST ${NTFY_BASE_URL}` com JSON) contendo o título resumido (*gist*), nível de prioridade diferenciado (`priority: 5` para emergências e `priority: 3` para bugs), link de clique principal (`click`) e botões de ação (`actions`) apontando diretamente para a Issue/PR no GitHub e para o Sentry/Logs, autenticando com `Authorization: Bearer ${NTFY_API_TOKEN}` quando `NTFY_API_TOKEN` estiver definido.

#### Scenario: Disparo de alerta de emergência via ntfy com prioridade máxima e botões de ação
- **WHEN** um alerta classificado como emergência for processado e `NTFY_TOPICO_EMERGENCIAS` estiver configurado no ambiente
- **THEN** o sistema DEVE enviar a notificação ao tópico de emergências no `ntfy` com `priority: 5`, tags de alerta crítico e ação clicável apontando para a GitHub Issue de emergência criada (e para o painel do Sentry/Actions).

#### Scenario: Disparo de novo bug ou PR via ntfy com prioridade padrão e link para o GitHub
- **WHEN** uma abertura ou reabertura de issue normal ou Pull Request for processada e `NTFY_TOPICO_BUGS` estiver configurado no ambiente
- **THEN** o sistema DEVE enviar a notificação ao tópico de bugs no `ntfy` com `priority: 3` e ação clicável apontando diretamente para a Issue ou Pull Request no GitHub.

#### Scenario: Autenticação com token secreto no ntfy quando configurado
- **WHEN** a variável `NTFY_API_TOKEN` estiver definida no ambiente do Worker
- **THEN** o sistema DEVE incluir o cabeçalho `Authorization: Bearer <NTFY_API_TOKEN>` em todas as requisições enviadas ao servidor `ntfy`.

## MODIFIED Requirements

### Requirement: Despacho via Webhooks do Discord com Gist na Primeira Linha e Menção no Rodapé
Quando as URLs de Webhook do Discord (`DISCORD_WEBHOOK_EMERGENCIAS_URL` para emergências ou `DISCORD_WEBHOOK_BUGS_URL` para bugs/feedbacks/PRs) estiverem configuradas no ambiente do Worker e o canal Discord estiver ativo (`CANAL_ALERTAS_ATIVO` igual a `"discord"` ou `"ambos"`), o sistema SHALL enviar a notificação ao respectivo Webhook do Discord iniciando com o resumo direto do problema (*gist*) na primeira linha e **sem menção `@everyone`** (`allowed_mentions: { parse: [] }`), operando os canais do Discord como mural de histórico somente-leitura enquanto as notificações push sonoras no celular são entregues pelo `ntfy`.

#### Scenario: Envio de alerta de emergência via Webhook do Discord com gist no topo e @everyone no rodapé
- **WHEN** um alerta classificado como emergência for processado e `DISCORD_WEBHOOK_EMERGENCIAS_URL` estiver configurada no ambiente
- **THEN** o sistema DEVE realizar um `POST` para `DISCORD_WEBHOOK_EMERGENCIAS_URL` contendo o resumo (*gist*) na primeira linha e o link da GitHub Issue de emergência criada (quando disponível), sem incluir `@everyone` e com `allowed_mentions: { parse: [] }`, retornando status HTTP `200` com `entregueVia: "discord"`.

#### Scenario: Envio de nova issue ou PR via Webhook do Discord de Bugs e Feedbacks
- **WHEN** uma abertura ou reabertura de issue (sem a label `emergencia`) ou Pull Request for processada e `DISCORD_WEBHOOK_BUGS_URL` estiver configurada no ambiente
- **THEN** o sistema DEVE realizar um `POST` para `DISCORD_WEBHOOK_BUGS_URL` contendo o resumo (*gist*) na primeira linha e os links da issue/PR sem incluir `@everyone`, retornando status HTTP `200` com `entregueVia: "discord"`.

#### Scenario: Coexistência em standby com o gateway WAHA do WhatsApp
- **WHEN** o ambiente estiver configurado com `CANAL_ALERTAS_ATIVO: "discord"` (ou sem credenciais do WAHA)
- **THEN** o sistema DEVE entregar o alerta ao Discord e ao `ntfy` (quando configurado) sem falhar por ausência ou inatividade do WAHA, mantendo o suporte ao WAHA pronto para ativação imediata via variáveis de ambiente.

### Requirement: Fila de Retentativas Assíncronas para Falhas do GitHub e do Discord
Quando a criação automática da Issue de emergência no GitHub falhar (ex: outage ou erro `5xx`/`429` na API do GitHub) ou quando o envio da notificação ao Discord ou ao `ntfy` falhar, o sistema SHALL registrar a operação pendente na fila persistente (`FILA_RETENTATIVAS_ALERTAS` via Cloudflare KV) para reprocessamento automático no próximo ciclo agendado (`scheduled` Cron Trigger).

#### Scenario: Falha ao criar Issue de emergência no GitHub notifica imediatamente no Discord e agenda retentativa
- **WHEN** o Worker tentar criar uma Issue de emergência via GitHub App e a API do GitHub retornar erro ou timeout
- **THEN** o sistema DEVE enviar imediatamente o alerta de emergência para `#🚨-emergencias` no Discord e no `ntfy` informando a indisponibilidade temporária do GitHub e enfileirar a criação da Issue em `FILA_RETENTATIVAS_ALERTAS` para nova tentativa no próximo ciclo do Cron Trigger.

#### Scenario: Reprocessamento agendado conclui criação de Issue ou entrega pendente ao Discord
- **WHEN** o Cron Trigger (`scheduled`) do Worker for executado e houver itens pendentes em `FILA_RETENTATIVAS_ALERTAS`
- **THEN** o sistema DEVE reexecutar a criação da Issue no GitHub, o envio pendente ao Discord e/ou o envio pendente ao `ntfy`, removendo o item da fila em caso de sucesso.

### Requirement: Documentação Passo a Passo de Provisionamento e Configuração
O repositório SHALL conter um guia técnico detalhado em português brasileiro (`docs/guia_configuracao_observabilidade_e_alertas.md`) documentando passo a passo a configuração do Sentry Open Source, da integração com GitHub Issues e GitHub App (`Aresta Climb Bot`), da criação dos 2 Webhooks do Discord em canais somente-leitura (`#🚨-emergencias` e `#🛠️-bugs-e-feedbacks`), dos tópicos de push móvel no `ntfy` (`NTFY_TOPICO_EMERGENCIAS`, `NTFY_TOPICO_BUGS` e `NTFY_API_TOKEN`), da fila KV de retentativas, da manutenção em *standby* da VM gratuita `e2-micro` no Google Cloud Platform com Docker (`devlikeapro/waha:noweb`) e Cloudflare Tunnel, do Webhook Organizacional do GitHub e dos segredos do Resend e Cloudflare.

#### Scenario: Consulta ao guia de configuração completa da infraestrutura
- **WHEN** um desenvolvedor consultar `docs/guia_configuracao_observabilidade_e_alertas.md` para provisionar ou auditar o ambiente de produção
- **THEN** o documento DEVE apresentar comandos reproduzíveis e instruções completas para os canais somente-leitura do Discord, assinatura dos tópicos no aplicativo móvel `ntfy`, proteção por `NTFY_API_TOKEN`, credenciais do GitHub App `Aresta Climb Bot`, fila KV `FILA_RETENTATIVAS_ALERTAS`, GCP `e2-micro` em standby e variáveis de ambiente do Cloudflare/Supabase.
