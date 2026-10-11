# Tasks

## 1. Modelo de Domínio e Cálculo de Amplitude de Graus

- [x] 1.1 Escrever testes unitários em `test/utils/filtro_grau_escalada_test.dart` validando `calcularFaixasGrauDisponiveis` para vias, boulders, pico com grau único e caso de pico sem graduações cadastradas.
- [x] 1.2 Implementar a classe `FaixaGrauDisponivel` e a função pura `calcularFaixasGrauDisponiveis` em `lib/utils/filtro_grau_escalada.dart` e verificar que todos os testes unitários passam.

## 2. Barra de Controles 100% Clicável

- [x] 2.1 Adicionar testes de widget em `test/widgets/painel_filtros_indice_test.dart` verificando que toques em qualquer ponto da barra sem filtros (inclusive centro e extrema direita) abrem o modal, e que toques no espaço vazio à direita dos chips também abrem o modal sem prejudicar o botão ✕.
- [x] 2.2 Atualizar `_buildBarraControlesEChips` em `lib/widgets/painel_filtros_indice.dart` utilizando `InkWell` expandido por toda a largura, ícone discreto `keyboard_arrow_down_rounded` na extrema direita e captura de toque na área neutra de chips.

## 3. Régua Adaptativa no Painel de Filtros

- [x] 3.1 Adicionar testes de widget em `test/widgets/painel_filtros_indice_test.dart` verificando a régua adaptativa com limites reais do pico, rótulos de extremidade, badge informativo de amplitude e caso de expansão para grau único.
- [x] 3.2 Atualizar `_buildSliderParaCategoria` em `lib/widgets/painel_filtros_indice.dart` para recortar `OpcoesGrau` de acordo com a `FaixaGrauDisponivel`, renderizar os rótulos de ponta e atualizar o badge para `Todos os graus (<min> a <max>)`.

## 4. Integração nas Páginas e Validação Completa

- [x] 4.1 Integrar `calcularFaixasGrauDisponiveis` em `SetoresPage` e `GrupoPage`, repassando `faixasGrauDisponiveis` para o `PainelFiltrosIndice`.
- [x] 4.2 Executar testes das páginas em `test/pages/pico_subpages/setores_page_test.dart` e `test/pages/grupo_test.dart` garantindo conformidade nos fluxos completos.
- [x] 4.3 Atualizar documentação em `lib/widgets/README.md` e rodar `flutter analyze` garantindo 0 warnings e conformidade estrita com o linter.
