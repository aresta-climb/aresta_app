## 1. Controlador de Configuração do Mantenedor

- [ ] 1.1 Escrever testes unitários em `test/services/configuracao_mantenedor_controller_test.dart` cobrindo valor padrão desativado, salvamento e carregamento via `SharedPreferences` (executar `flutter test test/services/configuracao_mantenedor_controller_test.dart` e verificar falha inicial)
- [ ] 1.2 Implementar `ConfiguracaoMantenedorController` em `frontend/lib/services/configuracao_mantenedor_controller.dart` com `ValueNotifier<bool>` e persistência local, verificando aprovação dos testes unitários

## 2. Utilitário de Geração de Link Fixalog

- [ ] 2.1 Escrever testes unitários em `test/utils/fixalog_link_utils_test.dart` validando a geração de URL em `fixalog.arestaclimb.com` para vias em setores diretos, vias em grupos e normalização com caracteres especiais (executar `flutter test test/utils/fixalog_link_utils_test.dart` e verificar falha inicial)
- [ ] 2.2 Implementar `gerarLinkFixalog` em `frontend/lib/utils/fixalog_link_utils.dart` integrado a `slug_utils.dart`, verificando aprovação dos testes unitários

## 3. Interface de Configurações

- [ ] 3.1 Escrever testes de widget em `test/widgets/card_ferramentas_mantenedor_test.dart` verificando a renderização do card, estado inicial do interruptor e alteração reativa ao alternar o Switch (executar `flutter test test/widgets/card_ferramentas_mantenedor_test.dart` e verificar falha inicial)
- [ ] 3.2 Implementar `buildCardFerramentasMantenedor` em `frontend/lib/view_functions/settings_functions.dart` e integrá-lo em `frontend/lib/pages/settings.dart`, garantindo a passagem dos testes de widget

## 4. Integração na Página de Detalhes da Escalada (ViaPage)

- [ ] 4.1 Escrever testes de widget em `test/view_functions/via_functions_fixalog_test.dart` validando que o botão "Manutenir no Fixalog" aparece apenas quando o modo mantenedor está ativado, em vias com e sem histórico anterior, e dispara `launchUrl` ao ser tocado (executar `flutter test test/view_functions/via_functions_fixalog_test.dart` e verificar falha inicial)
- [ ] 4.2 Integrar o botão no bloco de Histórico e Conquista em `frontend/lib/view_functions/via_functions.dart` com chamada a `gerarLinkFixalog`, registro de telemetria e tratamento de falha com `SnackBar`, verificando a passagem dos testes de widget

## 5. Validação Geral e Documentação

- [ ] 5.1 Executar análise estática e suite de testes do projeto (`flutter analyze` e `flutter test`) garantindo ausência de regressões e 100% de cobertura nas novas unidades
- [ ] 5.2 Revisar e documentar o novo fluxo e componentes através de docstrings `///` em português brasileiro e atualizar documentações pertinentes
