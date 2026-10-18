# Design

## Context

Conforme descrito em `proposal.md`, o Modo Experimental compartilha o mesmo contrato arquitetural de catálogo SQLite (`catalogo.db`) que o Modo Oficial, porém aponta para um diretório isolado (`<docs>/editor/experimental/catalogo.db`) e consome artefatos gerados localmente pelo Editor Desktop (`../aresta_db`) e servidos via Direct LAN (`ServidorCelular`) ou Cloudflare Relay (`ClienteTunelRetransmissor`).

Atualmente, cinco falhas impedem que o `catalogo.db` funcione com confiabilidade no Modo Experimental:
1. No `../aresta_db`, abrir um croqui experimental e clicar em "Conectar Celular" sem salvar antes pode servir uma pasta `compilado/` sem `catalogo.db`.
2. No `../aresta_db`, `ClienteTunelRetransmissor._ler_arquivo_proxy` não aplica a reescrita de rotas compactas (`/<id>/<resto>` -> `/<resto>`) que o `ServidorCelular` aplica para contornar o limite `MAX_PATH` do Windows, nem remove query strings (`?v=...`).
3. No `../aresta_db`, `gerar_catalogo_completo` não expurga croquis órfãos (quando o UID/ID muda ou quando o índice tem menos croquis) e grava `atualizado_em = int(time.time())` a cada save, mutando os bytes físicos do `catalogo.db` mesmo sem alterações de conteúdo.
4. No `aresta_app`, `nukeExperimentalData()` deleta recursivamente `<docs>/editor/experimental/` enquanto o `sqflite` (`RepositorioCatalogo`) ainda mantém `catalogo.db` aberto, e `conectarEditor` instancia um segundo `SyncService` concorrente ao listener `onModeChange` do `main.dart`.
5. No `aresta_app`, `GlobalSearch` não escuta `RepositorioCatalogo.versaoNotificador` e `GerenciadorSessaoOnline` não é limpo ao alternar entre modo oficial e experimental.

## Goals / Non-Goals

**Goals:**
- Garantir sincronia 1:1 estrita entre os croquis distribuídos no `indice.binarypb` e os registros de `catalogo.db` (se o índice tem 1 croqui, o `catalogo.db` contém apenas esse croqui; se tem todos, contém todos, sem registros órfãos).
- Manter os bytes físicos de `catalogo.db` estáveis entre saves quando os dados catalogados não mudarem.
- Garantir paridade total de roteamento compacto entre Direct LAN (`ServidorCelular`) e Túnel WebSocket (`ClienteTunelRetransmissor`).
- Eliminar condições de corrida e locks de arquivo SQLite no `RepositorioCatalogo` durante trocas de modo, `substituirBancoCompleto` e `nukeExperimentalData`.
- Fazer Deep Links (`LocalizadorDestinoUid`) e Busca Global (`GlobalSearch`) funcionarem perfeitamente e reativamente no Modo Experimental.

**Non-Goals:**
- Mesclar o catálogo oficial com o catálogo experimental (o isolamento entre os dois modos deve permanecer estrito).

## Decisions

### 1. Remoção de `atualizado_em` do Schema e Sincronização 1:1 do `catalogo.db` com `indice.binarypb` (`aresta_api` + `../aresta_db`)
- **Decisão**:
  - Remover completamente a coluna `atualizado_em` de `sql/catalogo.sql` (tabela `catalogo_croquis`) e de `openapi/catalogo.yaml` (`CatalogoCroqui`) no `aresta_api`, regenerando os artefatos Python, Dart e TypeScript. Eliminar a coluna na origem impede qualquer mutação não-determinística por timestamp na geração do `catalogo.db`.
  - Em `gerar_catalogo_sqlite_lib.py`:
    - Se um banco `catalogo.db` existente ainda contiver a coluna legada `atualizado_em` em `catalogo_croquis`, recriar/migrar a tabela sem a coluna.
    - Ao processar cada croqui alvo, verificar se os dados extraídos (`dados_croqui` e a lista ordenada de `registros_aresta`) já são idênticos aos armazenados no `catalogo.db`. Se forem idênticos, pular a reescrita no SQLite para manter os bytes físicos do arquivo `catalogo.db` inalterados.
    - Antes de inserir um croqui modificado, remover registros anteriores tanto por `croqui_uid` quanto por `id_slug` (garantindo que uma mudança de `uid` ou `id` não deixe o registro antigo órfão).
    - Sincronizar o `catalogo.db` com os croquis do `indice.binarypb` final (`ids_permitidos`), expurgando de `catalogo_croquis` e `catalogo_aresta` qualquer croqui que não pertença ao índice gerado.
- **Alternativas consideradas**:
  - *Recriar o `catalogo.db` do zero a cada save*: Descartado porque em um repositório completo (`LocalRepoWorkspace`) reprocessar dezenas de croquis seria mais lento e mudaria o binário a cada build.

### 2. Compilação Garantida Antes de Conectar ao Celular e Rota Compacta no Túnel (`../aresta_db`)
- **Decisão**:
  - Em `JanelaPrincipal._exibir_conexao_celular` (`area_principal.py`), verificar se há alterações não salvas (`not self.historico.obter_pilha().isClean()`) ou se `indice.binarypb` / `catalogo.db` não existem em `self.workspace.obter_pasta_servidor_celular()`. Caso positivo, disparar `self.salvar_croqui(callback_sucesso=...)` antes de iniciar o `ServidorCelular` e abrir o diálogo.
  - Em `ClienteTunelRetransmissor._ler_arquivo_proxy` (`tunel_retransmissor.py`), remover query strings (`caminho_str.split("?", 1)[0]`) e aplicar a mesma lógica de `ServidorCelular.reescrever_rotas_compactas`: se `caminho_str` tiver formato `<subpasta>/<resto>`, `(pasta_base / subpasta)` não existir e `(pasta_base / resto)` existir dentro de `pasta_base`, resolver para `pasta_base / resto`.

### 3. Serialização de Operações e Fechamento Prévio no `RepositorioCatalogo` (`aresta_app`)
- **Decisão**:
  - Adicionar uma fila/trava assíncrona (`_operacaoEmAndamento`) no `RepositorioCatalogo` para serializar `_obterBanco()`, `fechar()`, `substituirBancoCompleto()` e `aplicarDelta()`.
  - Em `substituirBancoCompleto`, após fechar o banco e antes de renomear `$caminho.tmp` para `$caminho`, remover possíveis arquivos `$caminho-wal`, `$caminho-shm` e `$caminho-journal`.
  - Em `EditorDeCroqui`, permitir registrar um callback assíncrono `aoAntesDeLimparExperimental` (ou coordenar via `DatasetRepository`) para que `nukeExperimentalData()` feche e aguarde (`await repositorioCatalogo.fechar()`) e limpe `gerenciadorSessaoOnline` **antes** de executar `experimentalDir.deleteSync(recursive: true)`.
  - Em `DatasetRepository._handleModeChange()`, limpar `gerenciadorSessaoOnline.limparTudo()` (ou remover sessões ativas) e aguardar `await repositorioCatalogo.fechar()` antes de recarregar o índice do novo modo.

### 4. Reutilização do `SyncService` e Reatividade da `GlobalSearch` (`aresta_app`)
- **Decisão**:
  - Em `conectarEditor` e `mostrarDialogConexao` (`funcoes_configuracoes.dart`), resolver a instância ativa do `SyncService` (via parâmetro ou `TreeNavigationWrapper.of(context).syncService`) e evitar disparar `syncIndex` duplicado em corrida com o listener `onModeChange`.
  - Em `GlobalSearch` (`busca_global.dart`), registrar listeners em `widget.datasetRepo.repositorioCatalogo.versaoNotificador` e `widget.datasetRepo.activeDataset` no `initState` (removendo no `dispose`), invalidando `_hasLoadedData` e recarregando quando o modal estiver expandido.

## Risks / Trade-offs

- **[Risco] Lock de arquivo SQLite no Windows durante testes ou uso desktop** → Mitigado pela serialização assíncrona no `RepositorioCatalogo` e pelo `await repositorioCatalogo.fechar()` obrigatório antes de qualquer operação de `deleteSync` ou `rename`.
- **[Risco] Latência ao clicar em "Conectar Celular" quando há alterações pendentes no Editor Desktop** → Mitigado reutilizando o fluxo existente de `salvar_croqui(callback_sucesso=...)`, que já exibe o indicador visual `"Salvando..."` e abre o modal de conexão imediatamente após a conclusão do worker.
