## Purpose

Permite que escaladores abram diretamente setores, grupos, vias ou picos específicos no aplicativo Aresta Climb através de QR Codes e URLs padronizadas no domínio app.arestaclimb.com, com suporte offline e online.

## Requirements

### Requirement: Interceptação e Normalização de Deep Links
O sistema DEVE (MUST) interceptar e normalizar URLs recebidas do domínio canônico `aresta.cc` (e as 8 URLs de placas físicas legadas em `app.arestaclimb.com`) tanto na inicialização a frio (*Cold Start*) quanto com o aplicativo já em execução em segundo plano (*Warm Start*), blindando o `MaterialApp` raiz (`didPushRouteInformation` e `onGenerateInitialRoutes`) para que notificações de rota do canal nativo do Flutter nunca disparem `FlutterError` em `_onUnknownRoute`.

#### Scenario: Abertura a frio a partir de um deep link externo
- **WHEN** o usuário toca em um link `https://aresta.cc/s/hv7YWgTBQGyWOX` com o aplicativo totalmente fechado
- **THEN** o aplicativo inicializa a rota raiz `'/'` sem erros no `MaterialApp` e despacha a rota por UID via `GerenciadorDeepLinks` preservando a origem de compartilhamento e eventuais parâmetros UTM.

#### Scenario: Abertura em segundo plano a partir de link externo
- **WHEN** o usuário clica em um link do domínio `aresta.cc` enquanto o aplicativo já está rodando em segundo plano
- **THEN** o `MyApp` intercepta eventuais notificações de rota do canal nativo sem acionar `_onUnknownRoute`, o aplicativo vem para o primeiro plano e transiciona suavemente para o recurso identificado pelo UID.

### Requirement: Suporte aos Prefixos Compactos de `aresta.cc` (QR Code Version 3-H) e Modo Mapa
O analisador de rotas (`DeepLinkRouteParser`) e o serviço de navegação (`DeepLinkNavigatorService`) DEVEM (MUST) suportar as rotas compactas de até 35 caracteres no domínio `aresta.cc`:
- `https://aresta.cc/<uid>`: origem padrão (`null`/indefinida, ou extraída de `utm_*`), `abrirMapa: false`
- `https://aresta.cc/m/<uid>`: origem padrão, `abrirMapa: true`
- `https://aresta.cc/s/<uid>`: `origemLink: 'compartilhamento'`, `abrirMapa: false`
- `https://aresta.cc/sm/<uid>` e `https://aresta.cc/ms/<uid>`: `origemLink: 'compartilhamento'`, `abrirMapa: true`
- `https://aresta.cc/q/<uid>`: `origemLink: 'qrcode'`, `abrirMapa: false`
- `https://aresta.cc/qm/<uid>` e `https://aresta.cc/mq/<uid>`: `origemLink: 'qrcode'`, `abrirMapa: true`

Quando `abrirMapa` for `true`, o sistema DEVE abrir diretamente o Mapa Interativo (`MapasCarrosselNode`) correspondente à entidade (croqui, grupo, setor ou escalada) tendo a página principal da entidade como nó pai na árvore de navegação, ou fazer fallback para a página principal da entidade caso não exista mapa associado.

#### Scenario: Abertura de link curto com prefixo de QR Code e Mapa (`/qm/<uid>`)
- **WHEN** o usuário abre `https://aresta.cc/qm/x8siJek3FiG3aB` correspondente a uma via ou setor que possui mapa
- **THEN** o aplicativo identifica `uid: "x8siJek3FiG3aB"`, `origemLink: "qrcode"` e `abrirMapa: true`, e navega diretamente para o `MapasCarrosselNode` focado na entidade (com a página da via/setor como ancestral imediato no botão Voltar).

#### Scenario: Fallback gracioso de `/m/<uid>` quando a entidade não possui mapa
- **WHEN** o usuário abre `https://aresta.cc/sm/<uid>` para uma entidade que não possui mapa próprio nem referências visuais em mapas
- **THEN** o aplicativo abre a página principal de detalhes da entidade sem falhar.

### Requirement: Mapeamento Estático das 8 Placas Físicas Legadas
O sistema DEVE (MUST) mapear estaticamente as 8 URLs legadas de placas físicas instaladas em campo (`app.arestaclimb.com/br_mg_igarape_pedra_grande/...`, ignorando query parameters durante a chave de busca) para seus respectivos UIDs canônicos:
- `br_mg_igarape_pedra_grande/bloco_democracia` $\rightarrow$ `sQ7YgEG6ONsPXt`
- `br_mg_igarape_pedra_grande/bloco_viva_o_climb` $\rightarrow$ `xNOT4evG3tUx7A`
- `br_mg_igarape_pedra_grande/grupo_sherpa` $\rightarrow$ `cqT5nqQ4pvPub7`
- `br_mg_igarape_pedra_grande/setor_estacionamento` $\rightarrow$ `hv7YWgTBQGyWOX`
- `br_mg_igarape_pedra_grande/setor_familia_i` $\rightarrow$ `ZTPu3KeCXIJisV`
- `br_mg_igarape_pedra_grande/setor_familia_ii` $\rightarrow$ `4GJDAcwWEJb4Ca`
- `br_mg_igarape_pedra_grande/bloco_fugitivos_i` $\rightarrow$ `7TPrkAyBIkfebu`
- `br_mg_igarape_pedra_grande/bloco_fugitivos_ii` $\rightarrow$ `jPzv6byW0dO0Gj`

Qualquer outra rota hierárquica arbitrária por slug deixa de ser suportada e retorna `null` no parser.

#### Scenario: Escaneamento de uma das 8 placas físicas legadas com parâmetros UTM
- **WHEN** o sistema recebe `https://app.arestaclimb.com/br_mg_igarape_pedra_grande/bloco_democracia?utm_source=setor_igarameca&utm_medium=qrcode`
- **THEN** o parser converte a rota diretamente para `uid: "sQ7YgEG6ONsPXt"` preservando `utm_source` e `utm_medium` nos parâmetros da rota.

### Requirement: Carregamento Resiliente Online e Offline
O sistema DEVE (MUST) resolver qualquer `uid` (de croqui, grupo, setor ou escalada) consultando primeiramente os croquis em memória/baixados (`/downloads`), o cache volátil (`/temp_cache`) e o banco SQLite local `catalogo.db` (`RepositorioCatalogo`) para identificar o `id_slug` do croqui hospedeiro. Se o croqui já estiver baixado em `/downloads` ou presente no cache volátil `/temp_cache` do dispositivo, o elemento DEVE ser aberto imediatamente sem aguardar requisições de rede, disparando a sincronização do índice em segundo plano. Caso o `uid` não seja encontrado no `catalogo.db` local ou o croqui não esteja em `/downloads` nem em `/temp_cache`, o sistema DEVE sincronizar rapidamente o índice e o catálogo (`syncIndex`) antes de carregar o croqui na sessão online e exibir o elemento. Se não houver internet nem croqui disponível localmente, o sistema DEVE apresentar uma notificação amigável e instrutiva.

#### Scenario: Acesso com croqui já baixado em ambiente offline
- **WHEN** o usuário escaneia um QR Code `https://aresta.cc/q/<uid>` na rocha sem sinal de operadora, mas o pico já está salvo em `/downloads` ou no cache volátil `/temp_cache` do dispositivo
- **THEN** o aplicativo abre o setor ou via instantaneamente sem exibir erros de rede e dispara a sincronização em segundo plano

#### Scenario: Acesso a via ou croqui recém-publicado ausente no catálogo local
- **WHEN** o usuário clica em `https://aresta.cc/s/<uid>` de uma entidade publicada recentemente que ainda não consta no `catalogo.db` local e há conexão ativa com a internet
- **THEN** o sistema executa a sincronização do índice e do delta do `catalogo.db`, localiza o `uid` na segunda tentativa, baixa o `.binarypb` do croqui e abre a tela correspondente

#### Scenario: Acesso com croqui não baixado em ambiente online
- **WHEN** o usuário clica em `https://aresta.cc/s/<uid>` de uma via ou setor pertencente a um croqui que ainda não está em `/downloads` nem em `/temp_cache`, mas possui conexão ativa com a internet
- **THEN** o sistema sincroniza o `indice.binarypb` e o `catalogo.db`, carrega o `.binarypb` atualizado do croqui na sessão online e renderiza a tela correspondente

#### Scenario: Acesso com croqui não baixado em ambiente offline
- **WHEN** o usuário clica em um link `https://aresta.cc/<uid>` de um pico não disponível em `/downloads` nem em `/temp_cache` e o dispositivo está sem conexão à internet
- **THEN** o sistema exibe uma mensagem informando que o croqui precisa ser baixado previamente quando houver sinal de rede, sem crashar a interface

### Requirement: Transição Direta no Cold Start Sem Pulo Pela Tela Inicial
Quando o aplicativo for iniciado a frio (*Cold Start*) a partir de um deep link válido, o sistema DEVE (MUST) resolver o nó de destino antes de exibir a árvore de navegação principal, abrindo diretamente na tela da entidade (via, setor, grupo, pico ou mapa) com a tela inicial na base da pilha de retorno, sem exibir ou piscar a Home intermediariamente.

#### Scenario: Abertura direta em via a partir de Cold Start
- **WHEN** o aplicativo é iniciado a frio por um link válido de via (`https://aresta.cc/s/<uid>`)
- **THEN** a transição sai da splash screen diretamente para a tela de detalhes da via, mantendo a hieriaquia pai (`Setor` -> `Pico` -> `Home`) na pilha para navegação de retorno

### Requirement: Abertura via Câmera Nativa do Celular (App Links / Deep Links)
O sistema DEVE (MUST) permitir que placas com QR Codes sejam lidas diretamente pelo aplicativo nativo de câmera do dispositivo (iOS e Android), abrindo diretamente o aplicativo Aresta Climb no setor ou via desejado sem necessidade de botão de leitor interno.

#### Scenario: Escaneamento de placa física via câmera do celular
- **WHEN** o usuário aponta a câmera nativa do celular para a placa física com o QR Code
- **THEN** o sistema operacional oferece a abertura no aplicativo Aresta Climb, que navega diretamente para o setor ou via identificado.

### Requirement: Captura de Parâmetros UTM e Metadados de Deep Links
O sistema DEVE (MUST) extrair e preservar tanto a origem codificada nos prefixos de caminho (`/s/`, `/sm/`, `/ms/`, `/q/`, `/qm/`, `/mq/`) quanto os parâmetros de consulta (`utm_source`, `utm_medium`, `utm_campaign`, `utm_term`, `utm_content`) das URLs de deep links recebidas.

#### Scenario: Deep link contendo parâmetros UTM de campanha
- **WHEN** o sistema intercepta uma URL como `https://aresta.cc/q/hv7YWgTBQGyWOX?utm_source=placa_pedra&utm_medium=qrcode`
- **THEN** o sistema analisa a rota preservando `origemLink: 'qrcode'`, `utm_source` e `utm_medium` associados à resolução da rota.

#### Scenario: Deep link sem parâmetros de consulta
- **WHEN** o sistema intercepta uma URL simples como `https://aresta.cc/hv7YWgTBQGyWOX`
- **THEN** o sistema normaliza a rota com mapa de parâmetros vazio sem falhar ou abortar a navegação.

### Requirement: Telemetria de Abertura via Deep Link e QR Code
O sistema DEVE (MUST) registrar um evento estruturado de telemetria (`deep_link_aberto`) sempre que um deep link for interceptado e processado pelo aplicativo, identificando o tipo de inicialização (Cold Start vs Warm Start), o destino alcançado (`pico`, `grupo`, `setor`, `via`), se abriu direto no mapa (`abrir_mapa`), a origem do link (`qrcode`, `compartilhamento` ou parâmetros UTM) e o resultado do carregamento (`sucesso: true/false`).

#### Scenario: Registro bem-sucedido de abertura de via via QR code físico
- **WHEN** o usuário escaneia um QR code físico (`https://aresta.cc/qm/<uid>` ou `https://aresta.cc/q/<uid>`) na rocha que abre uma via com o aplicativo previamente fechado (Cold Start)
- **THEN** o sistema despacha evento de telemetria contendo `tipo_start: cold_start`, `destino: via`, `sucesso: true`, `origem_link: qrcode` e eventuais parâmetros `utm_source` e `utm_medium`.

#### Scenario: Registro de falha no carregamento de deep link sem internet
- **WHEN** um link externo é acionado para um pico não baixado previamente e o dispositivo está sem conexão com a internet
- **THEN** o sistema despacha evento de telemetria registrando `sucesso: false` e o motivo do erro antes de notificar o usuário na interface.

