## 1. Componente Modal e Badge de Beta Aberto (TDD)

- [x] 1.1 Criar teste de widget em `frontend/test/widgets/modal_beta_aberto_test.dart` cobrindo a renderização do diálogo/modal explicativo, textos informativos e o acionamento do callback de feedback (garantir ciclo red inicial).
- [x] 1.2 Implementar o componente modular `ModalBetaAberto` e a função auxiliar `exibirModalBetaAberto` em `frontend/lib/widgets/modal_beta_aberto.dart` e validar aprovação dos testes de widget.
- [x] 1.3 Criar teste de widget para o micro-badge compacto em `frontend/test/widgets/micro_badge_beta_test.dart` validando as restrições estritas de tamanho e ausência de overflow em telas de 320dp e 360dp de largura.
- [x] 1.4 Implementar o widget `MicroBadgeBeta` em `frontend/lib/widgets/micro_badge_beta.dart` com estilo musgo (`dryMoss`), padding reduzido e ação de clique, validando aprovação dos testes.

## 2. Integração na Página Inicial (Home)

- [x] 2.1 Adicionar teste de widget no fluxo do cabeçalho da Home cobrindo a presença do `MicroBadgeBeta` e a abertura do modal ao ser tocado.
- [x] 2.2 Integrar o `MicroBadgeBeta` na linha de cabeçalho em `frontend/lib/view_functions/home_functions.dart` ao lado de `ARESTA` e executar `flutter test test/pages/home_test.dart` garantindo conformidade.

## 3. Identificação de Versão em Configurações e Comunidade

- [x] 3.1 Atualizar teste de widget em `frontend/test/pages/comunidade_test.dart` validando a exibição do sufixo `• Beta Aberto` no rodapé da versão.
- [x] 3.2 Atualizar o rodapé de versão em `frontend/lib/view_functions/comunidade_functions.dart` para `Aresta Climb v$version • Beta Aberto` e validar aprovação dos testes da Comunidade.
- [x] 3.3 Criar teste de widget em `frontend/test/pages/settings_test.dart` verificando a presença do rodapé de versão `Aresta Climb v$version (Beta Aberto)` e a abertura do modal de beta ao tocar.
- [x] 3.4 Implementar a exibição do rodapé de versão e atalho de beta na tela de Configurações (`frontend/lib/pages/settings.dart` e `frontend/lib/view_functions/settings_functions.dart`) e validar aprovação dos testes.

## 4. Splash Screen Nativa e Documentação

- [x] 4.1 Atualizar o asset `frontend/assets/logo_splash.png` incluindo a inscrição `CLIMB • BETA` mantendo dimensões, resolução e fidelidade visual.
- [x] 4.2 Executar o comando `dart run flutter_native_splash:create` e verificar a atualização dos manifestos e recursos nativos Android e iOS.
- [x] 4.3 Atualizar a documentação técnica em `frontend/lib/README.md` documentando o módulo de comunicação de Beta Aberto e executar a suíte de testes com `flutter test` garantindo integridade contínua.
