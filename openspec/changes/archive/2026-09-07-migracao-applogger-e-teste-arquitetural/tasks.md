## 1. TDD Fase Vermelha (RED) - Criação e Atualização dos Testes

- [x] 1.1 Criar o teste arquitetural `test/architecture/isolamento_logs_arquitetura_test.dart` fiscalizando ausência de `print` e `debugPrint` fora de `app_logger.dart` e validar que ele falha (RED) devido às ocorrências existentes
- [x] 1.2 Atualizar `test/services/firebase/app_logger_test.dart` adicionando testes para os novos métodos `logInfo` e `logAviso` (console em debug e breadcrumbs em release) e exigência de `required StackTrace stackTrace`
- [x] 1.3 Executar os testes unitários do logger e validar que falham/não compilam antes da implementação (RED)

## 2. TDD Fase Verde (GREEN) - Implementação no AppLogger e MockAppLogger

- [x] 2.1 Implementar `logInfo` e `logAviso` em `lib/services/firebase/app_logger.dart` com suporte a console e breadcrumbs via `FirebaseCrashlytics.instance.log`
- [x] 2.2 Alterar a assinatura de `logError`, `logCrash` e `logFalhaSyncOuDownload` para exigir `required StackTrace stackTrace`
- [x] 2.3 Atualizar `test/mocks/mock_app_logger.dart` com as novas assinaturas e coleções de eventos informativos
- [x] 2.4 Rodar os testes de `test/services/firebase/app_logger_test.dart` e garantir que passam com 100% de cobertura (GREEN)

## 3. Migração dos Blocos de Captura de Erros (Catches) e StackTrace

- [x] 3.1 Migrar catches de serviços de sincronização e rede (`sync_service.dart`, `sync_storage.dart`, `sync_network.dart`, `servico_croqui_online.dart`) para capturar `(e, stackTrace)` e repassar `stackTrace` ao `AppLogger`
- [x] 3.2 Migrar catches de background e notificações (`background_dispatcher.dart`, `migracao_background_orchestrator.dart`, `gerenciador_notificacao_download.dart`) para `AppLogger` com `stackTrace` obrigatório
- [x] 3.3 Migrar catches do editor de croqui, dataset e armazenamento (`editor_croqui.dart`, `dataset_repository.dart`, `extrator_assets_preload.dart`, `gerenciador_arquivos_locais.dart`, etc.)
- [x] 3.4 Migrar catches dos serviços Firebase e utilitários (`app_check_service.dart`, `remote_config_service.dart`, `telemetry_service.dart`, `construtor_caminho_trajeto.dart`)
- [x] 3.5 Migrar catches de páginas e view functions (`pico.dart`, `setor.dart`, `comunidade.dart`, `sobre_time.dart`, `terms_of_use.dart`, `mapa_interativo.dart`, `nearby_crags_carousel.dart`)
- [x] 3.6 Tratar pontos cegos com falhas engolidas silenciosamente (`database_migration_screen.dart` e `feedback_local_repository.dart`) enviando `stackTrace` ao `AppLogger`

## 4. Migração de Logs Informativos (debugPrint e print)

- [x] 4.1 Substituir chamadas informativas de `lib/main.dart` e orquestradores de migração/feedback por `AppLogger.instance.logInfo`
- [x] 4.2 Substituir chamadas informativas em serviços HTTP e sincronização (`sync_service.dart`, `update_downloader.dart`, `servico_download_segundo_plano.dart`, etc.)
- [x] 4.3 Substituir chamadas informativas em `editor_croqui.dart` e extratores de metadados
- [x] 4.4 Substituir chamadas diretas a `print` em `telemetry_service.dart` e `remote_config_service.dart` por `AppLogger.instance.logInfo` ou `logAviso`

## 5. Documentação Contínua e Validação Arquitetural (REFACTOR)

- [x] 5.1 Adicionar docstrings DartDoc em português (`///`) explicando a intenção e parâmetros de todos os métodos em `app_logger.dart`
- [x] 5.2 Atualizar a documentação técnica nos arquivos `lib/services/firebase/README.md` e `test/architecture/README.md` explicando o padrão arquitetural de logs
- [x] 5.3 Ativar `avoid_print: true` no arquivo `frontend/analysis_options.yaml`
- [x] 5.4 Executar o teste arquitetural `test/architecture/isolamento_logs_arquitetura_test.dart` e confirmar que agora passa com sucesso (GREEN)
- [x] 5.5 Executar `flutter analyze` e a suíte completa de testes (`flutter test`) garantindo zero warnings e 100% de conformidade com `PRINCIPIOS.md`
