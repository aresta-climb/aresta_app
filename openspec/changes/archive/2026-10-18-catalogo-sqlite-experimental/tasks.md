# Tasks

## 1. Remoção de `atualizado_em` no `aresta_api`, Catálogo Determinístico e Túnel no `../aresta_db`

- [x] 1.1 Em `aresta_api` (`sql/catalogo.sql` e `openapi/catalogo.yaml`), remover o campo `atualizado_em` de `catalogo_croquis` / `CatalogoCroqui`, regenerar os contratos multi-linguagem (`catalogo_sql.{py,dart,ts}` e `catalogo.{py,dart,ts}`), sincronizar o submódulo em `aresta_app` e `../aresta_db` e verificar os testes do `aresta_api` com `pytest`.
- [x] 1.2 Em `../aresta_db/scripts/gerar_catalogo_sqlite_lib.py` e `../aresta_db/scripts/deploy_generated.py`, implementar via TDD a sincronização 1:1 do `catalogo.db` com os croquis do `indice.binarypb` sem `atualizado_em` (remoção por `croqui_uid` e `id_slug`, expurgo de croquis órfãos ausentes do índice e preservação dos bytes do banco quando os dados catalogados não mudarem), verificando com `pytest` em `../aresta_db/tests/test_gerar_catalogo_sqlite.py`.
- [x] 1.3 Em `../aresta_db/editor/core/tunel_retransmissor.py`, implementar via TDD a sanitização de query string (`?v=...`) e a reescrita de rotas compactas (`/<id>/<resto>` -> `/<resto>`) em `ClienteTunelRetransmissor._ler_arquivo_proxy`, verificando com `pytest` em `../aresta_db/tests/test_tunel_retransmissor.py`.
- [x] 1.4 Em `../aresta_db/editor/legacy_views/area_principal.py`, garantir via TDD que `_exibir_conexao_celular` salve/compile o croqui antes de abrir a conexão celular quando houver modificações não salvas ou quando `indice.binarypb` / `catalogo.db` não existirem na pasta `compilado/`, verificando com `pytest` nos testes da janela principal e atualizando a documentação pertinente.

## 2. Serialização do `RepositorioCatalogo` e Isolamento de Modo no `aresta_app`

- [x] 2.1 Em `frontend/lib/services/catalogo/repositorio_catalogo.dart`, implementar via TDD (em `frontend/test/services/catalogo/repositorio_catalogo_test.dart`) a serialização assíncrona das operações de banco e a remoção de arquivos auxiliares (`-wal`, `-shm`, `-journal`) em `substituirBancoCompleto`, verificando com `flutter test test/services/catalogo/repositorio_catalogo_test.dart --coverage`.
- [x] 2.2 Em `frontend/lib/services/editor_croqui.dart` e `frontend/lib/services/repositorio_dataset.dart`, implementar via TDD o fechamento aguardado (`await repositorioCatalogo.fechar()`) antes de `experimentalDir.deleteSync(recursive: true)` no `nukeExperimentalData()` e a limpeza de `gerenciadorSessaoOnline` na troca entre Modo Oficial e Modo Experimental, verificando com `flutter test test/services/editor_croqui_test.dart test/services/repositorio_dataset_test.dart --coverage`.

## 3. Sincronização Experimental, Live Reload e Reatividade da Busca Global no `aresta_app`

- [x] 3.1 Em `frontend/lib/view/function_library/funcoes_configuracoes.dart`, `frontend/lib/services/http/sync_service.dart` e `frontend/lib/services/inicializacao_app.dart`, garantir via TDD que `conectarEditor` reutilize o `SyncService` sem colisão com `onModeChange` e que `<docs>/editor/experimental/catalogo.db` seja baixado na conexão inicial e atualizado a cada evento de Live Reload, verificando com `flutter test test/view/function_library/funcoes_configuracoes_test.dart test/services/http/sync_service_test.dart test/services/inicializacao_app_test.dart --coverage`.
- [x] 3.2 Em `frontend/lib/widgets/busca_global.dart`, implementar via TDD (em `frontend/test/widgets/busca_global_test.dart`) a escuta reativa de `repositorioCatalogo.versaoNotificador` e `datasetRepo.activeDataset` para recarregar os resultados automaticamente após Live Reload ou troca de modo, e atualizar os arquivos `README.md` pertinentes, verificando com `flutter test test/widgets/busca_global_test.dart --coverage`.

## 4. Verificação Integrada de Ponta a Ponta

- [x] 4.1 Validar o fluxo integrado de Deep Link (`LocalizadorDestinoUid`) e Busca Global (`GlobalSearch`) em Modo Experimental e executar a suíte completa de testes e validação OpenSpec (`openspec validate catalogo-sqlite-experimental`).
