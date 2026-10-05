# Tasks

## 1. Testes e Compactação da Interface do Bottom Sheet (TDD)

- [x] 1.1 Atualizar testes de widget em `test/widgets/feedback/construtor_feedback_usuario_test.dart` para validar a nova mensagem direta "Feedback público. Nenhum dado pessoal é exposto.", a presença de `FittedBox` e a compacidade visual (`VisualDensity.compact`), verificando a falha inicial controlada dos testes (Red) via `flutter test test/widgets/feedback/construtor_feedback_usuario_test.dart`.
- [x] 1.2 Implementar as alterações em `lib/widgets/feedback/construtor_feedback_usuario.dart`, aplicando `VisualDensity.compact` e ícones de 16 px no `SegmentedButton`, reduzindo espaçamentos verticais para 6 dp, otimizando o campo de texto para compacidade, substituindo a caixa de aviso por linha única com `FittedBox` e ajustando a altura do botão de envio para 42 dp, verificando aprovação total dos testes (Green).

## 2. Dimensionamento Adaptativo no BetterFeedback

- [x] 2.1 Adicionar teste para validação do cálculo dinâmico da fração de altura `feedbackSheetHeight` (clamp entre 0.22 e 0.45 correspondente a ~220 dp) em `test/widgets/feedback/`, verificando a falha inicial controlada do teste (Red).
- [x] 2.2 Configurar o parâmetro `feedbackSheetHeight` no `FeedbackThemeData` em `lib/main.dart` com cálculo dinâmico baseado na altura lógica da janela (`(220.0 / alturaTela).clamp(0.22, 0.45)`), verificando que o teste passa com sucesso (Green).

## 3. Atualização da Política de Privacidade e Sincronização Legal

- [x] 3.1 Atualizar `frontend/legal/repo/public/docs/politica-de-privacidade.md` adicionando a seção sobre envio de feedbacks (visibilidade pública no GitHub e diagnósticos técnicos restritos no Supabase) e incluindo GitHub e Supabase como provedores na relação de terceiros.
- [x] 3.2 Executar o gerador de hash jurídico via `dart run tool/legal_updater/bin/update_legal_version.dart` e verificar a atualização gerada em `lib/core/legal/legal_version.g.dart`.
- [x] 3.3 Executar os testes de integridade legal via `flutter test test/core/legal/` e verificar que todas as asserções de hash e integridade são aprovadas sem divergências.

## 4. Validação Geral e Documentação

- [x] 4.1 Executar a suíte completa de testes de feedback via `flutter test test/widgets/feedback/` e a análise estática via `flutter analyze`, verificando 100% de sucesso e zero linter issues.
- [x] 4.2 Revisar docstrings e documentação técnica nos arquivos alterados (`lib/widgets/feedback/construtor_feedback_usuario.dart` e `lib/main.dart`), assegurando explicações claras do racional e conformidade total com o AGENTS.md.
