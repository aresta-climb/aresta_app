## MODIFIED Requirements

### Requirement: Sincronia da Árvore de Rotas Declarativa
O componente UI de pilha Declarativa (o `Navigator` nativo) DEVE (MUST) sincronizar perfeitamente as suas ramificações (pages stack) de modo determinístico espelhando o estado interno do `TreeNavigationController`. Adicionalmente, as chaves (Keys) de cada página gerada pelo `Navigator` DEVEM (MUST) ser estritamente únicas baseadas na representação em texto (`toString()`) dos nós. O sistema DEVE garantir que nós logicamente distintos (conforme avaliado pela igualdade na árvore de navegação) nunca produzam a mesma representação de texto, prevenindo conflitos e crashes por chaves duplicadas.

#### Scenario: Retorno gerado pelo Sistema Operacional (Hardware)
- **WHEN** o usuário aciona o recurso nativo de "voltar" de seu dispositivo (botão físico ou gesto na tela)
- **THEN** o sistema DEVE interceptar e disparar `TreeNavigationController.goBack()`
- **AND** o `Navigator` tem de obrigatoriamente refletir a remoção da tela e retroceder suavemente, reativando a camada que repousava por baixo.

#### Scenario: Transição entre nós visualmente similares mas logicamente distintos
- **WHEN** o usuário navega de um nó com contexto parcial (ex: uma Via sem setor definido) para um nó atualizado do mesmo recurso com contexto completo (ex: a mesma Via, mas agora com setor resolvido via mapa)
- **THEN** a representação em texto gerada pelo novo nó DEVE ser diferente do nó anterior
- **AND** o `Navigator` DEVE ser capaz de mapear ambos os nós sem lançar uma exceção de chave duplicada (`!keyReservation.contains(key)`).
