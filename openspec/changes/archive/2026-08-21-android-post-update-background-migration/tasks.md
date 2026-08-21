## 1. Testes em Primeiro Lugar (TDD - Fase Vermelha)

- [x] 1.1 Criar testes unitários em `frontend/test/application_managers/migracao/migracao_background_orchestrator_test.dart` cobrindo a execução headless de migração de índice e croquis
- [x] 1.2 Criar testes em `frontend/test/main_test.dart` cobrindo o cancelamento de tarefa em segundo plano (`cancelarMigracaoSegundoPlano`) e a coordenação de primeiro plano no `setupAppServices`

## 2. Configuração Nativa do Android (Fase Verde)

- [x] 2.1 Configurar o receiver `ACTION_MY_PACKAGE_REPLACED` no `android/app/src/main/AndroidManifest.xml`
- [x] 2.2 Configurar o agendamento da tarefa única `tarefa_migracao_pos_atualizacao` no WorkManager com restrição de rede conectada

## 3. Migração Headless e Foreground Takeover (Fase Verde)

- [x] 3.1 Implementar o componente modular `MigracaoBackgroundOrchestrator` em `frontend/lib/application_managers/migracao/migracao_background_orchestrator.dart` e integrá-lo ao `callbackDispatcher`
- [x] 3.2 Implementar o cancelamento seguro da tarefa de segundo plano e coordenação de primeiro plano em `frontend/lib/main.dart`

## 4. Refatoração, Documentação e Cobertura 100% (Fase Refactor)

- [x] 4.1 Adicionar e revisar docstrings completas em português (`///`) em todas as novas funções, classes e métodos
- [x] 4.2 Executar a suíte de testes (`flutter test --coverage`) e verificar 100% de cobertura nos arquivos modificados
- [x] 4.3 Validar que toda a suíte de testes do projeto continua passando sem regressões


