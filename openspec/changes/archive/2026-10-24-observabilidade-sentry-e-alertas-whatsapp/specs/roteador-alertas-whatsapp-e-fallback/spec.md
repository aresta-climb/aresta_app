# Spec Delta

## Purpose

Prover um roteador central de webhooks (`cloudflare/alertas`) capaz de autenticar e classificar eventos críticos do Sentry e da organização GitHub (`aresta-climb`), despachando notificações formatadas em tempo real para dois grupos de WhatsApp via gateway WAHA com fallback automático por e-mail via Resend (`contato@arestaclimb.com`) e documentação completa de provisionamento.

## ADDED Requirements

### Requirement: Autenticação Criptográfica de Webhooks do Sentry e GitHub
O Worker de alertas SHALL validar a assinatura HMAC-SHA256 de todas as requisições recebidas nos endpoints `/webhook/sentry` (`sentry-hook-signature`) e `/webhook/github` (`x-hub-signature-256`) antes de processar qualquer carga útil, rejeitando requisições não autenticadas com status HTTP `401`.

#### Scenario: Webhook do GitHub com assinatura HMAC válida
- **WHEN** uma requisição `POST /webhook/github` for recebida com cabeçalho `x-hub-signature-256` correspondente ao HMAC-SHA256 do corpo usando `GITHUB_WEBHOOK_SECRET`
- **THEN** o sistema DEVE autenticar a requisição e processar o evento com status HTTP `200`.

#### Scenario: Rejeição de requisição com assinatura inválida ou ausente
- **WHEN** uma requisição `POST /webhook/sentry` ou `POST /webhook/github` for recebida sem cabeçalho de assinatura ou com assinatura divergente do segredo configurado
- **THEN** o sistema DEVE rejeitar a requisição imediatamente com status HTTP `401` e não disparar mensagens ao WhatsApp ou Resend.

### Requirement: Roteamento de Emergências Críticas para o Grupo 1 do WhatsApp
O sistema SHALL encaminhar imediatamente para o grupo de WhatsApp `🚨 Grupo 1 — Emergências` (`WHATSAPP_GROUP_EMERGENCIA_ID`) todo alerta crítico do Sentry (crashes fatais, picos de erro ou queda de uptime) e toda falha de execução de workflow do GitHub Actions (`workflow_run` concluído com `conclusion === "failure"`) ocorrida na branch `main` ou em tags de release de qualquer repositório da organização.

#### Scenario: Alerta de crash fatal ou spike originado no Sentry
- **WHEN** o endpoint `POST /webhook/sentry` receber um alerta de regra de emergência (nível `fatal`, anomalia de velocidade/spike ou monitor de uptime offline)
- **THEN** o sistema DEVE formatar o resumo contendo projeto, ambiente, mensagem do erro e link direto do Sentry e enviá-lo para `WHATSAPP_GROUP_EMERGENCIA_ID`.

#### Scenario: Falha de deploy ou CI na branch principal no GitHub Actions
- **WHEN** o endpoint `POST /webhook/github` receber um evento `workflow_run` com `action === "completed"`, `conclusion === "failure"` e `head_branch === "main"` (como falha de compilação/deploy no `aresta_db`, `aresta_backend` ou `aresta_app`)
- **THEN** o sistema DEVE enviar um alerta de emergência para `WHATSAPP_GROUP_EMERGENCIA_ID` contendo o nome do repositório, nome do workflow, autor do commit e link para o log da execução.

#### Scenario: Falha de workflow em branch de feature ignorada pelo canal de emergência
- **WHEN** o endpoint `POST /webhook/github` receber um evento `workflow_run` com `conclusion === "failure"` em uma branch secundária de desenvolvimento (diferente de `main` e não associada a tag de release)
- **THEN** o sistema DEVE retornar HTTP `200` ignorando o disparo para evitar ruído no grupo de emergência.

### Requirement: Roteamento de Novas Issues e Pull Requests para o Grupo 2 do WhatsApp
O sistema SHALL encaminhar para o grupo de WhatsApp `🛠️ Grupo 2 — Bugs & Feedbacks` (`WHATSAPP_GROUP_TRIAGEM_ID`) toda nova issue aberta (`issues` com `action === "opened"`) e todo novo Pull Request aberto (`pull_request` com `action === "opened"`) em qualquer repositório da organização `aresta-climb`, extraindo e destacando o link do Sentry quando a issue tiver sido gerada pela integração do Sentry.

#### Scenario: Nova issue aberta automaticamente pelo Sentry na primeira ocorrência
- **WHEN** o endpoint `POST /webhook/github` receber um evento `issues` com `action === "opened"` cujo corpo contenha um link de evento do Sentry (`sentry.io`)
- **THEN** o sistema DEVE enviar notificação para `WHATSAPP_GROUP_TRIAGEM_ID` contendo repositório, número e título da issue, link da issue no GitHub e link direto para o diagnóstico privado no Sentry.

#### Scenario: Nova issue de feedback do usuário ou novo PR de submissão de croqui
- **WHEN** o endpoint `POST /webhook/github` receber `issues` (`action === "opened"`) criado pelo `app-feedback` ou `pull_request` (`action === "opened"`) criado pelo `create-pr`
- **THEN** o sistema DEVE enviar notificação formatada para `WHATSAPP_GROUP_TRIAGEM_ID` com o título, autor/origem e link direto no GitHub.

### Requirement: Fallback Automático por E-mail via Resend sem Loop de Erro
Quando o envio da notificação para o gateway WAHA do WhatsApp falhar por erro de rede, timeout ou status HTTP diferente de `2xx`, o sistema SHALL disparar automaticamente o conteúdo do alerta por e-mail utilizando a API do Resend (`POST https://api.resend.com/emails`) para `contato@arestaclimb.com` (com remetente `alerta@login.arestaclimb.com`), sem registrar exceção recursiva no Sentry caso o próprio alerta seja oriundo de falha.

#### Scenario: Indisponibilidade da VM do WAHA aciona envio via Resend
- **WHEN** o Worker `cloudflare/alertas` tentar enviar uma mensagem ao endpoint REST do WAHA e receber erro HTTP `502`/`503` ou timeout
- **THEN** o sistema DEVE enviar um e-mail via API do Resend para `contato@arestaclimb.com` contendo o alerta original na íntegra acrescido de um banner avisando o motivo da falha no gateway do WhatsApp.

#### Scenario: Sucesso no envio ao WhatsApp não aciona o Resend
- **WHEN** o gateway WAHA responder com status HTTP `200` ou `201` ao envio da mensagem de alerta
- **THEN** o sistema NÃO DEVE invocar a API do Resend.

### Requirement: Documentação Passo a Passo de Provisionamento e Configuração
O repositório SHALL conter um guia técnico detalhado em português brasileiro (`docs/guia_configuracao_observabilidade_e_alertas.md`) documentando passo a passo a configuração do Sentry Open Source, da integração com GitHub Issues, do provisionamento da VM gratuita `e2-micro` no Google Cloud Platform com Docker, WAHA (motor NOWEB) e Cloudflare Tunnel, da criação dos grupos de WhatsApp, do Webhook Organizacional do GitHub e dos segredos do Resend e Cloudflare.

#### Scenario: Consulta ao guia de configuração completa da infraestrutura
- **WHEN** um desenvolvedor consultar `docs/guia_configuracao_observabilidade_e_alertas.md` para provisionar ou auditar o ambiente de produção
- **THEN** o documento DEVE apresentar comandos reproduzíveis e instruções completas para GCP `e2-micro`, Docker Compose do WAHA + `cloudflared`, obtenção de IDs de grupos do WhatsApp, configuração de projetos e alertas no Sentry, webhook organizacional no GitHub e variáveis de ambiente do Cloudflare/Supabase.
