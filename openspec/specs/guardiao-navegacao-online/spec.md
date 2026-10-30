## Purpose

Define os mecanismos visuais e de interceptação de saída para conscientização e proteção do escalador durante a navegação em croquis no modo online.

## Requirements

### Requirement: Banner Flutuante de Modo Online
Ao visualizar as telas de um croqui que não se encontra salvo localmente, a interface DEVE (MUST) exibir um banner/pílula visual indicando claramente o "Modo Online". O banner DEVE incluir um botão de ação primária com texto dinâmico exibindo o tamanho total (ex: "Salvar pra Pedra (18 MB)"). Ao ser acionado, o botão DEVE iniciar o download e exibir feedback de progresso, transitando para o estado "Salvo Offline" após a conclusão.

#### Scenario: Visualização do banner em croqui não baixado
- **WHEN** o usuário abre a página de detalhes de um pico em modo online
- **THEN** o banner flutuante é renderizado no topo com ícone de nuvem e botão de download com o tamanho formatado.

#### Scenario: Acionamento do download pelo banner
- **WHEN** o usuário toca no botão "Salvar pra Pedra" no banner
- **THEN** o download em background é iniciado
- **AND** o botão passa a exibir o estado de download em andamento com porcentagem.

### Requirement: Guardião de Saída (Confirmação ao Sair sem Salvar)
Ao tentar sair (voltar) das telas de um pico visualizado em modo online (seja aberto inicialmente online ou transitado para o modo online após a exclusão do guia salvo localmente), o sistema DEVE (MUST) interceptar a navegação de retorno antes de remover ou desmontar a página da pilha visual e exibir um modal de confirmação ("Guardião de Saída"). O modal DEVE alertar sobre a falta de sinal de internet na montanha e oferecer as opções de "Salvar Offline" ou "Sair sem Salvar", garantindo que a página permaneça montada enquanto o modal estiver aberto e que qualquer confirmação ou descarte do modal conclua a ação sem violar o ciclo de vida da tela.

#### Scenario: Intercepção de saída após exploração online
- **WHEN** o usuário navega por setores ou vias de um croqui online por mais de 10 segundos
- **AND** aciona o comando de voltar para a página inicial ou explorador
- **THEN** o sistema bloqueia o pop imediato e exibe o modal de confirmação do Guardião de Saída.

#### Scenario: Usuário opta por salvar no Guardião de Saída
- **WHEN** o usuário escolhe "Salvar Offline" no modal de confirmação
- **THEN** o sistema despacha o download para o serviço de background
- **AND** prossegue com a navegação de retorno.

#### Scenario: Usuário opta por sair sem salvar
- **WHEN** o usuário escolhe "Sair sem Salvar" no modal de confirmação
- **THEN** o modal é fechado e a navegação de retorno é concluída imediatamente sem iniciar downloads.

#### Scenario: Interceptação de saída pelo botão voltar da barra superior após exclusão do guia local
- **WHEN** o usuário exclui o guia offline na página de detalhes do pico (transitando a visualização para o modo online)
- **AND** aciona o botão voltar da barra superior da página
- **THEN** o sistema intercepta a saída mantendo a página de detalhes do pico montada sob o modal de confirmação
- **AND** ao tocar em "Sair sem Salvar" ou "Salvar Offline", o sistema fecha o modal e retorna à tela anterior na árvore sem lançar erro de estado desmontado.

### Requirement: Indicador de Atualização em Tempo Real (Pílula de Atualização)
Quando o polling de ETag detectar uma nova versão do `.binarypb` no servidor remoto enquanto a tela estiver aberta, a interface DEVE (MUST) exibir uma notificação visual não intrusiva (pílula flutuante ou barra superior) informando sobre as atualizações. Tocar na notificação DEVE recarregar a tela com os novos dados sem perder o contexto de navegação.

#### Scenario: Notificação de atualização durante leitura
- **WHEN** o servidor remoto emite status 200 para a verificação de ETag de um pico aberto
- **THEN** uma pílula informativa "Novas informações disponíveis • Recarregar" surge na tela
- **AND** ao ser clicada, atualiza a visualização com o novo protobuf.
