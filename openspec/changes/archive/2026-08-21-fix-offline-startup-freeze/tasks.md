## 1. Testes de Widget em Primeiro Lugar (TDD - Fase Vermelha)

- [x] 1.1 Atualizar `frontend/test/widgets/app_version_checker_test.dart` com teste que valida a renderização imediata do widget filho (`child`) no primeiro frame sem bloqueio de tela preta
- [x] 1.2 Adicionar teste de widget simulando atraso severo ou timeout na resposta do Remote Config e garantindo que a UI não congela
- [x] 1.3 Adicionar teste de widget para atualização reativa quando o Remote Config notificar uma nova versão mínima em segundo plano
- [x] 1.4 Adicionar testes unitários em `frontend/test/services/firebase/remote_config_service_test.dart` cobrindo a inicialização assíncrona não-bloqueante e emissão de eventos

## 2. Implementação do RemoteConfigService e AppVersionChecker (Fase Verde)

- [x] 2.1 Refatorar `RemoteConfigService` em `frontend/lib/services/firebase/remote_config_service.dart` para expor notificação reativa (`Listenable` / `ChangeNotifier`) quando o `fetchAndActivate()` em segundo plano for concluído
- [x] 2.2 Ajustar `RemoteConfigService.initialize()` para garantir que configurações padrão locais sejam carregadas instantaneamente sem travar chamadores
- [x] 2.3 Refatorar `AppVersionChecker` em `frontend/lib/widgets/app_version_checker.dart` para renderizar `child` imediatamente e escutar atualizações do Remote Config reativamente
- [x] 2.4 Remover o contêiner bloqueante `ColoredBox(color: Colors.black)` da árvore de renderização do `AppVersionChecker`

## 3. Refatoração, Documentação e Cobertura 100% (Fase Refactor)

- [x] 3.1 Adicionar e revisar docstrings completas em português (`///`) em todas as classes, métodos e parâmetros modificados
- [x] 3.2 Executar a suíte de testes (`flutter test`) e verificar 100% de cobertura nos arquivos modificados
- [x] 3.3 Validar que todos os testes passam sem regressões em todo o projeto
