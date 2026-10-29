# roteador-alertas-whatsapp-e-fallback Specification

## Purpose

Prover um roteador central de webhooks (`cloudflare/alertas`) capaz de autenticar e classificar eventos críticos do Sentry e da organização GitHub (`aresta-climb`), despachando notificações formatadas em tempo real para dois grupos de WhatsApp via gateway WAHA com fallback automático por e-mail via Resend (`contato@arestaclimb.com`) e documentação completa de provisionamento.

## Requirements

### Requirement: Autenticação Criptográfica de Webhooks do Sentry e GitHub
O Worker de alertas SHALL validar a assinatura HMAC-SHA256 de todas as requisições recebidas nos endpoints `/webhook/sentry` (`sentry-hook-signature`) e `/webhook/github` (`x-hub-signature-256`) antes de processar qualquer carga útil, rejeitando requisições não autenticadas com status HTTP `401`.

#### Scenario: Webhook do GitHub com assinatura HMAC válida
- **WHEN** uma requisição `POST /webhook/github` for recebida com cabeçalho `x-hub-signature-256` correspondente ao HMAC-SHA256 do corpo usando `GITHUB_WEBHOOK_SECRET`
- **THEN** o sistema DEVE autenticar a requisição e processar o evento com status HTTP `200`.

#### Scenario: Rejeição de requisição com assinatura inválida ou ausente
- **WHEN** uma requisição `POST /webhook/sentry` ou `POST /webhook/github` for recebida sem cabeçalho de assinatura ou com assinatura divergente do segredo configurado
- **THEN** o sistema DEVE rejeitar a requisição imediatamente com status HTTP `401` e não disparar mensagens ao WhatsApp ou Resend.

### Requirement: Roteamento de Emergências Críticas para o Grupo 1 do WhatsApp
O sistema SHALL encaminhar imediatamente para os canais de emergência (`#🚨-emergencias` no Discord, `NTFY_TOPICO_EMERGENCIAS` com `priority: 5` e `WHATSAPP_GROUP_EMERGENCIA_ID` quando ativo) todo alerta crítico do Sentry (crashes fatais, picos de erro ou queda de uptime), toda falha no workflow `Deploy para Cloudflare R2 e D1` (`deploy.yml` em `aresta-climb/aresta_db`) e toda falha inesperada de infraestrutura/script nos workflows `pr-*.yml` de `aresta-climb/aresta_db`. As demais falhas de `workflow_run` ocorridas nas branches `main`, `master` ou tags `v*`, bem como falhas de deploy externo (`check_run` da Cloudflare e `status` da Vercel), SHALL ser classificadas como `bugs` (abrindo automaticamente uma GitHub Issue com a label `bug` e notificando `#🛠️-bugs-e-feedbacks` e `NTFY_TOPICO_BUGS` com `priority: 3`).

#### Scenario: Alerta de crash fatal ou spike originado no Sentry
- **WHEN** o endpoint `POST /webhook/sentry` receber um alerta de regra de emergência (nível `fatal`, anomalia de velocidade/spike ou monitor de uptime offline)
- **THEN** o sistema DEVE formatar o resumo contendo projeto, ambiente, mensagem do erro e link direto do Sentry, criar uma GitHub Issue com label `emergencia` e enviá-lo para os canais de emergência.

#### Scenario: Falha de deploy ou CI na branch principal no GitHub Actions
- **WHEN** o endpoint `POST /webhook/github` receber um evento `workflow_run` com `action === "completed"`, `conclusion === "failure"` e `head_branch === "main"`
- **THEN** o sistema DEVE enviar um alerta de emergência para `#🚨-emergencias` e `NTFY_TOPICO_EMERGENCIAS` (com abertura de Issue `emergencia`) caso seja o workflow `deploy.yml` do `aresta_db`, ou classificar como `bugs` (abrindo Issue `bug` e notificando `#🛠️-bugs-e-feedbacks` e `NTFY_TOPICO_BUGS`) para os demais workflows gerais e deploys externos da Cloudflare/Vercel.

#### Scenario: Falha de workflow em branch de feature ignorada pelo canal de emergência
- **WHEN** o endpoint `POST /webhook/github` receber um evento `workflow_run` comum (que não seja `pr-*.yml` ou `deploy.yml` do `aresta_db`) com `conclusion === "failure"` em uma branch secundária de desenvolvimento (diferente de `main`, `master` e `v*`)
- **THEN** o sistema DEVE retornar HTTP `200` ignorando o disparo para evitar ruído.

### Requirement: Roteamento de Novas Issues e Pull Requests para o Grupo 2 do WhatsApp
O sistema SHALL encaminhar para o grupo de WhatsApp `🛠️ Grupo 2 — Bugs & Feedbacks` (`WHATSAPP_GROUP_TRIAGEM_ID`) toda nova issue aberta (`issues` com `action === "opened"`) e todo novo Pull Request aberto (`pull_request` com `action === "opened"`) em qualquer repositório da organização `aresta-climb`, extraindo e destacando o link do Sentry quando a issue tiver sido gerada pela integração do Sentry.

#### Scenario: Nova issue aberta automaticamente pelo Sentry na primeira ocorrência
- **WHEN** o endpoint `POST /webhook/github` receber um evento `issues` com `action === "opened"` cujo corpo contenha um link de evento do Sentry (`sentry.io`)
- **THEN** o sistema DEVE enviar notificação para `WHATSAPP_GROUP_TRIAGEM_ID` contendo repositório, número e título da issue, link da issue no GitHub e link direto para o diagnóstico privado no Sentry.

#### Scenario: Nova issue de feedback do usuário ou novo PR de submissão de croqui
- **WHEN** o endpoint `POST /webhook/github` receber `issues` (`action === "opened"`) criado pelo `app-feedback` ou `pull_request` (`action === "opened"`) criado pelo `create-pr`
- **THEN** o sistema DEVE enviar notificação formatada para `WHATSAPP_GROUP_TRIAGEM_ID` com o título, autor/origem e link direto no GitHub.

### Requirement: Fallback Automático por E-mail via Resend sem Loop de Erro
Quando o envio da notificação para o canal primário configurado (Webhook do Discord e/ou gateway WAHA do WhatsApp) falhar por erro de rede, timeout, ausência de canal primário configurado ou status HTTP diferente de `2xx`, o sistema SHALL disparar automaticamente o conteúdo do alerta por e-mail utilizando a API do Resend (`POST https://api.resend.com/emails`) para `contato@arestaclimb.com` (com remetente `alerta@login.arestaclimb.com`), enfileirar a entrega para nova tentativa no Discord (quando aplicável) e abster-se de registrar exceção recursiva no Sentry caso o próprio alerta seja oriundo de falha.

#### Scenario: Indisponibilidade da VM do WAHA aciona envio via Resend
- **WHEN** o Worker `cloudflare/alertas` tentar enviar uma mensagem ao endpoint REST do WAHA e receber erro HTTP `502`/`503` ou timeout
- **THEN** o sistema DEVE enviar um e-mail via API do Resend para `contato@arestaclimb.com` contendo o alerta original na íntegra acrescido de um banner avisando o motivo da falha no gateway do WhatsApp.

#### Scenario: Sucesso no envio ao WhatsApp não aciona o Resend
- **WHEN** o gateway WAHA responder com status HTTP `200` ou `201` ao envio da mensagem de alerta
- **THEN** o sistema NÃO DEVE invocar a API do Resend.

#### Scenario: Indisponibilidade do Webhook do Discord aciona envio via Resend e agenda retentativa na fila
- **WHEN** o Worker `cloudflare/alertas` tentar enviar uma mensagem ao Webhook do Discord e receber erro HTTP (`500`/`502`/`503`/`429`) ou falha de conexão
- **THEN** o sistema DEVE enviar um e-mail via API do Resend para `contato@arestaclimb.com` contendo o alerta original na íntegra acrescido de um banner avisando o motivo da falha no Discord e registrar a mensagem na fila `FILA_RETENTATIVAS_ALERTAS` para reenvio posterior ao Discord.

#### Scenario: Sucesso no envio ao Discord não aciona o Resend
- **WHEN** o Webhook do Discord responder com status HTTP `2xx` (`200` ou `204`) ao envio da mensagem de alerta
- **THEN** o sistema NÃO DEVE invocar a API do Resend.

### Requirement: Documentação Passo a Passo de Provisionamento e Configuração
O repositório SHALL conter um guia técnico detalhado em português brasileiro (`docs/guia_configuracao_observabilidade_e_alertas.md`) documentando passo a passo a configuração do Sentry Open Source, da integração com GitHub Issues e GitHub App (`Aresta Climb Bot`), da criação dos 2 Webhooks do Discord em canais somente-leitura (`#🚨-emergencias` e `#🛠️-bugs-e-feedbacks`), dos tópicos de push móvel no `ntfy` (`NTFY_TOPICO_EMERGENCIAS`, `NTFY_TOPICO_BUGS` e `NTFY_API_TOKEN`), da fila KV de retentativas, da manutenção em *standby* da VM gratuita `e2-micro` no Google Cloud Platform com Docker (`devlikeapro/waha:noweb`) e Cloudflare Tunnel, do Webhook Organizacional do GitHub e dos segredos do Resend e Cloudflare.

#### Scenario: Consulta ao guia de configuração completa da infraestrutura
- **WHEN** um desenvolvedor consultar `docs/guia_configuracao_observabilidade_e_alertas.md` para provisionar ou auditar o ambiente de produção
- **THEN** o documento DEVE apresentar comandos reproduzíveis e instruções completas para os canais somente-leitura do Discord, assinatura dos tópicos no aplicativo móvel `ntfy`, proteção por `NTFY_API_TOKEN`, credenciais do GitHub App `Aresta Climb Bot`, fila KV `FILA_RETENTATIVAS_ALERTAS`, GCP `e2-micro` em standby e variáveis de ambiente do Cloudflare/Supabase.

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

### Requirement: Notificações Push Móveis Dedicadas via ntfy com Prioridade e Ações Diretas
Quando os tópicos do `ntfy` (`NTFY_TOPICO_EMERGENCIAS` para emergências ou `NTFY_TOPICO_BUGS` para bugs/feedbacks/PRs) estiverem configurados no ambiente do Worker, o sistema SHALL enviar uma notificação push estruturada via HTTP (`POST ${NTFY_BASE_URL}` com JSON) contendo o título resumido (*gist*), nível de prioridade diferenciado (`priority: 5` para emergências e `priority: 3` para bugs), ícone WebP customizado por categoria (`icon`), link de clique principal (`click`) e até 3 botões de ação (`actions`: `"Discord"`, `"GitHub"`, `"Sentry"`) apontando diretamente para a mensagem publicada no mural do Discord, a Issue/PR no GitHub e o evento no Sentry/Logs, autenticando com `Authorization: Bearer ${NTFY_API_TOKEN}` quando `NTFY_API_TOKEN` estiver definido.

#### Scenario: Disparo de alerta de emergência via ntfy com prioridade máxima e botões de ação
- **WHEN** um alerta classificado como emergência for processado e `NTFY_TOPICO_EMERGENCIAS` estiver configurado no ambiente
- **THEN** o sistema DEVE enviar a notificação ao tópico de emergências no `ntfy` com `priority: 5`, ícone `emergencia.webp`, tags de alerta crítico e botões de ação clicáveis (`"Discord"`, `"GitHub"`, `"Sentry"`) apontando para o mural do Discord, a GitHub Issue de emergência criada e o painel do Sentry/Actions.

#### Scenario: Disparo de novo bug ou PR via ntfy com prioridade padrão e link para o GitHub
- **WHEN** uma abertura ou reabertura de issue normal ou Pull Request for processada e `NTFY_TOPICO_BUGS` estiver configurado no ambiente
- **THEN** o sistema DEVE enviar a notificação ao tópico de bugs no `ntfy` com `priority: 3`, ícone `feedback_bugs.webp` e botões de ação apontando diretamente para a mensagem no Discord e para a Issue ou Pull Request no GitHub (e para o Sentry quando houver link).

#### Scenario: Autenticação com token secreto no ntfy quando configurado
- **WHEN** a variável `NTFY_API_TOKEN` estiver definida no ambiente do Worker
- **THEN** o sistema DEVE incluir o cabeçalho `Authorization: Bearer <NTFY_API_TOKEN>` em todas as requisições enviadas ao servidor `ntfy`.

### Requirement: Criação Automática de GitHub Issues de Emergência via GitHub App e Deduplicação por Label
Quando o Worker receber um evento de emergência ou de bug de CI/deploy que ainda não possua uma GitHub Issue associada (Crash Fatal, Spike de `metric_alert` ou Queda de Uptime no Sentry, erro não-fatal inédito no Sentry, falha de `deploy.yml` ou erro inesperado nos `pr-*.yml` do `aresta_db`, ou falha de `workflow_run`/`check_run`/`status` em `main`/`v*`), o sistema SHALL autenticar utilizando o GitHub App `Aresta Climb Bot` (`ARESTA_CLIMB_BOT_GITHUB_APP_CLIENT_ID`, `ARESTA_CLIMB_BOT_GITHUB_APP_PRIVATE_KEY`, `ARESTA_CLIMB_BOT_GITHUB_APP_INSTALLATION_ID`), criar automaticamente uma nova Issue com a label correspondente (`emergencia` ou `bug`) no repositório da organização `aresta-climb` e incluir o link da Issue recém-criada na notificação enviada ao Discord e ao `ntfy`. Adicionalmente, ao receber eventos `issues` (`action: "opened"`) do GitHub cuja issue tenha sido aberta pelo próprio `aresta-climb-bot` para falhas de CI/deploy ou que possua a label `emergencia`, o sistema SHALL evitar notificações duplicadas.

#### Scenario: Emergência do Sentry ou falha de GitHub Actions cria Issue com label emergencia e notifica com link
- **WHEN** o Worker receber um webhook válido de emergência do Sentry (`metric_alert`, `issue.created` fatal ou `event_alert` fatal) ou falha de `deploy.yml` / erro inesperado em `pr-*.yml` do `aresta_db` e as credenciais do GitHub App estiverem configuradas
- **THEN** o sistema DEVE criar uma Issue no repositório correspondente com a label `emergencia` via API do GitHub e enviar a notificação ao canal `#🚨-emergencias` e `NTFY_TOPICO_EMERGENCIAS` contendo o `html_url` da Issue criada.

#### Scenario: Abertura de Issue com label emergencia é ignorada para evitar duplicação
- **WHEN** o Worker receber um webhook do GitHub `issues` com `action: "opened"` cuja issue possua a label `emergencia` (ou tenha sido recém-aberta pelo próprio bot para falha de CI/deploy já despachada)
- **THEN** o sistema DEVE encerrar o processamento imediatamente retornando status HTTP `200` (`ignorado: true`), sem enviar notificação duplicada ao canal `#🛠️-bugs-e-feedbacks` nem ao `#🚨-emergencias`.

#### Scenario: Reabertura de Issue é notificada no canal correspondente à sua severidade
- **WHEN** o Worker receber um webhook do GitHub `issues` com `action: "reopened"` (ou `pull_request` com `action: "reopened"`)
- **THEN** o sistema DEVE enviar a notificação de reabertura para `#🛠️-bugs-e-feedbacks` caso não possua a label `emergencia`, ou para `#🚨-emergencias` caso possua a label `emergencia`.

### Requirement: Fila de Retentativas Assíncronas para Falhas do GitHub e do Discord
Quando a criação automática de uma Issue no GitHub (seja `emergencia` ou `bug`, incluindo erros não-fatais do Sentry e falhas de CI/CD) falhar (ex: outage ou erro `5xx`/`429` na API do GitHub) ou quando o envio da notificação ao Discord ou ao `ntfy` falhar, o sistema SHALL registrar a operação pendente na fila persistente (`FILA_RETENTATIVAS_ALERTAS` via Cloudflare KV) para reprocessamento automático no próximo ciclo agendado (`scheduled` Cron Trigger), garantindo o envio imediato do alerta ao Discord e ao `ntfy` mesmo durante indisponibilidades do GitHub.

#### Scenario: Falha ao criar Issue de emergência no GitHub notifica imediatamente no Discord e agenda retentativa
- **WHEN** o Worker tentar criar uma Issue (`emergencia` ou `bug`, inclusive para um erro não-fatal inédito do Sentry) via GitHub App e a API do GitHub retornar erro ou timeout
- **THEN** o sistema DEVE enviar imediatamente o alerta para o canal correspondente do Discord e do `ntfy` informando a indisponibilidade temporária do GitHub e enfileirar a criação da Issue em `FILA_RETENTATIVAS_ALERTAS` para nova tentativa no próximo ciclo do Cron Trigger.

#### Scenario: Reprocessamento agendado conclui criação de Issue ou entrega pendente ao Discord
- **WHEN** o Cron Trigger (`scheduled`) do Worker for executado e houver itens pendentes em `FILA_RETENTATIVAS_ALERTAS`
- **THEN** o sistema DEVE reexecutar a criação da Issue no GitHub, o envio pendente ao Discord e/ou o envio pendente ao `ntfy`, removendo o item da fila em caso de sucesso.

### Requirement: Sincronização Bidirecional de Status de Issues entre Sentry e GitHub
O sistema SHALL sincronizar bidirecionalmente o estado de resolução/fechamento e reabertura de issues entre o Sentry e o GitHub utilizando `SENTRY_API_TOKEN` e o GitHub App `Aresta Climb Bot`, prevenindo loops infinitos quando a própria automação realizar a alteração de status.

#### Scenario: Fechamento ou reabertura de Issue no GitHub atualiza o status correspondente no Sentry
- **WHEN** o Worker receber um webhook do GitHub `issues` com `action: "closed"` ou `action: "reopened"` originado por um usuário humano (`sender.type !== "Bot"`), cujo corpo da issue contenha um link de Issue do Sentry (`sentry.io/issues/<ID>`)
- **THEN** o sistema DEVE enviar uma requisição `PUT https://sentry.io/api/0/issues/<ID>/` com `status: "resolved"` (quando fechada) ou `status: "unresolved"` (quando reaberta).

#### Scenario: Resolução, arquivamento ou reabertura de Issue no Sentry atualiza a Issue vinculada no GitHub
- **WHEN** o Worker receber um webhook do Sentry com `sentry-hook-resource: issue` e `action` igual a `"resolved"`, `"archived"`, `"ignored"` ou `"unresolved"`
- **THEN** o sistema DEVE buscar a Issue correspondente na organização `aresta-climb` via GitHub App (`in:body "issues/<ID>"`) e atualizar seu estado para `"closed"` (quando resolvida/arquivada/ignorada) ou `"open"` (quando marcada como `"unresolved"`), criando automaticamente uma nova Issue (`emergencia` se `fatal`, ou `bug` se não-fatal) caso a ação seja `"unresolved"` e nenhuma Issue correspondente exista no GitHub.

#### Scenario: Prevenção de loop infinito quando o próprio bot altera o estado no GitHub
- **WHEN** o Worker receber um webhook do GitHub `issues` (`closed` ou `reopened`) cujo `sender.type === "Bot"` ou `sender.login` pertença ao `aresta-climb-bot`
- **THEN** o sistema NÃO DEVE invocar a API do Sentry para atualizar o status novamente.

### Requirement: Classificação Diferenciada de Workflows de Pull Request e Deploys no aresta_db
O sistema SHALL diferenciar recusas legítimas de validação em Pull Requests de falhas inesperadas do próprio workflow ou de seus scripts nos workflows `pr-db-validator.yml`, `pr-code-validator.yml` e `pr-integrator.yml` do repositório `aresta-climb/aresta_db`, consultando as etapas (*steps*) dos jobs da execução e/ou códigos de saída padronizados (`exit code 1` para recusa de validação vs. `exit code >= 2` para falha interna de script).

#### Scenario: Recusa legítima de validação em Pull Request é ignorada pelo roteador de alertas
- **WHEN** um evento `workflow_run` concluído com `conclusion === "failure"` para `pr-db-validator.yml`, `pr-code-validator.yml` ou `pr-integrator.yml` em `aresta-climb/aresta_db` falhar exclusivamente na etapa de validação de código/croqui/checagens com código de saída de recusa legítima (`exit code 1`)
- **THEN** o sistema DEVE retornar status HTTP `200` (`ignorado: true`) sem disparar alertas de bug ou de emergência.

#### Scenario: Falha inesperada de infraestrutura ou erro interno de script em workflow de PR dispara Emergência
- **WHEN** um evento `workflow_run` concluído com falha para `pr-db-validator.yml`, `pr-code-validator.yml` ou `pr-integrator.yml` em `aresta-climb/aresta_db` apresentar falha em etapa de infraestrutura/integração (geração de token, checkout, instalação de dependências, comentário no PR, geração de artefatos ou merge) ou falha interna de script (`exit code >= 2`)
- **THEN** o sistema DEVE classificar o evento como `emergencias`, abrir automaticamente uma GitHub Issue com a label `emergencia` em `aresta-climb/aresta_db` e notificar `#🚨-emergencias` no Discord e `NTFY_TOPICO_EMERGENCIAS` (`priority: 5`).
