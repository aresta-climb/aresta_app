# Tasks

## 1. Limite de Altura dos Seletores e Rodapé Aplicar em `PainelFiltrosIndice`

- [x] 1.1 Escrever testes de widget falhando (Red) em `frontend/test/widgets/painel_filtros_indice_test.dart` validando: (a) que os seletores de localização e conquistadores possuem `menuMaxHeight: 280` e podem ser fechados com toque externo sem selecionar item; (b) que o botão de rodapé exibe `Aplicar (X resultados)` (e `Aplicar (1 resultado)` no singular ou `Aplicar` quando `totalResultados` é nulo) e fecha o modal preservando os filtros aplicados
- [x] 1.2 Implementar `menuMaxHeight: 280` nos `DropdownButton` de localização e conquistadores, a propriedade `totalResultados` e o rodapé fixo com o botão `Aplicar` em `frontend/lib/widgets/painel_filtros_indice.dart` (Green), atualizando as docstrings e verificando que `flutter test test/widgets/painel_filtros_indice_test.dart --coverage` passa com 100% de cobertura

## 2. Integração da Contagem Reativa de Resultados nas Páginas de Exploração

- [x] 2.1 Escrever testes de widget falhando (Red) em `frontend/test/pages/pico_subpages/setores_page_test.dart`, `frontend/test/pages/grupo_test.dart` e `frontend/test/pages/setor_test.dart` verificando que ao abrir o modal "Filtros e Ordenação" e alterar filtros, o botão do rodapé reflete em tempo real a quantidade filtrada da aba ativa (`Aplicar (X resultados)`) e fecha o modal mantendo os filtros ativos
- [x] 2.2 Atualizar `frontend/lib/pages/pico_subpages/setores_page.dart`, `frontend/lib/pages/grupo.dart` e `frontend/lib/pages/setor.dart` para calcular e passar `totalResultados` da aba ativa ao `PainelFiltrosIndice` (Green), verificando que os testes das três páginas passam com 100% de cobertura

## 3. Verificação Integrada

- [x] 3.1 Executar `flutter analyze` e a suíte de testes dos arquivos modificados verificando zero avisos estáticos e 100% de cobertura comportamental
