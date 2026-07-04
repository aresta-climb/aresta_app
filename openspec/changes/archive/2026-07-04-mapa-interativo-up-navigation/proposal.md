## Why

Atualmente, o botão "Mapa Geral" dentro dos mapas interativos navega para fora da interface do mapa, abrindo a página de texto do pico (`PicoPage`). Isso quebra o contexto visual e a imersão espacial. Precisamos de uma navegação hierárquica ("Subir") que mantenha o usuário dentro da experiência do mapa interativo ao transitar entre os níveis (Setor -> Grupo -> Mapa Geral). Além disso, a implementação deve ser estritamente orientada a testes (TDD) visando 100% de cobertura de testes unitários para a nova lógica.

## What Changes

- Substituição do botão estático "Mapa Geral" na `MapaInterativoPage` por um botão dinâmico de navegação hierárquica.
- Restrição da navegação do mapa exclusivamente para outros mapas: se não houver um mapa de nível superior, o botão não é exibido.
- Lógica de navegação guiada por testes (TDD):
  - Do mapa de Setor -> mapa de Grupo (se o setor pertencer a um grupo e este tiver mapas).
  - Do mapa de Grupo (ou Setor sem grupo) -> mapa geral do Pico (se disponível).
- O texto do botão é gerado dinamicamente (ex: `⬆ Grupo Vale Oculto` ou `⬆ Mapa Geral`) para indicar claramente o destino.
- Truncamento de nomes longos e design de botão compacto para evitar obstrução da visão do mapa.
- Garantia de 100% de test coverage para as funções e condicionais que definem qual mapa deve ser aberto.

## Capabilities

### New Capabilities
- `map-hierarchy-navigation`: Define as regras de navegação hierárquica para "Subir" dentro dos mapas interativos (Setor -> Grupo -> Pico).

### Modified Capabilities
- `interactive-map`: Modifica os requisitos do botão flutuante existente para ser dinâmico e condicional com base na hierarquia, assegurado por testes unitários.

## Impact

- Interface e lógica da `MapaInterativoPage`.
- `navigation_functions.dart` (se novos métodos de navegação forem necessários para abrir Mapas de Grupo ou Mapas Gerais).
- Pilha de navegação (back stack) do Android (empurrando novos nós de mapa em vez de navegar para a página do Pico).
- Suíte de testes (`navigation_tree_test.dart`, `navigation_routing_test.dart` e testes de UI da `MapaInterativoPage`).
