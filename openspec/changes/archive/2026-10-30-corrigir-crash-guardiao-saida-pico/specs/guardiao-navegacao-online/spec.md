## MODIFIED Requirements

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
