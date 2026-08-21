## 1. Testes de Widget em Primeiro Lugar (TDD - Fase Vermelha)

- [x] 1.1 Criar testes de widget em `frontend/test/widgets/nearby_crags_carousel_test.dart` cobrindo o fallback de coordenadas salvas no `SharedPreferences` e ausência de chamadas HTTP externas
- [x] 1.2 Criar testes de widget em `frontend/test/pages/database_migration_screen_test.dart` cobrindo etapas de progresso, mensagem contextual de diagnóstico e auto-retry reativo ao restabelecer conectividade

## 2. Geolocalização Local e Cache no NearbyCragsCarousel (Fase Verde)

- [x] 2.1 Remover chamada a `http://ip-api.com/json/` e a dependência de rede externa em `frontend/lib/widgets/nearby_crags_carousel.dart`
- [x] 2.2 Implementar persistência de latitude/longitude no `SharedPreferences` e leitura de cache local como fallback em `frontend/lib/widgets/nearby_crags_carousel.dart`

## 3. Experiência de Migração com Fases e Auto-Retry (Fase Verde)

- [x] 3.1 Implementar fases de progresso (`verificando`, `baixando`, `concluido`, `erro`) e mensagem explicativa de diagnóstico em `frontend/lib/pages/database_migration_screen.dart`
- [x] 3.2 Implementar listener de conectividade (`Connectivity().onConnectivityChanged`) para auto-retry transparente em `frontend/lib/pages/database_migration_screen.dart`

## 4. Refatoração, Documentação e Cobertura 100% (Fase Refactor)

- [x] 4.1 Adicionar e revisar docstrings completas em português (`///`) em todos os métodos e classes modificados
- [x] 4.2 Executar a suíte de testes (`flutter test`) e verificar 100% de cobertura nos arquivos modificados
- [x] 4.3 Validar que todos os testes do projeto passam sem regressões
