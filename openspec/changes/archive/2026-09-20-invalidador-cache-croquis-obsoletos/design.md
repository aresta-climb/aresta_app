## Context

Atualmente, `ConstrutorCaminhoTrajeto` mantém caches estáticos em memória RAM (`_cacheCaminhos` e `_cacheCaminhosViewport`) para evitar o custo computacional de conversão de strings SVG e decomposição de traços durante operações de pan e zoom a 60/120 FPS. Esses caches são indexados por `${caminhoImagemMapa}#${pontoId}-${estilo}`. 

Ao atualizar um croqui no servidor, a sincronização atômica (`SyncService.syncIndex`) grava o novo `.binarypb` em disco e atualiza os metadados dos picos em memória, mas nunca notifica o `ConstrutorCaminhoTrajeto` nem expurga croquis da sessão online (`GerenciadorSessaoOnline`). Como resultado, o contêiner visual se reposiciona com as novas caixas delimitadoras enquanto o `CustomPaint` recupera o `Path` desatualizado da memória RAM.

Para a motivação detalhada, consulte `proposal.md`.

## Goals / Non-Goals

**Goals:**
- Centralizar o ciclo de vida e a invalidação de memória de croquis em um método coeso no `DatasetRepository`.
- Disparar a limpeza do cache de trajetos vetoriais (`ConstrutorCaminhoTrajeto.limparCache()`) ao término da sincronização atômica (`syncIndex`), garantindo que tanto o sync automático quanto o manual na Home redefinam o cache.
- Detectar e expurgar automaticamente croquis obsoletos mantidos na memória RAM de `GerenciadorSessaoOnline` quando o índice mestre indicar novo checksum SHA-256 e o pico não estiver com a visualização aberta pelo usuário.
- Limpar os caminhos vetoriais do viewport no `dispose` de `PicoPage` e no callback de atualização sob demanda do `ServicoCroquiOnline`.

**Non-Goals:**
- Não alterar a chave do cache em tempo de execução para concatenar strings completas de SVG (evitando degradação de Garbage Collector e jank em pan/zoom).
- Não interromper abruptamente a sessão do usuário se ele estiver com o pico aberto durante a sincronização (respeitando o fluxo existente de pendências atômicas via `picoAbertoId`).
- Não modificar a estrutura de arquivos no disco nem alterar contratos Protobuf.

## Decisions

### 1. Invalidador Centralizado no `DatasetRepository`
- **Decisão**: Criar o método `invalidarCroquisObsoletos({Indice? novoIndice, List<String>? picosAtualizados})` no `DatasetRepository`. Esse método limpa `ConstrutorCaminhoTrajeto.limparCache()` e itera sobre as chaves de `GerenciadorSessaoOnline.croquisEmMemoria`. Se um pico teve seu checksum alterado no `novoIndice` (ou foi atualizado em disco) e não é o `picoAbertoId` atual, remove a sessão via `gerenciadorSessaoOnline.removerSessao(picoId)`.
- **Alternativas consideradas**:
  - *Colocar a limpeza espalhada diretamente no `SyncService` e no `PicoPage`*: Rejeitada, pois espalha a responsabilidade de gestão de cache por múltiplos serviços desacoplados, violando o princípio Feature-First e facilitando esquecimentos futuros.

### 2. Acionamento do Invalidador no Fluxo Atômico de `syncIndex`
- **Decisão**: O `syncIndex` no `SyncService` invocará `datasetRepository.invalidarCroquisObsoletos` logo após efetivar a renomeação atômica de arquivos e os metadados dos picos, apenas quando houver sucesso total nas alterações.
- **Alternativas consideradas**:
  - *Chamar no `handleManualSync` da Home*: Desnecessário e redundante, pois o botão manual delega para o próprio `syncIndex(auto: false)`. Centralizar no `syncIndex` cobre tanto a sincronização manual quanto a automática em segundo plano.

### 3. Preservação da Chave de Cache Leve em `ConstrutorCaminhoTrajeto`
- **Decisão**: Manter a chave leve `${imagem}#${pontoId}` em `ConstrutorCaminhoTrajeto`, baseando a invalidação no ciclo de vida e não em chaves com conteúdo bruto de SVG.
- **Alternativas consideradas**:
  - *Usar a string inteira de SVG na chave*: Rejeitada por provocar alocações excessivas de heap e pausas de GC em animações a 60/120 FPS.
  - *Usar apenas `hashCode` sem limpeza*: Rejeitada porque trocar apenas a chave deixa os objetos antigos acumulando lixo na memória RAM indefinidamente.

## Risks / Trade-offs

- **[Risco]** Custo de recompilação de `Path` no primeiro frame após o sync.
  - **Mitigação**: O parsing de SVG e criação do `Path` leva menos de 2 milissegundos por traçado e ocorre apenas no primeiro acesso após a sincronização, sendo imediatamente armazenado no cache recém-limpo para os frames subsequentes de pan/zoom.
- **[Risco]** Usuário com croqui aberto perder a navegação se a sessão online for removida no meio da leitura.
  - **Mitigação**: O invalidador respeita `syncService.picoAbertoId`. Se o pico estiver aberto, a sessão permanece ativa e as pendências são aplicadas apenas quando o usuário navegar para fora do pico ou aceitar a recarga.
