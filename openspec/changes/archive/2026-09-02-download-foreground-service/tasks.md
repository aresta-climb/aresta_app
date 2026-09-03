## 1. Configurações Nativas e Dependências

- [x] 1.1 Adicionar dependência `flutter_local_notifications` ao `frontend/pubspec.yaml` e executar resolução de dependências
- [x] 1.2 Configurar permissões no `android/app/src/main/AndroidManifest.xml` (`FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_DATA_SYNC`, `POST_NOTIFICATIONS`)
- [x] 1.3 Configurar permissões de notificação e modos de execução no `ios/Runner/Info.plist`

## 2. Gerenciador de Notificações de Download (TDD)

- [x] 2.1 Escrever testes unitários com mocks para `GerenciadorNotificacaoDownload` (`test/services/notificacoes/gerenciador_notificacao_download_test.dart`) cobrindo inicialização multiplataforma, solicitação de permissões, emissão de progresso persistente (`ongoing: true`) no Android, conclusão e tratamento de falhas
- [x] 2.2 Implementar `GerenciadorNotificacaoDownload` em `lib/services/notificacoes/gerenciador_notificacao_download.dart` seguindo estritamente os princípios de anti-abstração e simplicidade
- [x] 2.3 Adicionar documentação contínua e docstrings completas no `frontend/lib/services/README.md`

## 3. Integração com SyncService e Orquestrador de Download (TDD)

- [x] 3.1 Escrever testes de integração em `test/services/http/servico_download_segundo_plano_test.dart` verificando a orquestração entre `SyncService` e `GerenciadorNotificacaoDownload`
- [x] 3.2 Integrar o `GerenciadorNotificacaoDownload` ao `ServicoDownloadSegundoPlano` e ao loop de download do `SyncService.downloadCrag` para alimentar o sistema operacional em tempo real
- [x] 3.3 Executar a suíte completa de testes (`flutter test`) assegurando 100% de aprovação e ausência de regressões
