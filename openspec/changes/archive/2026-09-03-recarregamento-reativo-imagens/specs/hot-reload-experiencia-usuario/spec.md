## MODIFIED Requirements

### Requirement: Componente Modular e Pulso Luminoso no Banner Experimental
O sistema MUST fornecer um widget independente e modular (BannerModoExperimental) que emita um feedback visual luminoso sutil e não-bloqueante no banner ao receber eventos push de recarregamento, suportando tanto croquis baixados no armazenamento local quanto croquis abertos em sessão online (streaming), e MUST expurgar o cache de imagens da GPU para atualizar instantaneamente as imagens atualmente exibidas na tela ativa.

#### Scenario: Recebimento de evento Live Reload para croqui baixado
- **WHEN** o aplicativo recebe uma notificação push WebSocket de recarga do editor desktop para um croqui baixado
- **THEN** o BannerModoExperimental DEVE acionar uma transição de pulso luminoso com duração de até 500ms
- **AND** o sistema DEVE expurgar o cache de imagens (`PaintingBinding.instance.imageCache.clear()` e `clearLiveImages()`)
- **AND** a tela aberta DEVE ser reconstruída com os novos dados em memória e as novas imagens renderizadas imediatamente preservando a posição de rolagem.

#### Scenario: Recebimento de evento Live Reload para croqui em sessão online
- **WHEN** o aplicativo recebe uma notificação push WebSocket de recarga e o croqui atualmente aberto na navegação está em sessão online (não baixado)
- **THEN** o sistema DEVE executar re-fetch do arquivo `.binarypb` com parâmetro de quebra de cache HTTP
- **AND** o sistema DEVE atualizar o `GerenciadorSessaoOnline` e reindexar as mídias no `DatasetRepository`
- **AND** o sistema DEVE expurgar o cache de imagens do Flutter
- **AND** o BannerModoExperimental DEVE acionar a transição de pulso luminoso
- **AND** a tela aberta DEVE ser reconstruída de forma seamless com os novos dados em memória e a nova imagem atualizada sem exigir que o usuário saia e reabra a aba.
