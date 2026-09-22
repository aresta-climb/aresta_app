## Purpose

Registra e monitora as principais ações de engajamento do usuário na interface do aplicativo, abrangendo modais informativos, botões comunitários e de apoio aos picos, banners de modo online e opções de ordenação.

## ADDED Requirements

### Requirement: Telemetria do Modal de Beta Aberto e Canais Oficiais
O sistema DEVE (MUST) registrar evento analítico ao abrir o modal explicativo da fase de Beta Aberto (ao tocar no logotipo ou micro-badge `BETA` da Home) e ao interagir com seus botões de ação (Instagram Oficial, Comunidade WhatsApp e Enviar Sugestão).

#### Scenario: Abertura do modal de Beta Aberto a partir da Home
- **WHEN** o usuário clica no título "ARESTA CLIMB" ou no micro-badge "BETA" na página inicial
- **THEN** o sistema exibe o modal e despacha evento de telemetria indicando a visualização da tela de Beta Aberto.

#### Scenario: Clique nos botões sociais dentro do modal de Beta Aberto
- **WHEN** o usuário clica no botão "Instagram Oficial" ou "Comunidade no WhatsApp" dentro do modal de Beta
- **THEN** o sistema despacha evento de telemetria registrando o canal de destino antes de abrir o aplicativo externo correspondente.

### Requirement: Telemetria de Apoio ao Pico e Contribuição PIX
O sistema DEVE (MUST) registrar evento de telemetria quando o usuário interagir com a chave PIX de manutenção do pico ou com as opções de suporte aos autores e guardiões do local.

#### Scenario: Cópia da chave PIX de manutenção do pico
- **WHEN** o usuário toca no card de doação via PIX na página "Apoie o Pico"
- **THEN** a chave PIX é copiada para a área de transferência e um evento de telemetria é registrado com o identificador do pico.

### Requirement: Telemetria de Guardião de Saída e Banner Modo Online
O sistema DEVE (MUST) registrar evento analítico ao exibir o modal de confirmação de saída do croqui online e registrar a decisão do usuário entre salvar offline ou sair sem salvar. Além disso, o toque no botão "Salvar Offline" do banner de modo online DEVE ser rastreado.

#### Scenario: Exibição e escolha no modal do guardião de saída
- **WHEN** o usuário tenta sair de um croqui em modo online não salvo e o modal do guardião é exibido
- **THEN** o sistema registra evento de telemetria na exibição e outro evento registrando se o usuário escolheu "salvar_offline" ou "sair_sem_salvar".

#### Scenario: Toque no botão salvar offline do banner de modo online
- **WHEN** o usuário clica no botão "Salvar Offline" dentro do banner de modo online na página de detalhes do pico
- **THEN** o sistema inicia o download e despacha evento de telemetria registrando o início do salvamento a partir do banner.

### Requirement: Telemetria de Hub de Páginas e Ordenação
O sistema DEVE (MUST) registrar eventos de telemetria ao navegar através dos cards centrais do pico (Setores, Explorar Local, Regras e Recomendações, Comunidade) e ao alternar modos de ordenação de vias ou setores.

#### Scenario: Acesso aos cards principais do pico
- **WHEN** o usuário clica em "Setores", "Explorar Local", "Regras e recomendações" ou "Comunidade" na página de detalhes do pico
- **THEN** o sistema navega para a seção correspondente e despacha evento de telemetria identificando o pico e a seção acessada.

#### Scenario: Alternância de ordenação de vias ou setores
- **WHEN** o usuário seleciona um novo critério de ordenação na lista de vias ou setores (ex: alfabético ou por grau)
- **THEN** a lista é reordenada e o sistema despacha evento de telemetria registrando o critério selecionado.

### Requirement: Telemetria de Links Externos de Comunidade e Time
O sistema DEVE (MUST) registrar evento de telemetria com a URL e canal correspondente sempre que o usuário acionar um link externo na aba Comunidade ou na tela "Sobre o Time" (WhatsApp, Instagram, LinkedIn, Discord, GitHub).

#### Scenario: Acesso ao grupo de WhatsApp ou Discord a partir da Comunidade
- **WHEN** o usuário toca no card "Grupo do WhatsApp" ou "Discord dos Desenvolvedores" na tela de Comunidade
- **THEN** o sistema registra evento de link externo com a URL e origem correspondentes antes de abrir o link no navegador ou app nativo.
