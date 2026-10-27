# Design

## Context

Conforme detalhado em `proposal.md`, o `aresta-alertas-worker` (`aresta_backend/cloudflare/alertas/src/index.ts`) atualmente classifica qualquer falha de `workflow_run`, `check_run` (Cloudflare) e `status` (Vercel) em branches de produção como emergência máxima (`#🚨-emergencias`), além de não enfileirar na `FILA_RETENTATIVAS_ALERTAS` falhas de criação de GitHub Issues para erros não-fatais do Sentry caso o GitHub esteja em *outage*. Paralelamente, precisamos distinguir nos workflows `pr-*.yml` do `aresta_db` recusas legítimas de validação de PRs de falhas inesperadas de infraestrutura/scripts, destacar o apoio do **Sentry Sponsored Business Plan** no site e repositórios, e estruturar o repositório `aresta-climb/.github`.

## Goals / Non-Goals

**Goals:**
- Reduzir ruído no canal de emergências classificando falhas gerais de CI/CD e deploys externos (Cloudflare/Vercel) como `bugs` (com abertura automática de GitHub Issue com label `bug`, ou deduplicação limpa via fluxo unificado).
- Garantir que qualquer falha no `deploy.yml` do `aresta_db` e qualquer falha inesperada de infraestrutura ou script nos workflows `pr-*.yml` do `aresta_db` disparem **Emergência** imediata.
- Padronizar códigos de saída (*exit codes*) no `aresta_db` (`0` = sucesso, `1` = recusa legítima de validação, `>= 2` = erro interno/inesperado de script).
- Garantir que erros não-fatais do Sentry sobrevivam a *outages* do GitHub (notificando imediatamente no Discord e `ntfy` e enfileirando a criação da issue na `FILA_RETENTATIVAS_ALERTAS`).
- Publicar o reconhecimento oficial ao Sentry em `arestaclimb.com` e nos `README.md` dos repositórios, além de criar `c:\Renato\Devel\aresta-climb\.github\profile\README.md`.

**Non-Goals:**
- Alterar a página `sobre_time.dart` ou `comunidade.dart` no aplicativo móvel `aresta_app` neste momento.
- Remover o `/webhook/sentry` do `aresta-alertas-worker` (mantido para suportar *Metric Alerts* / Spikes e garantir tolerância a *outages* do GitHub).

## Decisions

### 1. Fluxo Unificado e Resiliente para Bugs Não-Fatais do Sentry e Falhas de CI/CD
- **Decisão**:
  - Para **erros não-fatais do Sentry** (`recurso === "issue" && acao === "created" && level !== "fatal"`):
    - Quando a criação da GitHub Issue (`label: ["bug"]`) tiver **sucesso** (GitHub online), o próprio GitHub dispara imediatamente o webhook `issues.opened`, que é recebido pelo `/webhook/github` e envia o alerta para `#🛠️-bugs-e-feedbacks` e `NTFY_TOPICO_BUGS` (evitando duplicar mensagem no Discord/ntfy).
    - Quando a criação da GitHub Issue **falhar** (GitHub em *outage*), o `/webhook/sentry` enfileira o item `criar_issue_emergencia` (com `labels: ["bug"]` e `categoria: "bugs"`) na `FILA_RETENTATIVAS_ALERTAS` do Cloudflare KV e chama imediatamente `despacharNotificacaoComFallback` para a categoria `bugs`! Assim, o alerta chega na hora no Discord e no `ntfy` mesmo com o GitHub fora do ar, e quando o Cron Trigger criar a issue posteriormente, publica a confirmação.
  - Para **falhas gerais de workflows (`workflow_run`), Cloudflare (`check_run`) e Vercel (`status`)**:
    - `classificarWebhookGithub` retorna `categoria: "bugs"` com `dadosIssueEmergencia: { repositorio, titulo, corpo, labels: ["bug"] }`.
    - Para evitar que a Issue com label `bug` criada pelo próprio `aresta-climb-bot` para uma falha de workflow gere uma **segunda notificação duplicada** quando o GitHub enviar o webhook `issues.opened` de volta:
      - No evento `issues` (`action === "opened"`), se a issue NÃO veio do Sentry (ou seja, não é um `🐛 [Sentry] ...`) e o autor da abertura (`sender.login`) for `aresta-climb-bot[bot]` com título de falha de CI/deploy (`🐛 [CI/CD] ...`), `classificarWebhookGithub` ignora o eco do próprio bot porque `despacharNotificacaoComFallback` já enviou a notificação completa com o link da issue recém-criada!

### 2. Separação entre Recusa Legítima (`exit code 1`) e Erro de Infraestrutura/Script (`exit code >= 2`) nos `pr-*.yml` do `aresta_db`
- **Decisão**:
  1. Em `aresta_db/serving/pr_db_validator.py`:
     - Erros de validação de dados (cabeçalhos SPDX ausentes nos arquivos do PR, versão de migração desatualizada ou erro de validação de schema/croqui) retornam `1`.
     - Qualquer exceção inesperada de sistema/execução ou falha fora das regras de domínio (bloco `try/except` de topo em `main()`) imprime o traceback e retorna código de saída `2`.
  2. Nos workflows `.github/workflows/pr-db-validator.yml`, `pr-code-validator.yml` e `pr-integrator.yml`:
     - Padronizar o tratamento nos steps de validação para que, se o comando retornar `exit code >= 2` (erro interno de script, erro de configuração do `pytest`/`ruff` ou crash não tratado), o step registre explicitamente falha em um step sentinela `Erro Interno no Script de Validação` (ou que os steps de validação legítima tenham nomes canônicos conhecidos pelo Worker e só falhem isoladamente quando o código de saída for `1`).
  3. No `aresta-alertas-worker` (`cloudflare/alertas/src/index.ts`):
     - Quando chegar um `workflow_run` (`action === "completed"`) com falha (`failure`, `timed_out`, `startup_failure`):
       - Se o repositório for `aresta-climb/aresta_db` e o workflow for `Deploy para Cloudflare R2 e D1` (`.github/workflows/deploy.yml`): classifica imediatamente como **Emergência** (`categoria: "emergencias"`, `labels: ["emergencia"]`).
       - Se o repositório for `aresta-climb/aresta_db` e o caminho/nome do workflow corresponder a `pr-db-validator.yml`, `pr-code-validator.yml` ou `pr-integrator.yml` (independente da branch!):
         - O Worker consulta os jobs/steps da execução via `ClienteGithubApp.obterStepsFalhosWorkflowRun` (`GET /repos/{owner}/{repo}/actions/runs/{run_id}/jobs`).
         - Se **todos** os steps que falharam pertencerem ao conjunto de steps de recusa legítima de validação do PR (`"Run Validator"`, `"Verificar Formatação e Linting (Ruff)"`, `"Run Pytest"`, `"Validar DCO (Signed-off-by)"`, `"Aguardar e Validar Checagens do Pull Request"`), o Worker ignora o evento (`null` $\rightarrow$ HTTP `200`, `ignorado: true`).
         - Se **qualquer** step de infraestrutura/integração tiver falhado (ex: `"Generate Github App Token"`, `"checkout"`, `"Setup uv"`, `"Install dependencies"`, `"Comentar no PR"`, `"Erro Interno no Script de Validação"`, `"Executar Deploy Generated"`, `"Commitar e Enviar Alterações"`, `"Realizar Merge do PR"`, ou job sem steps por `startup_failure`), o Worker classifica como **Emergência** (`categoria: "emergencias"`, `labels: ["emergencia"]`)!

### 3. Destaque do Sentry e Repositório `aresta-climb/.github`
- **Decisão**:
  - Adicionar no `arestaclimb.com/index.html` (seção `#codigo-aberto` / rodapé) o badge oficial do Sentry (`https://sentry.io/branding/`) com link e agradecimento pelo plano *Sponsored Business*.
  - Adicionar seção de apoio do Sentry nos `README.md` de `aresta_app`, `aresta_db`, `aresta_backend` e `arestaclimb.com`.
  - Criar `c:\Renato\Devel\aresta-climb\.github\profile\README.md` com o resumo do ecossistema, link para `arestaclimb.com/editor`, comunidade (WhatsApp, Instagram, Discord) e infraestrutura/apoiadores.

## Risks / Trade-offs

- **[Risk] Chamada extra à API do GitHub (`/actions/runs/{id}/jobs`) quando um `pr-*.yml` falha** → **Mitigation**: A chamada só ocorre quando um `workflow_run` de `pr-*.yml` no `aresta_db` termina com falha; se a API do GitHub falhar ao consultar os jobs, assumimos postura segura (tratando como erro a investigar) e cobrimos o contrato com testes determinísticos no `ClienteGithubAppFake`.
