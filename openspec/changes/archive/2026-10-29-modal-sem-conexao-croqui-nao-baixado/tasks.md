# Tasks

## 1. Consulta de Entidade por UID no Catálogo e Diagnóstico no Localizador

- [x] 1.1 Em ciclo TDD (*Red-Green-Refactor*), adicionar testes em `frontend/test/services/catalogo/repositorio_catalogo_test.dart` e implementar `obterItemPorUid(String uid)` em `frontend/lib/services/catalogo/repositorio_catalogo.dart` para resolver em $O(1)$ os metadados completos (`ItemCatalogoBusca`) de uma escalada, setor, grupo ou croqui, verificando 100% de cobertura em `repositorio_catalogo.dart`.
- [x] 1.2 Em ciclo TDD (*Red-Green-Refactor*), adicionar testes em `frontend/test/navigation/localizador_destino_uid_test.dart` e implementar `ResultadoBuscaDestinoUid` e `localizarComDiagnostico(String uid, {bool abrirMapa = false})` em `frontend/lib/navigation/localizador_destino_uid.dart` (garantindo que croquis em `/downloads` ou `/temp_cache` continuem abrindo offline e que falhas de rede retornem `itemSemConexao` preenchido via `catalogo.db` ou `indice.binarypb`), verificando 100% de cobertura em `localizador_destino_uid.dart`.

## 2. Componente Visual `ModalCroquiSemConexao` (Bottom Sheet)

- [x] 2.1 Em ciclo TDD (*Red-Green-Refactor*), criar o teste espelhado `frontend/test/widgets/bottom_sheets/modal_croqui_sem_conexao_test.dart` e implementar `ModalCroquiSemConexao` em `frontend/lib/widgets/bottom_sheets/modal_croqui_sem_conexao.dart` (exibindo tipo/nome da entidade, setor/grupo pai, nome e cidade/UF do croqui, estado de carregamento ao clicar em `"Tentar novamente"`, aviso inline caso continue sem conexão e fechamento automático em caso de sucesso), atualizando `frontend/lib/widgets/README.md` e validando 100% de cobertura em `modal_croqui_sem_conexao.dart`.

## 3. Integração com Deep Links (*Cold Start* e *Warm Start*) e Busca Global

- [x] 3.1 Em ciclo TDD (*Red-Green-Refactor*), atualizar `frontend/test/navigation/servico_navegacao_deep_link_test.dart` e `frontend/lib/navigation/servico_navegacao_deep_link.dart` para utilizar `localizarComDiagnostico`, registrar `AppLogger.instance.logAviso` e telemetria `croqui_offline_sem_conexao` (ou `uid_nao_encontrado_no_acervo` quando realmente inexistente) e acionar `ModalCroquiSemConexao` / callback `onCroquiSemConexao`, mantendo 100% de cobertura em `servico_navegacao_deep_link.dart`.
- [x] 3.2 Em ciclo TDD (*Red-Green-Refactor*), atualizar `frontend/lib/services/inicializacao_app.dart`, `frontend/lib/main.dart` e `frontend/lib/navigation/wrapper_navegacao_arvore.dart` (e seus respectivos testes espelhados `inicializacao_app_test.dart`, `main_test.dart` e `wrapper_navegacao_arvore_test.dart`) para propagar `itemSemConexaoInicial` resolvido durante o *Cold Start* e exibir o `ModalCroquiSemConexao` após a saída da splash screen, validando 100% de cobertura nos módulos alterados.
- [x] 3.3 Em ciclo TDD (*Red-Green-Refactor*), atualizar `frontend/test/widgets/busca_global_test.dart` e `frontend/lib/widgets/busca_global.dart` para que o toque em uma via, setor, grupo ou pico não baixado sem conexão (e ausente no `/temp_cache`) exiba o `ModalCroquiSemConexao` e navegue para o destino ao reconectar e tocar em `"Tentar novamente"`, mantendo 100% de cobertura em `busca_global.dart`.
