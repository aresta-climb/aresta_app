## Purpose

Permite que escaladores abram diretamente setores, grupos, vias ou picos específicos no aplicativo Aresta Climb através de QR Codes e URLs padronizadas no domínio app.arestaclimb.com, com suporte offline e online.

## Requirements

### Requirement: Interceptação e Normalização de Deep Links
O sistema DEVE (MUST) interceptar e normalizar URLs recebidas do domínio `app.arestaclimb.com` tanto na inicialização a frio (*Cold Start*) quanto com o aplicativo já em execução em segundo plano (*Warm Start*).

#### Scenario: Abertura a frio a partir de um deep link externo
- **WHEN** o usuário toca em um link `https://app.arestaclimb.com/br_mg_igarape_pedra_grande/grupo_estacionamento` com o aplicativo totalmente fechado
- **THEN** o aplicativo inicializa e despacha a rota correspondente sem perder os parâmetros da URL.

#### Scenario: Abertura em segundo plano a partir de link externo
- **WHEN** o usuário clica em um link do domínio `app.arestaclimb.com` enquanto o aplicativo já está rodando em segundo plano
- **THEN** o aplicativo vem para o primeiro plano e transiciona suavemente para o recurso identificado.

### Requirement: Resolução Hierárquica de Slugs
O sistema DEVE (MUST) decompor o caminho da URL em até 4 níveis de profundidade (`/:pico`, `/:pico/:setor_ou_grupo`, `/:pico/:setor_ou_grupo/:sub_elemento`, `/:pico/:grupo/:setor/:via`) e localizar o elemento correspondente no croqui comparando versões normalizadas (*slugs*) dos nomes.

#### Scenario: URL apontando diretamente para um Pico
- **WHEN** o sistema recebe `https://app.arestaclimb.com/br_mg_igarape_pedra_grande`
- **THEN** o sistema resolve o croqui de Pedra Grande e navega para a página do Pico.

#### Scenario: URL apontando para um Grupo de setores
- **WHEN** o sistema recebe `https://app.arestaclimb.com/br_mg_igarape_pedra_grande/grupo_estacionamento` e o identificador corresponde a um Grupo
- **THEN** o sistema abre a página correspondente àquele Grupo.

#### Scenario: URL apontando para um Setor direto
- **WHEN** o sistema recebe `https://app.arestaclimb.com/br_mg_igarape_pedra_grande/savassinha` e o elemento é um Setor direto do Pico
- **THEN** o sistema abre a página de detalhes daquele Setor.

#### Scenario: URL apontando para um Setor dentro de um Grupo
- **WHEN** o sistema recebe `https://app.arestaclimb.com/br_mg_igarape_pedra_grande/grupo_estacionamento/savassinha`
- **THEN** o sistema resolve o Grupo pai e o Setor filho, abrindo a página do Setor contextualizada ao Grupo.

#### Scenario: URL apontando para uma Via dentro de Setor em Grupo
- **WHEN** o sistema recebe `https://app.arestaclimb.com/br_mg_igarape_pedra_grande/grupo_estacionamento/savassinha/teto_da_aresta`
- **THEN** o sistema resolve a Via "Teto da Aresta" e navega para os seus detalhes preservando todo o contexto pai.

### Requirement: Carregamento Resiliente Online e Offline
O sistema DEVE (MUST) verificar a disponibilidade local do croqui referenciado no deep link. Se o croqui já estiver baixado no dispositivo, o elemento DEVE ser aberto imediatamente sem exigir conexão com a internet. Se o croqui não estiver baixado e houver conexão com a internet, o sistema DEVE carregar o croqui através da sessão online e exibir o elemento. Se não houver internet nem croqui baixado, o sistema DEVE apresentar uma notificação amigável e instrutiva.

#### Scenario: Acesso com croqui já baixado em ambiente offline
- **WHEN** o usuário escaneia um QR Code de setor na rocha sem sinal de operadora, mas o pico já está no cache local do dispositivo
- **THEN** o aplicativo abre o setor instantaneamente sem exibir erros de rede.

#### Scenario: Acesso com croqui não baixado em ambiente online
- **WHEN** o usuário clica em um link de setor de um pico que ainda não baixou, mas possui conexão ativa com a internet
- **THEN** o sistema carrega o croqui sob demanda via sessão online e renderiza a tela do setor.

#### Scenario: Acesso com croqui não baixado em ambiente offline
- **WHEN** o usuário clica em um link de setor de um pico não baixado e o dispositivo está sem conexão à internet
- **THEN** o sistema exibe uma mensagem informando que o croqui precisa ser baixado previamente quando houver sinal de rede, sem crashar a interface.

### Requirement: Abertura via Câmera Nativa do Celular (App Links / Deep Links)
O sistema DEVE (MUST) permitir que placas com QR Codes sejam lidas diretamente pelo aplicativo nativo de câmera do dispositivo (iOS e Android), abrindo diretamente o aplicativo Aresta Climb no setor ou via desejado sem necessidade de botão de leitor interno.

#### Scenario: Escaneamento de placa física via câmera do celular
- **WHEN** o usuário aponta a câmera nativa do celular para a placa física com o QR Code
- **THEN** o sistema operacional oferece a abertura no aplicativo Aresta Climb, que navega diretamente para o setor ou via identificado.
