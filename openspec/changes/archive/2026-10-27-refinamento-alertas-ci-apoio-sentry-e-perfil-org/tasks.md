# Tasks

## 1. Padronização de Exit Codes e Workflows `pr-*.yml` no `aresta_db`

- [x] 1.1 Escrever testes em `aresta_db/tests/test_pr_db_validator.py` validando que `serving/pr_db_validator.py` retorna código de saída `0` em sucesso, `1` em recusas legítimas de validação de dados/cabeçalhos/migração, e `2` quando ocorre exceção inesperada de sistema/execução, verificando que os novos testes falham antes da implementação (*Red*).
- [x] 1.2 Implementar o tratamento de exceções inesperadas com código de saída `2` em `aresta_db/serving/pr_db_validator.py` e verificar que `uv run pytest tests/test_pr_db_validator.py` passa com 100% de cobertura (*Green*).
- [x] 1.3 Atualizar `.github/workflows/pr-db-validator.yml`, `.github/workflows/pr-code-validator.yml` e `.github/workflows/pr-integrator.yml` em `aresta_db` para distinguir nos steps de validação o código de saída `1` (recusa legítima do PR) de `>= 2` (falha interna de script, acionando step explícito `Erro Interno no Script de Validação`), verificando a validade sintática dos arquivos YAML.

## 2. Refinamento de Alertas de CI/CD e Fallback KV para Bugs no `aresta_backend`

- [x] 2.1 Escrever testes comportamentais em `aresta_backend/cloudflare/alertas/test/index.test.ts` cobrindo: (a) falhas gerais de `workflow_run` em `main`/`v*`, `check_run` da Cloudflare e `status` da Vercel classificadas como `bugs` com abertura de GitHub Issue `bug`; (b) falha no `deploy.yml` do `aresta_db` classificada como `emergencias`; (c) falha em `pr-*.yml` do `aresta_db` ignorada quando ocorre apenas em step de validação legítima, mas classificada como `emergencias` quando falha em step de infraestrutura ou `Erro Interno no Script de Validação`; e (d) enfileiramento na `FILA_RETENTATIVAS_ALERTAS` + envio imediato ao Discord/`ntfy` quando a criação de GitHub Issue para um erro não-fatal do Sentry falha por *outage* do GitHub (*Red*).
- [x] 2.2 Implementar em `aresta_backend/cloudflare/alertas/src/index.ts` a consulta de steps de jobs via `InterfaceClienteGithubApp` (`obterStepsFalhosWorkflowRun`), a nova classificação de `workflow_run`/`check_run`/`status` e o fallback na `FILA_RETENTATIVAS_ALERTAS` para issues de bugs não-fatais do Sentry, verificando que todos os testes em `cloudflare/alertas` passam (*Green*) e fazendo deploy do worker `aresta-alertas-worker`.
- [x] 2.3 Atualizar `docs/guia_configuracao_observabilidade_e_alertas.md` no `aresta_app` documentando a regra de severidade de workflows (`deploy.yml` e erros internos de `pr-*.yml` como emergência vs. demais workflows e deploys como bug) e o fallback em fila KV para bugs do Sentry.

## 3. Destaque do Patrocínio do Sentry e Repositório da Organização `aresta-climb/.github`

- [x] 3.1 Adicionar o card/selo oficial de apoio do **Sentry (Sponsored Business Plan)** com link e ativo oficial em `arestaclimb.com/index.html` e verificar que a suíte de testes do portal (`npm test` em `arestaclimb.com`) passa integralmente.
- [x] 3.2 Adicionar a seção de apoio do Sentry nos arquivos `README.md` de `aresta_app`, `aresta_db`, `aresta_backend` e `arestaclimb.com`, verificando a presença dos links e badges.
- [x] 3.3 Criar o repositório `c:\Renato\Devel\aresta-climb\.github` contendo `profile/README.md` com a apresentação do ecossistema, link para `arestaclimb.com/editor`, comunidade no WhatsApp, Instagram e Discord, e seção de infraestrutura e apoiadores liderada pelo Sentry, verificando que o arquivo foi criado e o repositório Git local inicializado na branch `main`.
