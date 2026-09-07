## ADDED Requirements

### Requirement: Definição Global de Estilos Base para Botões e Menus
O `ThemeData` da aplicação SHALL definir temas explícitos para botões com ícones e menus, garantindo que `ButtonStyle.merge` opere sobre instâncias válidas.

#### Scenario: Interação e mesclagem de estilo de IconButton
- **WHEN** um `IconButton` sofrer alterações dinâmicas de tema ou estado (pressed, hover, disabled)
- **THEN** o estilo resultante DEVE resolver a mesclagem com o tema base sem lançar `Null check operator used on a null value`.

#### Scenario: Abertura e renderização de MenuAnchor e PopupMenuButton
- **WHEN** um menu suspenso for aberto em qualquer modo de tema (Light ou Dark)
- **THEN** o estilo do botão e dos itens DEVE mesclar com os valores padrão de `menuButtonTheme` e `popupMenuTheme` sem exceções de nulidade.
