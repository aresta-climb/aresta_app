---
name: diagnosticar-issue-sentry
description: Diagnostica e resolve bugs a partir de uma Issue do GitHub ou link do Sentry usando o servidor MCP do Sentry. Use quando o usuário pedir para investigar ou corrigir uma issue do GitHub ligada ao Sentry, um crash de produção ou uma falha encontrada pelo Robô Caótico.
---

# Diagnosticar Issues do Sentry a partir do GitHub (via MCP)

Nos repositórios do ecossistema Aresta conectados ao Sentry (`aresta_app`, `aresta_db`, `aresta_backend` e `arestaclimb.com`), o roteador de alertas (`aresta-alertas-worker`) abre automaticamente Issues no GitHub contendo apenas o resumo e o link direto para a Issue no Sentry (`https://aresta-climb.sentry.io/issues/<ID_SENTRY>/`).

Os detalhes ricos de diagnóstico — **StackTrace completo**, **Breadcrumbs normais da aplicação**, **`contexto_erro`** e eventuais receitas de reprodução (**`receita_robo_caotico`**) — ficam armazenados no **Sentry** e devem ser consultados pelo agente através do **MCP do Sentry**.

---

## 1. Verificar e Configurar o MCP do Sentry (Caso Não Esteja Ativo)

Antes de consultar a issue, verifique se o servidor MCP do Sentry (`sentry_sentry` ou `sentry`) está disponível nas ferramentas da sessão atual.

### Caso o MCP do Sentry NÃO esteja instalado ou configurado:

1. **No Google Antigravity (AGY)**:
   - Sugira o plugin oficial do Sentry exibindo o card abaixo em uma linha própria e oriente o usuário a adicioná-lo e fazer login na organização `aresta-climb`:
     `<plugin-card catalog-id="antigravity-plugins-partners/plugin/sentry"></plugin-card>`
   - Se o plugin já estiver instalado mas desautenticado (verifique com a ferramenta `list_plugin_accounts`), informe exatamente qual provedor reconectar no *Plugins Manager*.

2. **No Cursor / VS Code / Claude Code / Outros Clientes MCP**:
   - Instrua o usuário a adicionar o servidor MCP remoto oficial do Sentry no arquivo de configuração de MCP do cliente (`.cursor/mcp.json`, `.vscode/mcp.json` ou equivalente):
     ```json
     {
       "mcpServers": {
         "sentry": {
           "url": "https://mcp.sentry.dev/mcp"
         }
       }
     }
     ```
   - Na primeira execução, o cliente abrirá o fluxo OAuth no navegador para autenticar na organização `aresta-climb` no Sentry.

---

## 2. Passo a Passo para Diagnosticar a partir da Issue do GitHub

### Passo 1 — Obter o Link / ID do Sentry na Issue do GitHub
Quando o usuário informar o número de uma Issue do GitHub (ex: `#142` ou URL da issue):
1. Consulte o corpo da Issue via GitHub CLI:
   ```bash
   gh issue view <NUMERO_ISSUE> --json number,title,body,labels,url
   ```
2. Extraia do campo `body` a URL do Sentry no formato:
   `https://aresta-climb.sentry.io/issues/<ID_SENTRY>/` (ou o identificador `<ID_SENTRY>`).

### Passo 2 — Puxar o Contexto Completo no Sentry via MCP
Com a URL ou `<ID_SENTRY>` em mãos, utilize as ferramentas do servidor MCP do Sentry (`call_mcp_tool` no servidor `sentry_sentry` / `sentry`):
1. **Buscar a Issue e o Evento Representativo**:
   - Invoque `get_sentry_resource` passando a URL ou ID da issue no Sentry.
   - Caso precise de detalhes adicionais do evento (stacktrace detalhado, breadcrumbs completos, tags ou anexos), utilize `search_sentry_tools` e `execute_sentry_tool` (ex: `get_event_stacktrace`, `get_issue_breadcrumbs`, `get_event_attachment`).
2. **Inspecionar os 4 Sinais Obrigatórios no Evento do Sentry**:
   - **Exceção e StackTrace**: arquivo, classe, método e linha exatos onde ocorreu a falha.
   - **Contexto do Erro (`contexts.contexto_erro`)**: mensagem de contexto operacional e indicador `fatal` registrados pelo logger.
   - **Breadcrumbs Normais da Aplicação**: trilha cronológica de eventos de telemetria, navegação e logs que antecederam o erro.
   - **Receita do Robô Caótico (`contexts.receita_robo_caotico`)** *(específico para `aresta_app`)*: se presente, contém o JSON completo com `seed`, `dataset` (`normal` ou `toxico`), `passos_minimos` (encolhidos por busca binária) e `passos_originais`.

### Passo 3 — Reproduzir com Teste (Red), Corrigir (Green) e Evitar Regressão
Siga rigorosamente o `AGENTS.md` do repositório (100% em português, TDD *Red-Green-Refactor*, sem mocks para código interno):

- **Se o evento contiver `contexts.receita_robo_caotico` (no `aresta_app`)**:
  1. Salve o JSON da receita em:
     `frontend/test/caos/caminhos_regressao/issue_<NUMERO_ISSUE>_seed_<SEED>.json`
  2. Execute a suíte de regressão de caminhos para reproduzir o crash em `< 1s` (*Red*):
     ```bash
     flutter test test/caos/regressao_caminhos_test.dart
     ```
  3. Corrija a causa raiz no código de produção e adicione/atualize o teste unitário/widget espelhado (`_test.dart`) até que tanto o teste espelhado quanto `regressao_caminhos_test.dart` passem (*Green*).
  4. **Mantenha o arquivo `.json` commitado** em `frontend/test/caos/caminhos_regressao/` para que o caminho seja executado automaticamente em todos os PRs e releases futuros.

- **Para demais crashes e erros de produção (nos 4 repositórios)**:
  1. Reproduza o cenário descrito pelo StackTrace + Breadcrumbs escrevendo primeiro um teste automatizado que falhe (*Red*).
  2. Aplique a correção mínima e limpa na causa raiz (*Green*) e refatore mantendo 100% de cobertura comportamental.
  3. Ao fazer commit ou abrir PR, referencie `Fixes #<NUMERO_ISSUE>` (o `aresta-alertas-worker` resolverá automaticamente a issue correspondente no Sentry quando a Issue do GitHub for fechada).
