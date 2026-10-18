# Proposal

## Why

No Modo Experimental (conectado ao Editor Desktop via LAN ou Cloudflare Relay), o aplicativo não está gerenciando nem sincronizando adequadamente o banco SQLite experimental (`<docs>/editor/experimental/catalogo.db`), o que impede o funcionamento de recursos essenciais dependentes do catálogo — como resolução de Deep Links/QR Codes por UID (`LocalizadorDestinoUid`) e a Busca Global (`GlobalSearch`) — além de provocar condições de corrida no `sqflite` ao alternar modos ou limpar dados experimentais (`nukeExperimentalData`). Precisamos garantir que o `catalogo.db` experimental funcione de ponta a ponta (tanto no `aresta_app` quanto no `../aresta_db`), mantendo-se estritamente sincronizado com os croquis distribuídos no `indice.binarypb` ativo.

## What Changes

- **Ciclo de Vida Seguro e Serializado do `RepositorioCatalogo` (`aresta_app`)**:
  - Serializar operações de abertura, fechamento e substituição (`substituirBancoCompleto`) no `RepositorioCatalogo` para evitar condições de corrida onde leituras concorrentes reabrem o banco durante uma substituição de arquivo ou troca de modo.
  - Remover eventuais arquivos auxiliares do SQLite (`-wal`, `-shm`, `-journal`) ao substituir ou limpar o `catalogo.db`.
  - Garantir que `EditorDeCroqui.nukeExperimentalData()` e as transições de modo (`DatasetRepository._handleModeChange` / `disconnect`) fechem e aguardem (`await`) o fechamento da conexão SQLite **antes** de excluir recursivamente o diretório `<docs>/editor/experimental/`, prevenindo `FileSystemException` por arquivo bloqueado.
- **Isolamento Estrito e Sincronização Determinística no Modo Experimental (`aresta_app`)**:
  - Limpar o cache em memória do `GerenciadorSessaoOnline` ao alternar entre o Modo Oficial e o Modo Experimental para evitar vazamento de croquis oficiais na busca/resolução experimental (e vice-versa).
  - Unificar o disparo de `SyncService.syncIndex()` em `conectarEditor` para reutilizar a instância existente do `SyncService` sem colidir com listeners concorrentes, garantindo que `<docs>/editor/experimental/catalogo.db` seja sempre baixado na conexão inicial (inclusive se o arquivo local ainda não existir) e atualizado a cada evento de Live Reload (`registrarOuvintesLiveReload`).
- **Reatividade da Busca Global (`aresta_app`)**:
  - Fazer `GlobalSearch` escutar `RepositorioCatalogo.versaoNotificador` e `DatasetRepository.activeDataset` para invalidar e recarregar os resultados automaticamente quando o `catalogo.db` experimental (ou oficial) for atualizado em segundo plano ou via Live Reload.
- **Remoção de `atualizado_em` do Schema do Catálogo (`aresta_api`, `../aresta_db` e `aresta_app`)**:
  - Remover a coluna sem uso `atualizado_em` de `sql/catalogo.sql` e a propriedade `atualizado_em` de `openapi/catalogo.yaml` no submódulo `aresta_api`, regenerando os contratos tipados (`catalogo_sql.{py,dart,ts}` e `catalogo.{py,dart,ts}`).
  - Atualizar `RepositorioCatalogo` (`aresta_app`) e `gerar_catalogo_sqlite_lib.py` (`../aresta_db`) para operar sem `atualizado_em` (e migrar automaticamente bancos locais legados que ainda possuam o schema antigo).
- **Geração Determinística, Expurgo de Órfãos e Rota Compacta no Editor Desktop (`../aresta_db`)**:
  - Em `gerar_catalogo_sqlite_lib.py` e `deploy_generated.py`, sincronizar estritamente o `catalogo.db` com os croquis presentes no `indice.binarypb` final (removendo registros anteriores por `croqui_uid` e por `id_slug`, expurgando registros órfãos ausentes do índice e evitando reescrever no SQLite quando os dados catalogados do croqui não mudaram).
  - Em `area_principal.py` (`_exibir_conexao_celular`), garantir que o croqui seja salvo/compilado antes de iniciar a conexão com o celular caso haja modificações pendentes ou caso `indice.binarypb` / `catalogo.db` ainda não existam na pasta `compilado/`.
  - Em `tunel_retransmissor.py` (`_ler_arquivo_proxy`), aplicar a mesma reescrita de rotas compactas do `ServidorCelular` (`/<id>/<resto>` -> `/<resto>` quando a pasta foi achatada no Windows) e sanitizar query strings (`?v=...`).

## Capabilities

### New Capabilities
<!-- Nenhuma nova capability isolada necessária; os requisitos estendem capabilities existentes. -->

### Modified Capabilities
- `catalogo-sqlite-sync`: Adiciona requisitos de isolamento e sincronização direta do `catalogo.db` no Modo Experimental, serialização de conexões SQLite e fechamento seguro antes de exclusão física do diretório experimental.
- `busca-global-catalogo`: Adiciona requisito de atualização reativa automática da Busca Global quando `RepositorioCatalogo.versaoNotificador` ou o dataset ativo mudarem (incluindo Live Reload e troca entre modo oficial e experimental).
- `hot-reload-experiencia-usuario`: Atualiza os requisitos de conexão experimental, Live Reload e desconexão/limpeza para contemplar a sincronização do `catalogo.db` experimental e o expurgo de sessões online em memória.

## Impact

- **`aresta_api` (`frontend/lib/aresta_api` e `../aresta_db/aresta_api`)**:
  - `sql/catalogo.sql` e `openapi/catalogo.yaml` (remoção de `atualizado_em` e regeneração de `sql/generated/*` e `openapi/generated/*`)
- **`aresta_app` (`frontend/`)**:
  - `lib/services/catalogo/repositorio_catalogo.dart`
  - `lib/services/editor_croqui.dart`
  - `lib/services/repositorio_dataset.dart`
  - `lib/services/http/sync_service.dart`
  - `lib/services/inicializacao_app.dart`
  - `lib/view/function_library/funcoes_configuracoes.dart`
  - `lib/widgets/busca_global.dart`
  - `lib/main.dart`
  - Testes espelhados 1:1 em `test/`
- **`../aresta_db`**:
  - `scripts/gerar_catalogo_sqlite_lib.py`
  - `scripts/deploy_generated.py`
  - `editor/core/tunel_retransmissor.py`
  - `editor/legacy_views/area_principal.py`
  - Testes correspondentes em `../aresta_db/tests/`
