## MODIFIED Requirements

### Requirement: Componente Modular e Pulso Luminoso no Banner Experimental
O sistema MUST fornecer um widget independente e modular (BannerModoExperimental) que exiba o status "MODO EXPERIMENTAL ATIVO" sem cronômetro regressivo ou limite de tempo de sessão, operando exclusivamente via conexão remota (Cloudflare Relay, Direct LAN, URL direta ou QR Code), e emita um feedback visual luminoso sutil e não-bloqueante no banner ao receber eventos push de recarregamento em tempo real (Live Reload via WebSocket). Além disso, o aplicativo MUST tratar a sessão experimental como volátil, limpando os dados temporários e restaurando com segurança o Modo Oficial na reinicialização do aplicativo (boot).

#### Scenario: Exibição limpa do Banner Experimental sem temporizador
- **WHEN** o aplicativo entra ou está no modo experimental
- **THEN** o BannerModoExperimental DEVE ser exibido no topo da tela com o texto fixo "MODO EXPERIMENTAL ATIVO"
- **AND** o banner NÃO DEVE exibir temporizador regressivo, tempo restante ou contagem de minutos/segundos
- **AND** a sessão NÃO DEVE ser encerrada automaticamente por expiração de tempo

#### Scenario: Reinicialização do aplicativo em modo experimental (Sessão Volátil)
- **WHEN** o aplicativo é fechado e reiniciado do zero enquanto estava em modo experimental
- **THEN** o sistema DEVE executar no boot a limpeza compulsória dos dados temporários experimentais (nukeExperimentalData)
- **AND** o sistema DEVE iniciar com segurança no Modo Oficial com a base de produção

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

### Requirement: Botão de Desconexão Rápida no Banner Superior
O banner global de modo experimental MUST conter uma ação rápida de encerramento para permitir o retorno imediato à biblioteca oficial de produção e encerramento voluntário do modo experimental sem dependência de expiração temporizada.

#### Scenario: Clique no botão de sair do banner
- **WHEN** o usuário toca no botão de fechar/sair presente no banner superior de modo experimental
- **THEN** o sistema DEVE executar a limpeza dos dados experimentais (nukeExperimentalData)
- **AND** o sistema DEVE resetar a navegação para a tela inicial oficial (HomeNode)
