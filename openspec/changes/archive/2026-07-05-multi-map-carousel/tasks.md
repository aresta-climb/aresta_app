## 1. Camada de Navegação (TDD)

- [x] 1.1 Escrever testes unitários para a classe `MapasCarrosselNode` (assegurar propriedades e formatação)
- [x] 1.2 Implementar a classe `MapasCarrosselNode` no arquivo `navigation_tree.dart` e garantir que passe nos testes com 100% de cobertura
- [x] 1.3 Escrever testes unitários para `AppNav.toMapasCarrossel` validando mock de rota
- [x] 1.4 Implementar a função `AppNav.toMapasCarrossel` no arquivo `navigation_functions.dart`

## 2. Nova Página do Carrossel (TDD)

- [x] 2.1 Criar suite de testes de widget (WidgetTest) garantindo a renderização inicial da `MapasCarrosselPage` vazia/com mapas
- [x] 2.2 Criar o arquivo `mapas_carrossel.dart` e o scaffolding da página `MapasCarrosselPage` para fazer o teste inicial passar
- [x] 2.3 Escrever teste garantindo que o click na seta ">" muda o índice do state interno
- [x] 2.4 Implementar o `PageView` com `NeverScrollableScrollPhysics` e a UI flutuante superior `< 01 de 03 >`, alcançando 100% de cobertura do Widget

## 3. Integração com a Via (TDD)

- [x] 3.1 Escrever teste garantindo que `_buildTopBadges` agrupa mapas corretamente na Via (substituindo múltiplos chips por um só)
- [x] 3.2 Atualizar `via_functions.dart` para agrupar chips de múltiplos mapas e invocar `toMapasCarrossel`

## 4. Integração com Interactive Map (TDD)

- [x] 4.1 Escrever teste para o surgimento do botão "Ver nos mapas" em `_buildEscaladaCard` quando pertinente
- [x] 4.2 Atualizar `mapa_interativo.dart` para renderizar o botão extra quando as validações estiverem corretas (100% de cobertura no bloco novo)
- [x] 4.3 Ajustar o `_buildSetorCard` e `_buildGrupoCard` e escrever os testes equivalentes para o comportamento de carrossel nesses casos
