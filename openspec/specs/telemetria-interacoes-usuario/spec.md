## Purpose

Registra e monitora as principais ações de engajamento do usuário na interface do aplicativo, abrangendo o Índice de Escaladas e seus filtros contextuais, modais informativos, botões comunitários e de apoio aos picos, banners de modo online e opções de ordenação.

## Requirements

### Requirement: Telemetria do Índice de Escaladas e Filtros Contextuais
O sistema DEVE (MUST) registrar eventos analíticos em todas as interações da tela de Índice de Escaladas, identificando a modalidade de escalada na dimensão `origem` (ex: `indice_esportiva`, `indice_boulder`, `indice_movel`, `indice_multienfiada`, `indice_highline`), ações padronizadas (`filtrar_grau`, `filtrar_setor`, `filtrar_conquistador`, `filtrar_classicas`, `limpar_filtros`, `expandir_filtros`, `colapsar_filtros`, `trocar_aba`) e valores complementares na dimensão `detalhe`.

#### Scenario: Acesso ao Índice de Escaladas a partir do hub do pico
- **WHEN** o usuário toca no cartão "ÍNDICE DE ESCALADAS" na página de detalhes do pico
- **THEN** o sistema despacha evento de telemetria com `id_croqui`, `acao: 'abrir_indice_escaladas'` e `origem: 'pico_hub'` antes de navegar para a tela do índice.

#### Scenario: Alternância entre abas de modalidade no Índice
- **WHEN** o usuário toca em uma aba de modalidade diferente na barra de abas (ex: de Esportivas para Boulders)
- **THEN** o sistema despacha evento de telemetria registrando `acao: 'trocar_aba'`, `origem: 'indice_boulder'` e `detalhe: 'Boulder'`.

#### Scenario: Aplicação de filtro de grau
- **WHEN** o usuário ajusta o controle deslizante de faixa de dificuldade no painel de filtros
- **THEN** o sistema despacha evento de telemetria registrando `acao: 'filtrar_grau'`, `origem` contextualizada à modalidade ativa (ex: `indice_esportiva`) e `detalhe` contendo os limites selecionados (ex: `5º a 8ºb`).

#### Scenario: Aplicação de filtro por setor ou conquistador
- **WHEN** o usuário seleciona ou remove um filtro de setor ou conquistador no painel
- **THEN** o sistema despacha evento de telemetria com `acao: 'filtrar_setor'` ou `acao: 'filtrar_conquistador'`, `origem` da modalidade ativa e `detalhe` com o nome do elemento selecionado.

#### Scenario: Aplicação de filtro de clássicas e limpeza de filtros
- **WHEN** o usuário ativa o switch de apenas clássicas ou clica em limpar filtros da modalidade
- **THEN** o sistema despacha evento de telemetria com `acao: 'filtrar_classicas'` (com `detalhe: 'true'/'false'`) ou `acao: 'limpar_filtros'`.

#### Scenario: Toque no card de escalada no Índice
- **WHEN** o usuário clica em um card de via ou boulder na listagem do Índice de Escaladas
- **THEN** o sistema despacha evento `acao_escalada` com `acao: 'abrir_detalhes'`, `nome_escalada`, `nome_setor`, `id_croqui` e `origem: 'indice_<modalidade>'`.

### Requirement: Telemetria do Modal de Beta Aberto e Canais Oficiais
O sistema DEVE (MUST) registrar evento analítico ao abrir o modal explicativo da fase de Beta Aberto (ao tocar no logotipo ou micro-badge `BETA` da Home) e ao interagir com seus botões de ação (Instagram Oficial, Comunidade WhatsApp e Enviar Sugestão).

#### Scenario: Abertura do modal de Beta Aberto a partir da Home
- **WHEN** o usuário clica no título "ARESTA CLIMB" ou no micro-badge "BETA" na página inicial
- **THEN** o sistema exibe o modal e despacha evento de telemetria indicando a visualização da tela de Beta Aberto com `acao: 'abrir_modal_beta'` e `origem: 'home_header'`.

#### Scenario: Clique nos botões sociais dentro do modal de Beta Aberto
- **WHEN** o usuário clica no botão "Instagram Oficial" ou "Comunidade no WhatsApp" dentro do modal de Beta
- **THEN** o sistema despacha evento de telemetria com `origem: 'modal_beta'` e `acao: 'clique_instagram'` ou `acao: 'clique_whatsapp'` antes de abrir o aplicativo externo correspondente.

### Requirement: Telemetria de Apoio ao Pico e Contribuição PIX
O sistema DEVE (MUST) registrar evento de telemetria quando o usuário interagir com a chave PIX de manutenção do pico ou com as opções de suporte aos autores e guardiões do local.

#### Scenario: Cópia da chave PIX de manutenção do pico
- **WHEN** o usuário toca no card de doação via PIX na página "Apoie o Pico"
- **THEN** a chave PIX é copiada para a área de transferência e um evento de telemetria é registrado com `acao: 'copiar_pix'`, `id_croqui` e `origem: 'apoie_pico'`.

### Requirement: Telemetria de Guardião de Saída e Banner Modo Online
O sistema DEVE (MUST) registrar evento analítico ao exibir o modal de confirmação de saída do croqui online e registrar a decisão do usuário entre salvar offline ou sair sem salvar. Além disso, o toque no botão "Salvar Offline" do banner de modo online DEVE ser rastreado.

#### Scenario: Exibição e escolha no modal do guardião de saída
- **WHEN** o usuário tenta sair de um croqui em modo online não salvo e o modal do guardião é exibido
- **THEN** o sistema registra evento de telemetria na exibição e outro evento registrando `acao: 'guardiao_salvar_offline'` ou `acao: 'guardiao_sair_sem_salvar'` com `modo_acesso: 'online'`.

#### Scenario: Toque no botão salvar offline do banner de modo online
- **WHEN** o usuário clica no botão "Salvar Offline" dentro do banner de modo online na página de detalhes do pico
- **THEN** o sistema inicia o download e despacha evento de telemetria com `acao: 'banner_salvar_offline'` e `origem: 'banner_online'`.

### Requirement: Telemetria de Hub de Páginas e Ordenação
O sistema DEVE (MUST) registrar eventos de telemetria ao navegar através dos cards centrais do pico (Setores, Explorar Local, Regras e Recomendações, Comunidade) e ao alternar modos de ordenação de vias ou setores.

#### Scenario: Acesso aos cards principais do pico
- **WHEN** o usuário clica em "Setores", "Explorar Local", "Regras e recomendações" ou "Comunidade" na página de detalhes do pico
- **THEN** o sistema navega para a seção correspondente e despacha evento de telemetria identificando o pico e a seção acessada.

#### Scenario: Alternância de ordenação de vias ou setores
- **WHEN** o usuário seleciona um novo critério de ordenação na lista de vias ou setores (ex: alfabético ou por grau)
- **THEN** a lista é reordenada e o sistema despacha evento de telemetria registrando `acao: 'alterar_ordenacao'`, com o critério no parâmetro `detalhe`.

### Requirement: Telemetria de Links Externos de Comunidade e Time
O sistema DEVE (MUST) registrar evento de telemetria com a URL e canal correspondente sempre que o usuário acionar um link externo na aba Comunidade ou na tela "Sobre o Time" (WhatsApp, Instagram, LinkedIn, Discord, GitHub). Adicionalmente, o sistema DEVE validar o retorno de sucesso do mecanismo de abertura nativo e registrar falha no log de auditoria sempre que a abertura não for concluída com sucesso pelo sistema operacional.

#### Scenario: Acesso ao grupo de WhatsApp ou Discord a partir da Comunidade
- **WHEN** o usuário toca no card "Grupo do WhatsApp" ou "Discord dos Desenvolvedores" na tela de Comunidade
- **THEN** o sistema registra evento de link externo com a URL no parâmetro `detalhe` e `origem: 'comunidade'` ou `origem: 'sobre_time'` antes de abrir o link externo.

#### Scenario: Falha no lançamento de aplicativo ou navegador nativo
- **WHEN** o sistema operacional retornar `false` ou lançar exceção ao tentar abrir um link externo
- **THEN** o sistema registra imediatamente uma ocorrência no log de erros contextualizando o nome do serviço e a URL que falhou.

### Requirement: Telemetria de Navegação Interna e Termos na Comunidade
O sistema DEVE (MUST) registrar eventos analíticos ao acionar a navegação para telas institucionais e ao abrir os modais de termos de uso e privacidade a partir da aba Comunidade.

#### Scenario: Toque no card Sobre o Time na Comunidade
- **WHEN** o usuário toca no card "SOBRE O TIME" na página de Comunidade
- **THEN** o sistema despacha evento de telemetria com `acao: 'navegar_sobre_time'` e `origem: 'comunidade'` antes de transicionar a navegação.

#### Scenario: Abertura do modal de Termos de Uso e Privacidade
- **WHEN** o usuário clica no card de Termos de Uso e Privacidade
- **THEN** o sistema despacha evento de telemetria com `acao: 'abrir_termos'` e `origem: 'comunidade'`.
