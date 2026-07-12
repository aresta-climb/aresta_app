## 1. Testes Automatizados (TDD)

- [x] 1.1 Escrever teste em `mapa_interativo_test.dart` para garantir que, quando `popOnActionIfOriginal` for `true` (padrão) e `isOriginal` for verificado, a navegação faça um `pop`.
- [x] 1.2 Escrever teste em `mapa_interativo_test.dart` para garantir que, quando `popOnActionIfOriginal` for `false` e `isOriginal` for satisfeito, a navegação faça um `push` (ex: invocando `AppNav.toVia` em vez de fechar a tela).
- [x] 1.3 Escrever teste em `mapas_carrossel_test.dart` para verificar que `_defaultMapBuilder` repassa `popOnActionIfOriginal: false` ao instanciar o `MapaInterativoPage`.
- [x] 1.4 Garantir que todos os cenários de teste escritos alcancem 100% de coverage nas linhas modificadas e cubram casos de borda.

## 2. Refatoração do MapaInterativoPage

- [x] 2.1 Adicionar a propriedade `final bool popOnActionIfOriginal;` ao construtor de `MapaInterativoPage` em `frontend/lib/pages/mapa_interativo.dart`, com valor padrão `true`. Incluir docstrings detalhadas (`///`) explicando a motivação desse parâmetro.
- [x] 2.2 Atualizar o callback `onAction` de `_buildEscaladaCard` para avaliar `isOriginal` combinando com `widget.popOnActionIfOriginal`. Adicionar comentários em linha justificando a lógica para evitar que o carrossel feche indevidamente.

## 3. Ajuste do MapasCarrosselPage

- [x] 3.1 Atualizar o método `_defaultMapBuilder` em `frontend/lib/pages/mapas_carrossel.dart` para passar explicitamente `popOnActionIfOriginal: false`. Adicionar docstrings e comentários explicando que isso previne o "piscar" e a necessidade de dois cliques.

## 4. Revisão Final de Qualidade

- [x] 4.1 Executar os testes unitários (`flutter test --coverage`) e confirmar 100% de cobertura nos arquivos `mapa_interativo.dart` e `mapas_carrossel.dart`.
- [x] 4.2 Revisar todas as alterações de código (docstrings) para garantir clareza nas intenções de navegação do AppNav.
