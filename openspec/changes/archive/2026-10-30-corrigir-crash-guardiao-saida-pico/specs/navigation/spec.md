## MODIFIED Requirements

### Requirement: Sincronia da Árvore de Rotas Declarativa
O componente UI de pilha Declarativa (o `Navigator` nativo) DEVE (MUST) sincronizar perfeitamente as suas ramificações (pages stack) de modo determinístico espelhando o estado interno do `TreeNavigationController`. Qualquer comando de retorno disparado a partir de uma página declarativa da árvore (como o botão voltar da barra superior via `AppNav.back`) DEVE (MUST) delegar a transição ao `TreeNavigationController.goBack()` para avaliar interceptadores de saída antes de remover a página da pilha, reservando o desempilhamento imperativo (`Navigator.pop`) exclusivamente para rotas imperativas sobrepostas (como diálogos, painéis modais ou telas de busca). Adicionalmente, as chaves (Keys) de cada página gerada pelo `Navigator` DEVEM (MUST) ser estritamente únicas baseadas na representação em texto (`toString()`) dos nós. O sistema DEVE garantir que nós logicamente distintos (conforme avaliado pela igualdade na árvore de navegação) nunca produzam a mesma representação de texto, prevenindo conflitos e crashes por chaves duplicadas.

#### Scenario: Retorno gerado pelo Sistema Operacional (Hardware)
- **WHEN** o usuário aciona o recurso nativo de "voltar" de seu dispositivo (botão físico ou gesto na tela)
- **THEN** o sistema DEVE interceptar e disparar `TreeNavigationController.goBack()`
- **AND** o `Navigator` tem de obrigatoriamente refletir a remoção da tela e retroceder suavemente, reativando a camada que repousava por baixo.

#### Scenario: Retorno acionado por botão de interface em página declarativa com interceptador ativo
- **WHEN** o usuário toca no botão "Voltar" da barra superior de uma página declarativa da árvore que possui um interceptador de saída ativo
- **THEN** o sistema avalia o interceptador de saída antes de remover a página da pilha do `Navigator`
- **AND** caso o interceptador cancele o retorno imediato (exibindo um modal de confirmação), a página permanece ativa e montada na pilha declarativa.

#### Scenario: Retorno acionado em rota imperativa sobreposta
- **WHEN** há uma rota imperativa sobreposta (como diálogo, bottom sheet ou delegação de busca) aberta sobre a árvore de navegação e `AppNav.back` é invocado com o contexto dessa rota
- **THEN** o sistema desempilha apenas a rota imperativa sobreposta sem retroceder o nó atual no `TreeNavigationController`.

#### Scenario: Transição entre nós visualmente similares mas logicamente distintos
- **WHEN** o usuário navega de um nó com contexto parcial (ex: uma Via sem setor definido) para um nó atualizado do mesmo recurso com contexto completo (ex: a mesma Via, mas agora com setor resolvido via mapa)
- **THEN** a representação em texto gerada pelo novo nó DEVE ser diferente do nó anterior
- **AND** o `Navigator` DEVE ser capaz de mapear ambos os nós sem lançar uma exceção de chave duplicada (`!keyReservation.contains(key)`).
