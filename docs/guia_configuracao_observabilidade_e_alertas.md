# Guia Completo de Configuração: Observabilidade Centralizada (Sentry) e Roteamento de Alertas (Push Móvel `ntfy` + Mural Discord + WhatsApp WAHA Standby + Fallback Resend)

Este documento descreve o passo a passo completo e reproduzível para configurar toda a infraestrutura de observabilidade, deduplicação e sincronização bidirecional automática de issues no GitHub (`Sentry <-> GitHub`), notificações push móveis imediatas via **`ntfy`** (com ícones WebP customizados por categoria, prioridade máxima e botões de ação), mural visual somente-leitura no **Discord**, integração do WhatsApp WAHA em *standby* e contingência automática por e-mail via Resend + fila de retentativas no Cloudflare KV do ecossistema **Aresta Climb**.

---

## Visão Geral da Arquitetura

```
  [aresta_app (Flutter)] ──(Crashlytics + Sentry SDK)──┐
  [aresta_backend (CF Workers + Supabase)] ────────────┼──► [Sentry (Open Source Plan)]
  [arestaclimb.com (Portal + Editor Web)] ─────────────┤          │
  [aresta_db (Editor Desktop PySide6)] ────────────────┘          ├──► 1. Erro Inédito (First Seen)
                                                                  │       Abre Issue automática no GitHub
                                                                  │       (sem expor PII de usuários)
                                                                  │
                                                                  └──► 2. Emergência (Crash Fatal / Spike / Uptime)
                                                                          │
  [GitHub Org: aresta-climb]                                              ▼
  ├── Issues abertas/reabertas (Sentry, App Feedback) ──────► [Cloudflare Worker: alertas.arestaclimb.com]
  ├── Pull Requests abertos/reabertos (Croquis / Código) ───►  ├── Valida assinatura HMAC-SHA256
  ├── Falhas de GitHub Actions em main/tags (ex: aresta_db) ─► ├── Cria GitHub Issue p/ emergências (Aresta Climb Bot)
  └── Sincronização bidirecional (Sentry <-> GitHub) ────────► ├── Classifica severidade:
                                                               │    • 🚨 Grupo 1 (Emergências)
                                                               │    • 🛠️ Grupo 2 (Bugs & Feedbacks)
                                                               ├── 1. Envia Push Móvel ntfy (prioridade 5/3 + ícone WebP)
                                                               ├── 2. Publica no Mural Discord (somente-leitura, sem @everyone)
                                                               ├── 3. (Opcional) Envia via WAHA (GCP e2-micro)
                                                               └── Se os canais falharem:
                                                                    ├──► Enfileira no Cloudflare KV (Cron */5 * * * *)
                                                                    └──► [Fallback Resend API] ──► contato@arestaclimb.com
```

---

## Etapa 1: Solicitar o Plano Sentry for Open Source e Criar os Projetos

1. Crie uma organização no Sentry (ex.: `aresta-climb`) em [https://sentry.io/signup/](https://sentry.io/signup/).
2. Solicite o plano gratuito **Sentry for Open Source** em [https://sentry.io/for/open-source/](https://sentry.io/for/open-source/) informando:
   - **Organização GitHub:** `https://github.com/aresta-climb`
   - **Licenças Open Source:** MPL-2.0 (`aresta_app`) e ODbL-1.0 (`aresta_db`).
3. No painel do Sentry (*Projects* $\rightarrow$ *Create Project*), garanta a existência dos seguintes projetos e copie a **DSN** (*Settings* $\rightarrow$ *Projects* $\rightarrow$ `<projeto>` $\rightarrow$ *Client Keys (DSN)*) de cada um:
   - **`aresta-app`** (Plataforma: *Flutter*) — recebe erros não-fatais, falhas de sincronização e crashes do aplicativo móvel.
   - **`aresta-backend`** (Plataforma: *Node.js* / *Cloudflare Workers*) — recebe exceções dos Cloudflare Workers (`catalogo`, `feedback`, `previa`) e das Supabase Edge Functions (`git-proxy`, `create-pr`, `app-feedback`, `discord-feedback`).
   - **`aresta-web`** (Plataforma: *Browser JavaScript*) — recebe exceções globais (`error` e `unhandledrejection`) do portal `arestaclimb.com` e da página `editor.html`.
   - **`aresta-editor`** (Plataforma: *Python*) — já utilizado pelo Editor Desktop em `aresta_db`.
4. **Proteção de Privacidade (PII Scrubbing):**
   - Em *Settings* $\rightarrow$ *Security & Privacy* da organização no Sentry, mantenha **Data Scrubbing** e **Prevent Storing of IP Addresses** ativados.
   - Dessa forma, quando o Sentry abrir uma Issue pública no GitHub, apenas o tipo da exceção, arquivo/linha do stack trace e link autenticado (`https://aresta-climb.sentry.io/issues/...`) serão incluídos no corpo da Issue pública.

---

## Etapa 2: Configurar Integração Sentry $\leftrightarrow$ GitHub e Regras de Alerta

### 2.1 Instalar a Integração Oficial do GitHub no Sentry
1. No Sentry, acesse **Settings** $\rightarrow$ **Integrations** $\rightarrow$ **GitHub**.
2. Clique em **Add Installation** e autorize o aplicativo oficial do Sentry na organização **`aresta-climb`** do GitHub com acesso aos repositórios `aresta_app`, `aresta_backend`, `arestaclimb.com` e `aresta_db`.

### 2.2 Criar a Internal Integration para o Webhook de Emergências
1. No Sentry, acesse **Settings** $\rightarrow$ **Developer Settings** $\rightarrow$ **New Internal Integration**.
2. Configure:
   - **Name:** `Aresta Roteador de Alertas WhatsApp`
   - **Webhook URL:** `https://alertas.arestaclimb.com/webhook/sentry`
   - Marque **Alert Rule Action** habilitado.
   - Em **Permissions**, defina *Issue & Event* como `Read`.
3. Salve e copie o **Client Secret** gerado — ele será o seu `SENTRY_WEBHOOK_SECRET`.

### 2.3 Configurar as 3 Regras de Alerta em Cada Projeto do Sentry
Em **Alerts** $\rightarrow$ **Create Alert** de cada projeto (`aresta-app`, `aresta-backend`, `aresta-web`, `aresta-editor`):

1. **Regra A — Deduplicação de Novos Bugs (First Seen $\rightarrow$ GitHub Issue):**
   - **Tipo:** *Issues*
   - **When:** *A new issue is created*
   - **Then:** *Create a GitHub Issue* em `aresta-climb/<repositório-correspondente>` com a label `bug`.
   - *Nota:* Esta regra **não** chama o webhook do Sentry diretamente; a criação da Issue no GitHub acionará automaticamente o webhook organizacional do GitHub rumo ao `🛠️ Grupo 2 — Bugs & Feedbacks` já com o link da Issue pública e o link do Sentry!
2. **Regra B — Emergência: Crash Fatal:**
   - **Tipo:** *Issues*
   - **When:** *An event is captured*
   - **If:** *The event's level is equal to `fatal`*
   - **Then:** *Send a notification via `Aresta Roteador de Alertas WhatsApp`* (vai para `🚨 Grupo 1 — Emergências`).
3. **Regra C — Emergência: Spike de Erros:**
   - **Tipo:** *Metric Alert* (*Number of Events*)
   - **Window:** `5 minutes`
   - **Critical Threshold:** `30` eventos em 5 minutos
   - **Then:** *Send a notification via `Aresta Roteador de Alertas WhatsApp`* (vai para `🚨 Grupo 1 — Emergências`).

---

## Etapa 3: Provisionar a VM Gratuita `e2-micro` no Google Cloud + WAHA (`NOWEB`) + Cloudflare Tunnel

O nível **Always Free** do Google Cloud Compute Engine oferece gratuitamente 1 instância `e2-micro` por mês nas regiões `us-central1`, `us-east1` ou `us-west1` com até `30 GB` de disco padrão (`pd-standard`).

### 3.1 Criar a Instância `e2-micro` via `gcloud` CLI
Execute no seu terminal local (substituindo `<SEU_PROJETO_GCP>` pelo ID do seu projeto no Google Cloud):

```bash
gcloud compute instances create waha-alertas-aresta \
  --project=<SEU_PROJETO_GCP> \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --image-family=ubuntu-2404-lts-amd64 \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=20GB \
  --boot-disk-type=pd-standard \
  --tags=waha-tunnel
```

### 3.2 Configurar Swap de 2 GB e Instalar Docker na VM
Conecte-se à VM via SSH:

```bash
gcloud compute ssh waha-alertas-aresta --zone=us-central1-a
```

Dentro da VM, crie um arquivo de Swap de `2 GB` (essencial para que a `e2-micro` de `1 GB` de RAM nunca sofra falta de memória) e instale o Docker + Docker Compose:

```bash
# 1. Criar e ativar 2 GB de Swap persistente
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 2. Instalar Docker e Docker Compose plugin
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker $USER
newgrp docker
```

### 3.3 Criar o Cloudflare Tunnel para Expor o WAHA com Segurança (Zero Portas Abertas)
1. Acesse o painel [Cloudflare Zero Trust](https://one.dash.cloudflare.com/) $\rightarrow$ **Networks** $\rightarrow$ **Tunnels**.
2. Clique em **Create a tunnel** $\rightarrow$ selecione **Cloudflared** $\rightarrow$ nomeie como `waha-gcp-tunnel`.
3. Copie o **Tunnel Token** exibido (`eyJhIjoi...`).
4. Na aba **Public Hostname** do túnel, adicione:
   - **Subdomain:** `waha`
   - **Domain:** `arestaclimb.com`
   - **Service Type:** `HTTP`
   - **URL:** `waha:3000`

### 3.4 Subir o `docker-compose.yml` (WAHA `NOWEB` + `cloudflared`)
Ainda dentro da VM `waha-alertas-aresta`, crie a pasta `/opt/waha` e o arquivo `docker-compose.yml`:

```bash
sudo mkdir -p /opt/waha/waha-sessions
sudo chown -R $USER:$USER /opt/waha
cd /opt/waha
```

Crie um arquivo `.env` em `/opt/waha/.env` com uma chave forte gerada por `openssl rand -hex 32`:

```ini
WAHA_API_KEY=coloque_aqui_sua_chave_secreta_waha_gerada
WAHA_DASHBOARD_USERNAME=admin
WAHA_DASHBOARD_PASSWORD=coloque_aqui_uma_senha_forte_dashboard
CLOUDFLARE_TUNNEL_TOKEN=coloque_aqui_o_token_do_cloudflare_tunnel
```

Crie o arquivo `/opt/waha/docker-compose.yml` utilizando a imagem oficial leve `devlikeapro/waha:noweb` (sem o navegador Chromium, economizando ~300 MB de download e centenas de MB de RAM):

```yaml
services:
  waha:
    image: devlikeapro/waha:noweb
    container_name: waha
    restart: always
    environment:
      - WHATSAPP_DEFAULT_ENGINE=NOWEB
      - WAHA_API_KEY=${WAHA_API_KEY}
      - WAHA_DASHBOARD_ENABLED=true
      - WAHA_DASHBOARD_USERNAME=${WAHA_DASHBOARD_USERNAME}
      - WAHA_DASHBOARD_PASSWORD=${WAHA_DASHBOARD_PASSWORD}
      - WHATSAPP_RESTART_ALL_SESSIONS=true
    volumes:
      - ./waha-sessions:/app/.sessions
    expose:
      - "3000"

  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    restart: always
    command: tunnel --no-autoupdate run --token ${CLOUDFLARE_TUNNEL_TOKEN}
    depends_on:
      - waha
```

Suba os containers em background:

```bash
docker compose up -d
```

### 3.5 (Opcional - Standby) Parear o WhatsApp via QR Code e Obter os IDs dos 2 Grupos (`@g.us`)
> [!NOTE]
> A infraestrutura do WAHA na VM `e2-micro` permanece provisionada e pronta em *standby*. O canal primário de produção ativo são os **Webhooks do Discord** (Etapa 4), dispensando a contratação imediata de chip/eSIM dedicado. Quando desejar ativar o WhatsApp, execute os passos abaixo e cadastre os segredos no Cloudflare.

1. No WhatsApp, dentro da Comunidade Aresta Climb, crie os dois grupos restritos à equipe técnica e adicione o número de telefone que será pareado no WAHA:
   - **`🚨 Aresta — Emergências`** (Grupo 1)
   - **`🛠️ Aresta — Bugs & Feedbacks`** (Grupo 2)
2. Acesse `https://waha.arestaclimb.com/dashboard` com o usuário e senha definidos no `.env`.
3. Inicie a sessão `default` e escaneie o **QR Code** com o aparelho WhatsApp (*Aparelhos Conectados* $\rightarrow$ *Conectar um aparelho*).
4. Assim que o status da sessão `default` mudar para `WORKING`, liste os grupos para descobrir o `id` (`120363...@g.us`) de cada grupo executando:

```bash
curl -s "https://waha.arestaclimb.com/api/default/groups" \
  -H "X-Api-Key: SUA_WAHA_API_KEY" | jq '.[] | {id: .id, subject: .subject}'
```

Anote os dois identificadores:
- `WHATSAPP_GRUPO_EMERGENCIAS_ID` (ex.: `120363011111111111@g.us`)
- `WHATSAPP_GRUPO_BUGS_ID` (ex.: `120363022222222222@g.us`)

---

## Etapa 4: Configurar o Pager Móvel (`ntfy`), o Mural do Discord e o Fallback Resend

### 4.1 Configurar os Tópicos de Push Móvel no `ntfy` (Alertas Imediatos no Celular)
Como o Discord Desktop suprime notificações push para o celular sempre que há atividade de mouse/teclado no computador, utilizamos o **`ntfy`** (`https://ntfy.sh`) como pager móvel dedicado:

1. Instale o aplicativo gratuito **ntfy** no celular ([Android](https://play.google.com/store/apps/details?id=io.heckel.ntfy) / [iOS](https://apps.apple.com/us/app/ntfy/id1625396347)).
2. Defina dois nomes de tópicos secretos com sufixo aleatório longo (ex.: `aresta-emergencias-<hash>` e `aresta-bugs-<hash>`) e inscreva-se neles no aplicativo móvel.
3. O `aresta-alertas-worker` envia notificações push ricas contendo:
   - **Cabeçalho:** `"Aresta Climb • <resumo>"`
   - **Ícones WebP `256x256` customizados por categoria** (servidos diretamente pelo Worker):
     - Emergências (`priority: 5`): `https://alertas.arestaclimb.com/icones/emergencia.webp`
     - Bugs e Feedbacks (`priority: 3`): `https://alertas.arestaclimb.com/icones/feedback_bugs.webp`
   - **Ações clicáveis (até 3 botões):** Botões **`Discord`**, **`GitHub`** e **`Sentry`** levando diretamente à mensagem publicada no mural do Discord, à Issue/PR no GitHub e ao erro no Sentry.

### 4.2 Configurar os Canais do Discord como Mural Somente-Leitura
1. No servidor privado da equipe técnica no Discord, crie dois canais de texto:
   - `#🚨-emergencias`
   - `#🛠️-bugs-e-feedbacks`
2. Em cada canal (*Editar Canal* $\rightarrow$ *Permissões*):
   - Desative **Enviar mensagens** e **Criar tópicos** para `@everyone` (mantendo o canal bloqueado para conversa humana, de modo que toda discussão técnica ocorra exclusivamente nas Issues/PRs do GitHub).
   - Silencie as notificações dos dois canais no Discord para evitar alertas duplicados com o `ntfy`.
3. Em *Integrações* $\rightarrow$ *Webhooks* de cada canal, crie o webhook `Aresta Alertas` e copie as URLs:
   - `DISCORD_WEBHOOK_EMERGENCIAS_URL`
   - `DISCORD_WEBHOOK_BUGS_URL`

> [!TIP]
> O `aresta-alertas-worker` publica nos canais do Discord de forma silenciosa (`allowed_mentions: { parse: [] }`, sem `@everyone`) com `avatar_url` específico para emergências ou bugs. Além disso, toda emergência do Sentry ou falha de `workflow_run` abre automaticamente uma GitHub Issue com a label `emergencia` usando o GitHub App `Aresta Climb Bot` (ignorando o evento `issues.opened` subsequente com label `emergencia` para não duplicar no canal de bugs), e o fechamento/reabertura de issues é sincronizado bidirecionalmente entre Sentry e GitHub.

### 4.3 Configurar o Fallback de E-mail no Resend (`contato@arestaclimb.com`)

Para garantir que nenhum alerta seja perdido caso os canais primários falhem:

1. Acesse o painel do [Resend](https://resend.com/api-keys) onde o domínio `login.arestaclimb.com` já está verificado.
2. Clique em **Create API Key**:
   - **Name:** `aresta-alertas-worker-fallback`
   - **Permission:** `Sending access`
   - **Domain:** `login.arestaclimb.com`
3. Copie a chave gerada (`re_...`). O Worker enviará e-mails de contingência de `alerta@login.arestaclimb.com` para `contato@arestaclimb.com` **exclusivamente** quando os canais primários falharem, além de enfileirar no Cloudflare KV (`FILA_RETENTATIVAS_ALERTAS`) para reprocessamento automático a cada 5 minutos (`*/5 * * * *`).

---

## Etapa 5: Publicar o Worker `aresta-alertas-worker` e Cadastrar os Secrets

### 5.1 Deploy e Secrets do `aresta-alertas-worker` (Cloudflare)
No diretório `aresta_backend/cloudflare/alertas`:

```bash
cd aresta_backend/cloudflare/alertas

# 1. Cadastrar secrets dos tópicos do ntfy (Push Móvel Dedicado)
npx wrangler secret put NTFY_TOPICO_EMERGENCIAS
# Informe o nome secreto do tópico de emergências (ex: aresta-emergencias-<hash>)

npx wrangler secret put NTFY_TOPICO_BUGS
# Informe o nome secreto do tópico de bugs e feedbacks (ex: aresta-bugs-<hash>)

# (Opcional) Caso utilize conta autenticada no ntfy.sh ou instância própria:
# npx wrangler secret put NTFY_API_TOKEN

# 2. Cadastrar secrets dos Webhooks do Discord (Mural Visual Somente-Leitura)
npx wrangler secret put DISCORD_WEBHOOK_EMERGENCIAS_URL
# Cole a URL do Webhook do canal #🚨-emergencias

npx wrangler secret put DISCORD_WEBHOOK_BUGS_URL
# Cole a URL do Webhook do canal #🛠️-bugs-e-feedbacks

# 2. Cadastrar secrets de autenticação HMAC, Token de API do Sentry e Fallback Resend
npx wrangler secret put SENTRY_WEBHOOK_SECRET
# Informe o Client Secret da Internal Integration do Sentry (Etapa 2.2)

npx wrangler secret put SENTRY_API_TOKEN
# Informe o Token gerado na Internal Integration do Sentry (Permissão Issue & Event: Read & Write)

npx wrangler secret put GITHUB_WEBHOOK_SECRET
# Gere um segredo forte (ex: openssl rand -hex 32) que também será usado na Etapa 6

npx wrangler secret put RESEND_API_KEY
# Informe a chave re_... do Resend (Etapa 4.2)

# 3. Cadastrar secrets do GitHub App (Aresta Climb Bot) para criação e sincronização de Issues
npx wrangler secret put ARESTA_CLIMB_BOT_GITHUB_APP_CLIENT_ID
npx wrangler secret put ARESTA_CLIMB_BOT_GITHUB_APP_PRIVATE_KEY
npx wrangler secret put ARESTA_CLIMB_BOT_GITHUB_APP_INSTALLATION_ID

# 4. (Opcional - Standby) Cadastrar secrets do WAHA caso deseje ativar o WhatsApp
# npx wrangler secret put WAHA_BASE_URL
# npx wrangler secret put WAHA_API_KEY
# npx wrangler secret put WHATSAPP_GRUPO_EMERGENCIAS_ID
# npx wrangler secret put WHATSAPP_GRUPO_BUGS_ID

# 5. Publicar o Worker em alertas.arestaclimb.com
npx wrangler deploy
```

### 5.2 Configurar `SENTRY_DSN` nos Demais Serviços do Ecossistema

1. **Cloudflare Workers (`catalogo`, `feedback`, `previa`, `app-links`):**
   A DSN do projeto **`aresta-backend`** (`https://df8611ccbb9672027fc7f612c388ee91@o4511980548849664.ingest.us.sentry.io/4512313378013184`) já está configurada em `"vars"` nos arquivos `wrangler.jsonc` de cada Worker e em `DSN_SENTRY_ARESTA_BACKEND_PADRAO` no `relator_sentry.ts`. Basta publicar cada Worker com `npx wrangler deploy`.
2. **Supabase Edge Functions (`git-proxy`, `create-pr`, `app-feedback`, `discord-feedback`):**
   Na raiz de `aresta_backend`, defina o secret com a DSN do projeto **`aresta-backend`**:
   ```bash
   supabase secrets set SENTRY_DSN="https://df8611ccbb9672027fc7f612c388ee91@o4511980548849664.ingest.us.sentry.io/4512313378013184"
   ```
3. **Aplicativo Mobile (`aresta_app`):**
   - A DSN do projeto **`aresta-app`** (`https://a9b8f04560a98ff2186ca8cdb654d22a@o4511980548849664.ingest.us.sentry.io/4512313345966080`) está configurada por padrão em `kSentryDsn` no `frontend/lib/main.dart`.
   - O plugin oficial `sentry_dart_plugin` está configurado no `frontend/pubspec.yaml` (`upload_debug_symbols: true`, `upload_source_maps: true`, `org: aresta-climb`, `project: aresta-app`) para upload automático de símbolos e source maps em builds de release via `SENTRY_AUTH_TOKEN`.
4. **Portal Web (`arestaclimb.com` / `arestaclimb-com`):**
   - A DSN oficial do projeto **`arestaclimb-com`** (`https://274a2060ad47e642a33317bea66a6b13@o4511980548849664.ingest.us.sentry.io/4512313437913088`) está definida como padrão em `src/telemetria.js`.
   - O script loader oficial do Sentry (`https://js.sentry-cdn.com/274a2060ad47e642a33317bea66a6b13.min.js`) está inserido no topo do `<head>` de todas as páginas HTML do portal para capturar falhas precoces e expor `window.Sentry`.
   - O plugin `@sentry/vite-plugin` está integrado ao `vite.config.js` (`org: aresta-climb`, `project: arestaclimb-com`, `sourcemap: true`), ativado automaticamente quando `SENTRY_AUTH_TOKEN` estiver presente no CI/CD.

---

## Etapa 6: Configurar o Webhook Organizacional no GitHub e Testar Ponta a Ponta

### 6.1 Criar o Webhook na Organização `aresta-climb`
1. Acesse **Settings** da organização no GitHub: [https://github.com/organizations/aresta-climb/settings/hooks](https://github.com/organizations/aresta-climb/settings/hooks).
2. Clique em **Add webhook** e preencha:
   - **Payload URL:** `https://alertas.arestaclimb.com/webhook/github`
   - **Content type:** `application/json`
   - **Secret:** o valor exato cadastrado em `GITHUB_WEBHOOK_SECRET` na Etapa 5.1.
   - **Which events would you like to trigger this webhook?** Selecione *Let me select individual events* e marque apenas:
     - `[x] Issues` (notifica abertura de bugs do Sentry *First Seen*, feedbacks do app e issues comunitárias no Grupo 2)
     - `[x] Pull requests` (notifica novos PRs de croquis ou código no Grupo 2)
     - `[x] Workflow runs` (notifica falhas de CI/deploy do GitHub Actions nas branches `main`, `master` ou tags `v*`, incluindo `aresta_db` e `umami`, no Grupo 1)
     - `[x] Check runs` (notifica falhas de deploy do Cloudflare Pages em `arestaclimb.com` e Cloudflare Workers Builds em `aresta_backend` no Grupo 1)
     - `[x] Statuses` (notifica falhas de deploy da Vercel em `umami` no Grupo 1)
3. Clique em **Add webhook**.

### 6.2 Comandos `curl` para Verificação Ponta a Ponta

1. **Verificar saúde do Worker:**
   ```bash
   curl -i https://alertas.arestaclimb.com/health
   ```
2. **Simular um alerta assinado do GitHub (Nova Issue $\rightarrow$ Grupo 2):**
   ```bash
   SEGREDO_GH="SEU_GITHUB_WEBHOOK_SECRET"
   PAYLOAD='{"action":"opened","repository":{"full_name":"aresta-climb/aresta_app"},"issue":{"number":1,"title":"Teste de Alerta Operacional","html_url":"https://github.com/aresta-climb/aresta_app/issues/1","body":"Sentry Issue: https://aresta-climb.sentry.io/issues/12345/"}}'
   ASSINATURA="sha256=$(printf '%s' "$PAYLOAD" | openssl dgst -sha256 -hmac "$SEGREDO_GH" | awk '{print $2}')"

   curl -i -X POST https://alertas.arestaclimb.com/webhook/github \
     -H "Content-Type: application/json" \
     -H "x-github-event: issues" \
     -H "x-hub-signature-256: $ASSINATURA" \
     -d "$PAYLOAD"
   ```
3. **Testar o Fallback Automático de E-mail via Resend (`contato@arestaclimb.com`):**
   - Caso os canais primários configurados (Discord ou WAHA) estejam inacessíveis ou falhem, o Worker responde `{"ok":true,"entregueVia":"resend_fallback",...}` e a caixa de entrada `contato@arestaclimb.com` recebe imediatamente o e-mail com prefixo `[CONTINGÊNCIA ALERTA]`.
