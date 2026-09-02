## 1. Auto-Download e Navegação Pós-Conexão (TDD)

- [x] 1.1 Escrever testes unitários em `test/view_functions/settings_functions_test.dart` para auto-download imediato e navegação direta para `PicoNode` (1 croqui) e `BrowseNode` (>1 croquis) (Red)
- [x] 1.2 Implementar auto-download imediato e redirecionamento de rota em `conectarEditor` em `frontend/lib/view_functions/settings_functions.dart` com docstrings completas (Green)

## 2. Componente Modular BannerModoExperimental e Pulso Luminoso (Feature-First & Widget Tests)

- [x] 2.1 Adicionar notificador reativo `notificadorGatilhoRecarregamento` no `EditorDeCroqui` com testes unitários em `test/services/editor_croqui_test.dart` (Red-Green)
- [x] 2.2 Escrever testes de widget para o componente `BannerModoExperimental` em `test/widgets/banner_modo_experimental_test.dart` cobrindo exibição, pulso luminoso e ação de saída (Red)
- [x] 2.3 Implementar o widget modular `BannerModoExperimental` em `frontend/lib/widgets/banner_modo_experimental.dart` com animação de pulso e botão de saída rápida `[ Sair ✕ ]` (Green)
- [x] 2.4 Integrar o `BannerModoExperimental` no `frontend/lib/main.dart` com testes de integração em `test/main_test.dart`

## 3. Feedback de Sincronização Não-Intrusivo (TDD)

- [x] 3.1 Atualizar testes de comportamento de sincronização em `test/main_test.dart` para suprimir SnackBars em modo experimental e exibir notificação discreta em produção (Red)
- [x] 3.2 Ajustar `_onSyncStatusChanged` em `frontend/lib/main.dart` diferenciando modo experimental e modo oficial (Green)

## 4. Documentação e Qualidade (PRINCIPIOS.md)

- [x] 4.1 Validar que todas as classes, métodos, propriedades e variáveis estão em português brasileiro com docstrings explicativas (///)
- [x] 4.2 Atualizar o arquivo README.md de serviços/widgets documentando o fluxo de conexão, o BannerModoExperimental e o Hot Reload
- [x] 4.3 Executar a suíte completa de testes no Flutter (flutter test) e verificar 100% de cobertura e aprovação
