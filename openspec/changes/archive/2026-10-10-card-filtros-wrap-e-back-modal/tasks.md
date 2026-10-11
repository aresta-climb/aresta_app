# Tasks

## 1. Testes de Widget em Primeiro Lugar (TDD)

- [x] 1.1 Escrever testes de widget em `test/widgets/painel_filtros_indice_test.dart` validando a estrutura do card unificado com linha de cabeçalho 100% clicável e área inferior de chips distribuídos em `Wrap(spacing: 8, runSpacing: 8)` sem scroll horizontal.
- [x] 1.2 Escrever testes de widget em `test/widgets/painel_filtros_indice_test.dart` simulando o evento de pop nativo do sistema operacional (`handlePopRoute`) com o modal aberto em navegação completa, validando que o modal fecha no 1º toque e a página pai permanece intacta.

## 2. Implementação do Card Unificado e Correção do Back Modal

- [x] 2.1 Refatorar a barra externa em `lib/widgets/painel_filtros_indice.dart` para um card integrado em coluna com linha superior de toque de ponta a ponta e área inferior de chips em `Wrap`.
- [x] 2.2 Atualizar `_abrirModalControles` em `lib/widgets/painel_filtros_indice.dart` utilizando `useRootNavigator: true`, removendo interceptores manuais frágeis (`onBackInterceptor`) e simplificando o fechamento seguro via bloco `finally`.
- [x] 2.3 Executar `test/widgets/painel_filtros_indice_test.dart` e verificar que todos os testes de widget passam com sucesso.

## 3. Validação Geral e Documentação

- [x] 3.1 Executar a suíte de testes das páginas de exploração (`test/pages/setor_test.dart`, `test/pages/grupo_test.dart`, `test/pages/pico_subpages/setores_page_test.dart`) garantindo zero regressões.
- [x] 3.2 Atualizar a documentação técnica em `lib/widgets/README.md` documentando o card unificado com quebra de linha fluida e a abertura no `rootNavigator`.
- [x] 3.3 Executar `flutter analyze` e a validação estrita do OpenSpec, assegurando 0 issues.
