## 1. Testes em Primeiro Lugar (TDD)

- [x] 1.1 Atualizar `frontend/test/widgets/banner_modo_experimental_test.dart` removendo asserções de timer e validando exibição limpa do texto 'MODO EXPERIMENTAL ATIVO' e botão 'SAIR' (Red)
- [x] 1.2 Atualizar `frontend/test/services/experimental_mode_test.dart` removendo testes de expiração de temporizador de 20 minutos e adicionando validações de sessão volátil sem tempo limite (Red)

## 2. Refatoração do Serviço EditorDeCroqui

- [x] 2.1 Remover `_countdownTimer`, `timeRemaining`, `_expirationTime`, `_startCountdown` e o parâmetro `forceResetTimer` em `frontend/lib/services/editor_croqui.dart`
- [x] 2.2 Remover referências ao scheme `aresta-zip://` em `frontend/lib/services/editor_croqui.dart` e consolidar a limpeza compulsória no boot em `loadFromDisk()`
- [x] 2.3 Executar `flutter test test/services/experimental_mode_test.dart test/services/editor_croqui_test.dart` e verificar aprovação com cobertura total (Green)

## 3. Simplificação do Banner e Telas de Configurações

- [x] 3.1 Refatorar `frontend/lib/widgets/banner_modo_experimental.dart` removendo o ouvinte de `timeRemaining` e simplificando a árvore de widgets mantendo a animação de pulso
- [x] 3.2 Remover checagens residuais de extensão `.croqui`/`.zip` e atualizar o texto do card de conexão em `frontend/lib/view_functions/settings_functions.dart`
- [x] 3.3 Executar `flutter test test/widgets/banner_modo_experimental_test.dart` e validar integridade dos widgets de interface (Green)

## 4. Verificação de Integridade, Documentação e Validação

- [x] 4.1 Verificar que o submódulo `frontend/lib/aresta_api` permaneceu intocado e que nenhuma referência residual a arquivos locais `.croqui` ou `aresta-zip://` persiste no `aresta_app`
- [x] 4.2 Atualizar `frontend/lib/services/README.md` e `frontend/README.md` documentando o ciclo de vida sem limite de tempo e exclusivo para conexão remota
- [x] 4.3 Executar análise estática e suíte completa de testes (`flutter test`) garantindo 100% de sucesso e conformidade com as diretrizes de engenharia
