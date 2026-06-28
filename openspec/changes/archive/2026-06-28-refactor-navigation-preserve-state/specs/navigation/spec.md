## ADDED Requirements

### Requirement: Preservação de Estado da Navegação
O sistema DEVE (MUST) preservar o estado interno (incluindo as posições de rolagem da tela, campos de texto digitados, e os estados de painéis ou sanfonas das páginas) em toda a sua hierarquia visual, restaurando-os intactos quando o usuário navegar de volta para eles.

#### Scenario: Navegando de volta para uma página rolável
- **WHEN** o usuário navega de uma página principal passível de scroll (ex. PicoPage) em direção a uma subpágina mais profunda (ex. SetorPage)
- **AND** o usuário clica no botão "voltar"
- **THEN** o sistema exibe imediatamente a página do Pico exatamente na mesma posição de rolagem (offset) deixada anteriormente.

### Requirement: Sincronia da Árvore de Rotas Declarativa
O componente UI de pilha Declarativa (o `Navigator` nativo) DEVE (MUST) sincronizar perfeitamente as suas ramificações (pages stack) de modo determinístico espelhando o estado interno do `TreeNavigationController`.

#### Scenario: Retorno gerado pelo Sistema Operacional (Hardware)
- **WHEN** o usuário aciona o recurso nativo de "voltar" de seu dispositivo (botão físico ou gesto na tela)
- **THEN** o sistema DEVE interceptar e disparar `TreeNavigationController.goBack()`
- **AND** o `Navigator` tem de obrigatoriamente refletir a remoção da tela e retroceder suavemente, reativando a camada que repousava por baixo.
