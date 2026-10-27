# Proposal

## Why

Atualmente, qualquer falha de workflow do GitHub Actions na branch principal ou de deploy externo (Cloudflare/Vercel) é classificada como emergência máxima, gerando alarmes críticos para falhas rotineiras de CI, enquanto falhas inesperadas de infraestrutura ou script nos workflows de Pull Request (`pr-*.yml`) do `aresta_db` passam despercebidas por rodarem em branches de PR ou se confundirem com recusas legítimas de validação. Além disso, caso o GitHub sofra uma indisponibilidade (*outage*) no momento em que um erro não-fatal surge no Sentry, a abertura da issue de bug precisa contar com a mesma fila persistente de retentativas em KV já usada para emergências. Por fim, com a aprovação do **Sentry Sponsored Business Plan**, precisamos destacar oficialmente o apoio do Sentry no site e nos repositórios e estruturar o `README.md` institucional da organização `aresta-climb` no GitHub.

## What Changes

- **Refinamento da Classificação de Falhas de Workflows e Deploys (`aresta_backend/cloudflare/alertas`)**:
  - Alterar falhas gerais de `workflow_run` em branches de produção/release (`main`, `master`, `v*`), bem como falhas de deploy externo (`check_run` da Cloudflare Pages/Workers e `status` da Vercel), para a categoria `bugs` (criando automaticamente uma GitHub Issue com label `bug` e notificando `#🛠️-bugs-e-feedbacks` e `NTFY_TOPICO_BUGS` com prioridade 3).
  - Manter qualquer falha no workflow `Deploy para Cloudflare R2 e D1` (`deploy.yml` do repositório `aresta-climb/aresta_db`) como **Emergência** (`categoria: "emergencias"`, label `emergencia`, `#🚨-emergencias` e `NTFY_TOPICO_EMERGENCIAS` com prioridade 5).
  - Monitorar execuções dos workflows de PR do `aresta_db` (`pr-db-validator.yml`, `pr-code-validator.yml` e `pr-integrator.yml`): distinguir recusas legítimas de validação do PR (que devem ser ignoradas pelo roteador de alertas) de falhas inesperadas do próprio workflow ou de seus scripts (que devem disparar **Emergência** com abertura de Issue `emergencia`).
- **Padronização de Códigos de Saída (*Exit Codes*) e Etapas nos Workflows `pr-*.yml` (`aresta_db`)**:
  - Padronizar `serving/pr_db_validator.py` e os workflows `pr-db-validator.yml`, `pr-code-validator.yml` e `pr-integrator.yml` para separar códigos de saída de recusa legítima de validação (`exit code 1`) de erros internos/inesperados de script ou infraestrutura (`exit code >= 2`), expondo etapas claras para inspeção via API do GitHub pelo `aresta-alertas-worker`.
- **Resiliência contra Outages do GitHub para Erros Não-Fatais do Sentry (`aresta_backend/cloudflare/alertas`)**:
  - Atualizar o fluxo de `issue.created` não-fatal no `/webhook/sentry` para que, caso a criação da GitHub Issue (`label: ["bug"]`) falhe por indisponibilidade da API do GitHub, o Worker enfileire a criação da issue na `FILA_RETENTATIVAS_ALERTAS` (Cloudflare KV) e envie imediatamente a notificação para o Discord (`#🛠️-bugs-e-feedbacks`) e `ntfy` (`NTFY_TOPICO_BUGS`).
- **Reconhecimento Oficial do Patrocínio do Sentry e Perfil da Organização `aresta-climb`**:
  - Adicionar seção/selo oficial de apoio do **Sentry** no portal web `arestaclimb.com` (`index.html`) e nos `README.md` dos repositórios (`aresta_app`, `aresta_db`, `aresta_backend`, `arestaclimb.com`).
  - Criar o repositório `.github` em `c:\Renato\Devel\aresta-climb\.github` contendo `profile/README.md` com o resumo do ecossistema, arquitetura, link para o Aresta Editor (`arestaclimb.com/editor`), canais da comunidade (WhatsApp, Instagram e Discord) e infraestrutura/apoiadores.

## Capabilities

### New Capabilities

### Modified Capabilities
- `roteador-alertas-whatsapp-e-fallback`: Refinamento das regras de severidade de falhas de CI/CD (`workflow_run`, `check_run`, `status`), detecção de falhas inesperadas de infraestrutura/script nos workflows `pr-*.yml` e `deploy.yml` do `aresta_db`, e fallback em fila KV para criação de issues de bugs não-fatais do Sentry durante indisponibilidades do GitHub.

## Impact

- **`aresta_backend`**: `cloudflare/alertas/src/index.ts` e `cloudflare/alertas/test/index.test.ts` (lógica de classificação de webhooks do GitHub, consulta de steps de jobs dos workflows `pr-*.yml` do `aresta_db`, criação automática de issues de bug para falhas de CI/CD e enfileiramento KV para bugs do Sentry em caso de outage do GitHub), além de `README.md`.
- **`aresta_db`**: `serving/pr_db_validator.py`, `tests/test_pr_db_validator.py`, `.github/workflows/pr-db-validator.yml`, `.github/workflows/pr-code-validator.yml`, `.github/workflows/pr-integrator.yml` e `README.md`.
- **`arestaclimb.com`**: `index.html` e `README.md`.
- **`aresta_app`**: `README.md` e `docs/guia_configuracao_observabilidade_e_alertas.md`.
- **`aresta-climb/.github`**: Novo repositório local em `c:\Renato\Devel\aresta-climb\.github\profile\README.md`.
