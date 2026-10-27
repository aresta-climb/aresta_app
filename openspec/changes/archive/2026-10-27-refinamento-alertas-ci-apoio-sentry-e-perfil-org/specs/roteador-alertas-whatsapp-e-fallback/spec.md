# Spec Delta

## ADDED Requirements

### Requirement: Classificação Diferenciada de Workflows de Pull Request e Deploys no aresta_db
O sistema SHALL diferenciar recusas legítimas de validação em Pull Requests de falhas inesperadas do próprio workflow ou de seus scripts nos workflows `pr-db-validator.yml`, `pr-code-validator.yml` e `pr-integrator.yml` do repositório `aresta-climb/aresta_db`, consultando as etapas (*steps*) dos jobs da execução e/ou códigos de saída padronizados (`exit code 1` para recusa de validação vs. `exit code >= 2` para falha interna de script).

#### Scenario: Recusa legítima de validação em Pull Request é ignorada pelo roteador de alertas
- **WHEN** um evento `workflow_run` concluído com `conclusion === "failure"` para `pr-db-validator.yml`, `pr-code-validator.yml` ou `pr-integrator.yml` em `aresta-climb/aresta_db` falhar exclusivamente na etapa de validação de código/croqui/checagens com código de saída de recusa legítima (`exit code 1`)
- **THEN** o sistema DEVE retornar status HTTP `200` (`ignorado: true`) sem disparar alertas de bug ou de emergência.

#### Scenario: Falha inesperada de infraestrutura ou erro interno de script em workflow de PR dispara Emergência
- **WHEN** um evento `workflow_run` concluído com falha para `pr-db-validator.yml`, `pr-code-validator.yml` ou `pr-integrator.yml` em `aresta-climb/aresta_db` apresentar falha em etapa de infraestrutura/integração (geração de token, checkout, instalação de dependências, comentário no PR, geração de artefatos ou merge) ou falha interna de script (`exit code >= 2`)
- **THEN** o sistema DEVE classificar o evento como `emergencias`, abrir automaticamente uma GitHub Issue com a label `emergencia` em `aresta-climb/aresta_db` e notificar `#🚨-emergencias` no Discord e `NTFY_TOPICO_EMERGENCIAS` (`priority: 5`).

## MODIFIED Requirements

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
