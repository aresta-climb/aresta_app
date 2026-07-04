## 1. Testes Unitários de Navegação (TDD)

- [x] 1.1 Criar testes unitários para a função responsável por determinar o destino do botão "Subir" (validando 100% dos fluxos lógicos).
- [x] 1.2 Implementar testes para garantir que o Mapa de Grupo seja retornado caso `setorContext` pertença a um `grupoContext` que possua mapas.
- [x] 1.3 Implementar testes para garantir que o Mapa Geral seja retornado caso não haja Mapa de Grupo, mas o `Pico` tenha `mapasGerais`.
- [x] 1.4 Implementar testes garantindo que nenhum mapa destino seja retornado caso não existam mapas de nível superior.

## 2. Lógica de Navegação

- [x] 2.1 Implementar a função lógica testada na Etapa 1 que avalia `setorContext`, `grupoContext` e `Pico` e decide o mapa de destino.
- [x] 2.2 Implementar a chamada correta para `AppNav.toMapaInterativo` (inserindo um novo `MapaInterativoNode` na pilha) utilizando a lógica desenvolvida, alcançando os 100% de cobertura nos testes já escritos.
- [x] 2.3 Executar a suíte de testes de navegação e garantir 100% de passagem e cobertura nessa lógica.

## 3. Testes de Interface de Usuário (TDD Widget Tests)

- [x] 3.1 Criar Widget Tests validando a ausência do botão "Subir" em mapas sem nível superior.
- [x] 3.2 Criar Widget Tests para garantir que nomes muito grandes fiquem truncados (verificação do comportamento em telas pequenas / uso de `ConstrainedBox`).
- [x] 3.3 Criar Widget Tests validando que o clique no botão empurra a página esperada (Mapa de Grupo ou Mapa Geral) na pilha.

## 4. UI e Atualizações Visuais

- [x] 4.1 Substituir o botão "Mapa Geral" existente na `MapaInterativoPage` pelo novo botão de navegação hierárquica.
- [x] 4.2 Envolver o texto do botão com um `ConstrainedBox` definindo um `maxWidth` para evitar a obstrução do mapa, em conjunto com `TextOverflow.ellipsis`.
- [x] 4.3 Estilizar o botão utilizando um formato compacto e discreto (ex: custom button ou `ActionChip`) com um ícone apropriado para "Subir" (`^`).
- [x] 4.4 Garantir que o texto exibido no botão é gerado dinamicamente através da lógica de navegação.
- [x] 4.5 Garantir que os Widget Tests passem e que os requisitos de layout e truncamento atendam a cobertura almejada.
