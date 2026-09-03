## 1. Dependências e Permissões Nativas

- [ ] 1.1 Adicionar `flutter_local_notifications` ao `frontend/pubspec.yaml` e resolver dependências
- [ ] 1.2 Configurar permissões e declaração de foreground service de sincronização no `android/app/src/main/AndroidManifest.xml` (`FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_DATA_SYNC`, `POST_NOTIFICATIONS`)

## 2. Serviço de Notificações de Download (TDD)

- [ ] 2.1 Escrever testes unitários com mocks para `ServicoNotificacaoDownload` (`test/services/notificacoes/servico_notificacao_download_test.dart`) cobrindo registro de canal, cálculo de hash do pico, emissão contínua com `ongoing: true`, sucesso, erro e cancelamento
- [ ] 2.2 Implementar `ServicoNotificacaoDownload` em `lib/services/notificacoes/servico_notificacao_download.dart` seguindo os princípios de anti-abstração e simplicidade
- [ ] 2.3 Adicionar documentação contínua e docstrings completas no `frontend/lib/services/README.md`

## 3. Integração com SyncService e Orquestrador de Download (TDD)

- [ ] 3.1 Escrever testes de integração em `test/services/http/servico_download_segundo_plano_test.dart` verificando a comunicação entre o `SyncService` e o `ServicoNotificacaoDownload`
- [ ] 3.2 Integrar o `ServicoNotificacaoDownload` ao `ServicoDownloadSegundoPlano` e `SyncService.downloadCrag` para alimentar a barra de status do sistema operacional em tempo real
- [ ] 3.3 Rodar bateria completa de testes (`flutter test`) assegurando 100% de sucesso sem regressões
