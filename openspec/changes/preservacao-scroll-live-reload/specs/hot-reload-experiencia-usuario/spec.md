## MODIFIED Requirements

### Requirement: Componente Modular e Pulso Luminoso no Banner Experimental
O sistema MUST fornecer um widget independente e modular (BannerModoExperimental) que emita um feedback visual luminoso sutil e não-bloqueante no banner ao receber eventos push de recarregamento, suportando tanto croquis baixados no armazenamento local quanto croquis abertos em sessão online (streaming), e MUST invalidar o cache de imagens sem descartar bruscamente texturas ativas da GPU, atualizando instantaneamente as imagens atualmente exibidas na tela ativa.

#### Scenario: Recebimento de evento Live Reload para croqui baixado
- **WHEN** o aplicativo recebe uma notificação push WebSocket de recarga do editor desktop para um croqui baixado
- **THEN** o BannerModoExperimental DEVE acionar uma transição de pulso luminoso com duração de até 500ms
- **AND** o sistema DEVE expurgar imagens inativas do cache (`PaintingBinding.instance.imageCache.clear()`) preservando imagens ativas em tela sem invocar `clearLiveImages()`
- **AND** a tela aberta DEVE ser reconstruída com os novos dados em memória e as novas imagens renderizadas imediatamente preservando a posição de rolagem.

#### Scenario: Recebimento de evento Live Reload para croqui em sessão online
- **WHEN** o aplicativo recebe uma notificação push WebSocket de recarga e o croqui atualmente aberto na navegação está em sessão online (não baixado)
- **THEN** o sistema DEVE executar re-fetch do arquivo `.binarypb` com parâmetro de quebra de cache HTTP
- **AND** o sistema DEVE atualizar o `GerenciadorSessaoOnline` e reindexar as mídias no `DatasetRepository`
- **AND** o sistema DEVE expurgar imagens inativas do cache de imagens do Flutter
- **AND** o BannerModoExperimental DEVE acionar a transição de pulso luminoso
- **AND** a tela aberta DEVE ser reconstruída de forma suave e contínua com os novos dados em memória e a nova imagem atualizada sem exigir que o usuário saia e reabra a aba e sem resetar a rolagem.

## ADDED Requirements

### Requirement: Preservação Estrita de Rolagem e Retenção de Nós Ativos em Live Reload
O sistema MUST manter montada a árvore de visualização de croquis e reter a posição de rolagem (`scroll offset`) exata durante o processamento e aplicação de qualquer evento de Live Reload.

#### Scenario: Atualização de textos e dados sem reset de rolagem
- **WHEN** o usuário está navegando em uma página de croqui (`PicoDetailsPage`, `GrupoPage`, `SetorPage` ou `ViaPage`) com a tela rolada em um deslocamento diferente de zero
- **AND** um evento de Live Reload com atualização de textos, graus ou informações for recebido e processado
- **THEN** o `PageListenableBuilder` DEVE reter o último estado válido dos nós sem desmontar a página para `const Scaffold()` durante a atualização intermediária do dataset
- **AND** a página DEVE aplicar as modificações localmente via `didUpdateWidget` mantendo o deslocamento de rolagem anterior inalterado
- **AND** o `CustomScrollView` ou `SingleChildScrollView` associado DEVE possuir uma `PageStorageKey` determinística atrelada ao identificador do pico e da entidade.

### Requirement: Diagnóstico e Depuração de Arquivos Atualizados em Sincronização
O sistema MUST emitir mensagens de log de depuração explícitas no console durante o processamento de atualizações em `syncIndex`, indicando nominalmente os arquivos adicionados, modificados ou excluídos.

#### Scenario: Execução de sincronização com alterações em disco
- **WHEN** uma sincronização via `syncIndex` detecta atualizações em arquivos locais
- **THEN** o sistema DEVE registrar via log de depuração a lista de caminhos dos arquivos atualizados/renomeados
- **AND** o sistema DEVE registrar via log de depuração a lista de caminhos dos arquivos excluídos caso existam remoções.
