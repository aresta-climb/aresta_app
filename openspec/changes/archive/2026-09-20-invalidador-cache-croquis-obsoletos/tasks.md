## 1. Invalidador no DatasetRepository (TDD)

- [x] 1.1 Criar testes unitários em `test/services/dataset_repository_test.dart` cobrindo o método `invalidarCroquisObsoletos`, validando a limpeza de caminhos estáticos em `ConstrutorCaminhoTrajeto` e a remoção de sessões online cujo checksum divergiu do índice mestre (quando o pico não é o atualmente aberto), verificando a falha inicial do teste (Red).
- [x] 1.2 Implementar `invalidarCroquisObsoletos` em `frontend/lib/services/dataset_repository.dart` integrando a limpeza de `ConstrutorCaminhoTrajeto.limparCache()` e a iteração sobre `gerenciadorSessaoOnline.croquisEmMemoria`, verificando a passagem dos testes (Green).

## 2. Integração no Fluxo de Sincronização (SyncService)

- [x] 2.1 Adicionar testes unitários em `test/services/sync_service_test.dart` verificando que `syncIndex` chama `invalidarCroquisObsoletos` com o novo índice e a lista de picos atualizados ao concluir o commit atômico de arquivos, verificando a falha inicial (Red).
- [x] 2.2 Integrar a invocação de `datasetRepository.invalidarCroquisObsoletos` no fluxo de sucesso atômico de `syncIndex` em `frontend/lib/services/http/sync_service.dart`, verificando a passagem de todos os testes do serviço de sincronização (Green).

## 3. Limpeza Reativa em Tempo Real e Ciclo de Vida de UI

- [x] 3.1 Adicionar teste em `test/services/servico_croqui_online_test.dart` garantindo que o recebimento de nova versão de croqui via ETag dispara a limpeza do cache de trajetos, e integrar a invocação em `frontend/lib/services/http/servico_croqui_online.dart`, verificando a passagem do teste.
- [x] 3.2 Adicionar teste de widget em `test/pages/pico_test.dart` verificando que o descarte (`dispose`) de `PicoPage` limpa o cache de caminhos, e integrar a chamada no método `dispose` de `frontend/lib/pages/pico.dart`, verificando a passagem do teste.

## 4. Validação e Cobertura Completa

- [x] 4.1 Executar a suíte de testes de regressão dos módulos afetados via `flutter test test/services/ test/pages/pico_test.dart test/utils/construtor_caminho_trajeto_test.dart` garantindo 100% de aprovação e ausência de regressões.
