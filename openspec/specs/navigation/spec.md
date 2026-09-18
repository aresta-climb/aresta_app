## Purpose

Define as regras fundamentais de navegação, sincronização da árvore declarativa e preservação de estado da interface do Aresta Climb.

## Requirements

### Requirement: Preservação de Estado da Navegação
O sistema DEVE (MUST) preservar o estado interno (incluindo as posições de rolagem da tela, campos de texto digitados, e os estados de painéis ou sanfonas das páginas) em toda a sua hierarquia visual, restaurando-os intactos quando o usuário navegar de volta para eles.

#### Scenario: Navegando de volta para uma página rolável
- **WHEN** o usuário navega de uma página principal passível de scroll (ex. PicoPage) em direção a uma subpágina mais profunda (ex. SetorPage)
- **AND** o usuário clica no botão "voltar"
- **THEN** o sistema exibe imediatamente a página do Pico exatamente na mesma posição de rolagem (offset) deixada anteriormente.

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


### Requirement: Navegação Direta para Croquis Não Baixados
O sistema DEVE (MUST) permitir que a seleção de qualquer pico listado nas telas de Explorar (`browse.dart`), Home (`home.dart`) e Mapa Global (`mapa_global.dart`) transicione diretamente para a rota `PicoContextNode` (`PicoDetailsPage`), independentemente de o pico estar previamente baixado ou não no dispositivo.

#### Scenario: Seleção de pico não baixado na grade de croquis
- **WHEN** o usuário toca no card de um pico que possui `isDownloaded == false`
- **THEN** o sistema despacha a navegação para `AppNav.toPico`
- **AND** renderiza a página de detalhes em modo online sem exibir modais de bloqueio de download.

#### Scenario: Seleção de marcador de pico não baixado no Mapa Global
- **WHEN** o usuário seleciona um pico no Mapa Global e toca para abrir seus detalhes
- **THEN** a tela de detalhes do pico é aberta imediatamente consumindo os dados da sessão online.

### Requirement: Contexto de Modo Online na Árvore de Navegação
Os nós de navegação contextualizados a um pico (`PicoContextNode` e seus descendentes `SetorNode`, `ViaNode`, `MapaInterativoNode`) DEVEM (MUST) propagar e manter acessível o estado indicativo de que o pico está sendo visualizado em sessão online, permitindo que as subpáginas renderizem os controles e proteções de modo online.

#### Scenario: Navegação de subpágina dentro de um croqui online
- **WHEN** o usuário navega da página do Pico para um Setor ou Via de um croqui online
- **THEN** a subpágina herda o contexto online
- **AND** mantém o banner e os comportamentos de proteção ativos.

### Requirement: Reconstrução de Linhagem Ascendente em Deep Links
O sistema DEVE (MUST) garantir que qualquer navegação disparada a partir de deep link externo monte a linhagem declarativa completa de ancestrais na árvore de nós (`NavNode`), de modo que o botão voltar ou o gesto de retorno do sistema transicione retroativamente pelos nós pais (`ViaNode -> SetorNode -> PicoNode -> HomeNode`) em vez de fechar o aplicativo ou desorientar o usuário.

#### Scenario: Retorno a partir de uma via aberta por deep link
- **WHEN** o usuário abre uma Via via deep link e aciona o comando voltar
- **THEN** a árvore de navegação retrocede para o Setor pai daquela via
- **AND** um acionamento subsequente retrocede para a página do Pico correspondente, até atingir a raiz (Home).

#### Scenario: Retorno a partir de um setor dentro de grupo aberto por deep link
- **WHEN** o usuário abre um Setor filho de um Grupo via deep link e aciona o comando voltar
- **THEN** a árvore de navegação retrocede para a visualização do Grupo pai
- **AND** o retorno subsequente alcança o Pico pai.
