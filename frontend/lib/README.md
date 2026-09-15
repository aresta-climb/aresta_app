# Arquitetura Principal do Aplicativo Aresta Climb

Este documento descreve a estrutura e o fluxo lógico do aplicativo, com foco em como os dados são buscados, gerenciados e apresentados ao usuário. O aplicativo consiste em uma camada de **Serviços** para o gerenciamento de dados, uma camada de **Funções de Visualização** para componentes de interface/callbacks desacoplados e uma camada de **Páginas** para roteamento e layout.

## 1. Camada de Serviços (`lib/services/`)

A camada de serviços é responsável pelo gerenciamento de estado do aplicativo e da arquitetura baseada em **MVVM**. Classes geradas via **Protobuf** (`ResumoCroqui`, `Indice`, `Croqui`) atuam como nossos **Models** fortemente tipados. O `DatasetRepository` atua como a **ViewModel** principal.

### `DatasetRepository` (`dataset_repository.dart` e `dataset/`)
O gerenciador de estado central do aplicativo (Singleton), orquestrando o fluxo de dados de escalada do armazenamento local e das sessões online até as camadas reativas da interface. Foi decomposto em submódulos desacoplados de responsabilidade única:

- **`dataset/modelos/`**: Modelo de dados em memória `TopoDataset` e tipos auxiliares fortemente tipados.
- **`dataset/armazenamento/`**: `GerenciadorArmazenamento` responsável pela estrutura de diretórios em `<app_docs>/downloads/<pico_id>/` e integridade física.
- **`dataset/metadados/`**: `FormatadorMetadados` e `GerenciadorPrioridade` para ordenação, normalização e manipulação de `recent_picos.yaml`.
- **`dataset/sessao_online/`**: `GerenciadorSessaoOnline` responsável pelo gerenciamento de croquis visualizados sob demanda na RAM e cache volátil (`/temp_cache`), além de notificações de atualização de versão via ETag.

### Módulo HTTP e Conectividade (`http/`)
Diretório isolado que retém todas as responsabilidades que interagem com tráfego de rede, conexões externas, downloads em background e streaming sob demanda. A arquitetura geral do aplicativo é completamente agnóstica à internet (offline-first) fora desse módulo.

- **`SyncService` (`sync_service.dart`)**: Trabalhador em segundo plano responsável por manter o conjunto de dados local sincronizado. Trabalha de forma tipada, lendo `ResumoCroqui`. Aciona e monitora a thread secundária (`Isolate`), convertendo atualizações em eventos para barras de progresso na UI. Expõe `lastSyncWasAuto` e `quantidadeCroquisBaixadosAtualizadosNoUltimoSync` para que a UI notifique o usuário exclusivamente quando croquis locais baixados forem alterados na inicialização do app.
- **`SyncIsolate` (`sync_isolate.dart`)**: Executa as validações pesadas de integridade (SHA256) e gere o fluxo das Delta Syncs (baixando apenas arquivos que mudaram) em uma thread separada para não causar travamentos ou "lag" na UI.
- **`SyncNetwork` (`sync_network.dart`)**: Responsável pela comunicação HTTP pura, lidando com respostas (como *304 Not Modified* via ETag) e leitura do `.binarypb` mestre.
- **`SyncStorage` (`sync_storage.dart`)**: Trata a persistência atômica no disco, lidando com criação, download em arquivos intermediários (`.tmp`) e substituições seguras em caso de erro na conexão.
- **`ServicoCroquiOnline` (`servico_croqui_online.dart`)**: Baixa arquivos `.binarypb` sob demanda em milissegundos para navegação imediata sem exigir download prévio e executa polling periódico leve de ETag.
- **`ServicoDownloadSegundoPlano` (`servico_download_segundo_plano.dart`)**: Realiza downloads permanentes resilientes em segundo plano com notificações persistentes (`ongoing: true`).
- **`UpdateDownloader` (`update_downloader.dart`)**: Verificação OTA (Over-The-Air) e download de atualizações via novos `.apk`.

### `EditorDeCroqui` (`editor_croqui.dart`)
O controlador de contexto e configuração do aplicativo. Rastreia qual modo está ativo e fornece caminhos de diretório dinâmicos para os outros serviços.

- **Modos de operação**:
  - **Oficial**: Dados do servidor CDN/GitHub Pages. URL base: `https://aresta-climb.github.io/aresta_serving`.
  - **Experimental / Live Reload**: Conexão com Editor Desktop via WebSocket e Live Reload.
- **Temporizador de Auto-Destruição**: O modo experimental tem vida útil de 20 minutos. Um cronômetro regressivo é exibido em um banner global e, ao chegar em zero, executa um "Nuke" dos dados de teste.
- **Persistência**: Salva o estado em `editor_config.json` para sobreviver reinicializações parciais.

### Integração Firebase (`firebase/`)
Subdiretório responsável por isolar o SDK do Firebase do restante da aplicação. Contém serviços para inicialização centralizada, Firebase App Check (atestação de integridade para Play Integrity / App Attest), Remote Config e Telemetry (Analytics). Consulte o [`firebase/README.md`](services/firebase/README.md) para detalhes de arquitetura e testes de linter que previnem vazamento de dependências do Firebase para a UI.

---

## 2. Camada de Páginas (`lib/pages/`)

A camada de páginas é responsável pelo roteamento de nível superior, estrutura do Scaffold e montagem dos widgets.

### Navegação Principal (`main.dart`)
Inicializa os bindings do Flutter, cria instâncias do `DatasetRepository` e `SyncService`, aciona a sincronização inicial e configura o `TreeNavigationWrapper` (que monitora o `TreeNavigationController`) para renderizar condicionalmente as visualizações raiz: Início (Home), Explorar (Browse) e Configurações. As transições hierárquicas (GPS, Setores, Vias) reconstroem a interface reativamente com base no nó ativo.

### Páginas de Nível Superior
- **`home.dart`**: Exibe um carrossel dos picos de maior prioridade e uma lista suspensa de todos os picos disponíveis localmente.
- **`browse.dart`**: Lista todos os guias disponíveis no índice mestre com thumbnails dinâmicos, indicadores de download e ações de download inline.
- **`mapa_global.dart`**: O "Mapa Global", uma visão 2D no Google Maps exibindo todos os croquis disponíveis com marcadores escalonados por faixas de zoom (Macro, Regional e Local), balões compactos com truncamento automático de texto e interações de bottom sheet.
- **`comunidade.dart`**: Hub central com mídias, apoios e links interativos (WhatsApp, Instagram, Discord, GitHub).
- **`settings.dart`**: Gerenciamento do aplicativo, cache e ferramentas de editor experimental.
- **`terms_of_use.dart`**: Exibe a interface de visualização dos documentos legais do aplicativo (Termos de Uso e Privacidade).

### Páginas Hierárquicas de Guias
Representam a estrutura topológica aninhada de um guia de escalada. O estado flui para baixo passando `DatasetRepository` e `cragId` por toda a hierarquia:

- **`pico.dart`**: Nó raiz de um guia. Exibe resumo, informações logísticas e a lista de setores ou grupos.
- **`mapas_carrossel.dart`**: Navegação em formato carrossel horizontal (swiping) contendo múltiplos `mapa_interativo.dart`, oferecendo transições de mapa mais fluidas entre hierarquias e subsetores do guia de escalada.
- **`grupo.dart` / `setor.dart`**: Subárea geográfica. Adapta a nomenclatura dinamicamente ("Vias" vs "Boulders") de acordo com o tipo de conteúdo do setor.
- **`via.dart`**: Nó folha com beta, descrições e imagens croqui (topo) de alta resolução.

---

## 3. Camada de Navegação (`lib/navigation/`)

A camada de navegação gerencia o fluxo de telas do aplicativo utilizando uma arquitetura baseada em **Árvore de Nós** (Tree Navigation) em vez do tradicional Navigator em pilha (push/pop) do Flutter. Isso previne o acúmulo infinito de páginas redundantes (loops) e otimiza o consumo de memória.

### `navigation_tree.dart`
Contém as definições da estrutura lógica dos nós e o controlador central de estado da navegação.
* **`NavNode`**: Classe base abstrata. Cada nó na árvore mantém uma referência opcional para o seu pai (`parent`) e armazena **apenas identificadores em texto** (como `cragId`, `setorNome`, etc.), nunca objetos do banco de dados, para garantir a resiliência a hot-reloads de dados. Os nós implementados incluem: `HomeNode`, `BrowseNode`, `MapaGlobalNode`, `PicoNode`, `SetorNode`, `ViaNode`, `MapaInterativoNode`, entre outros.
* **`TreeNavigationController`**: Um `ChangeNotifier` que rastreia o nó ativo (`currentNode`).
  * **Prevenção de Loops**: Realiza um retrocesso (*rewind*) para o nó original em vez de empilhar uma nova página redundante se o nó já existir no histórico.
  * **Botão de Voltar / Home**: Gerencia o retorno de telas (`goBack`) e reset para a tela inicial (`goHome`).

### `page_listenable_builder.dart`
O coração do **Hot-Reload Reativo**. Atua como o elo entre a Árvore de Navegação e a UI.
* Fica escutando as mudanças no `activeDataset` do `DatasetRepository` (acionadas em background pelo `SyncService`).
* Em vez de injetar objetos engessados na inicialização da página, este Builder intercepta as transições, lê os identificadores (IDs) do `NavNode` atual e busca em tempo real os dados mais recentes do modelo `TopoDataset` para injetar nas views (`PicoView`, `SetorView`, etc.).
* É o que permite que as telas do Aresta se atualizem instantaneamente quando um croqui sofre um hot-reload pelo Editor.

### `navigation_functions.dart`
Expõe a API pública estática **`AppNav`**, que simplifica a navegação no aplicativo.
* **Métodos Principais**: `AppNav.toPico`, `AppNav.toMapaGlobal`, `AppNav.toSetor`, `AppNav.toGrupo`, `AppNav.toVia`, `AppNav.toGPS`, `AppNav.back`, `AppNav.home`, e `AppNav.canGoBack`.

---

## 4. Camada de Funções de Visualização (`lib/view_functions/`)

Para evitar arquivos de página monolíticos, todos os construtores de UI complexos, estilização e callbacks são extraídos para o diretório `view_functions/`.

- **Funções específicas** (`home_functions.dart`, `browse_functions.dart`, `setor_functions.dart`, `sobre_time_functions.dart`, etc.): Contêm funções `build...` e manipuladores de ação para suas respectivas páginas. Reduzem o tamanho dos arquivos em `pages/`. Com foco em arquitetura limpa, estruturas dinâmicas foram migradas para modelos fortemente tipados (`RotulosVia`, `MembroTime`, `ResumoPico`) e blocos aninhados foram decompostos em funções puras testáveis.
- **`mapa/` (Subdiretório)**: Organiza as funções exclusivas do mapa de visualização global, como `mapa_global_functions.dart` e o `mapa_marker.dart`, que renderiza programaticamente usando `Canvas` e `Path` o marcador personalizado (pingo) na cor vibrante da logomarca do app.
- **`common_functions.dart`**: Sistema de design genérico. Define componentes como `buildSortMenu<T>` e a renderização das barras de navegação primária (`buildPrimaryBottomNav`) e secundária. Obs: O controle mestre de cores passou para o diretório `theme/app_colors.dart`.
- **`offline_markdown.dart`**: Visualizador Markdown customizado para o mandato _offline-first_. Substitui o `imageBuilder` padrão para interceptar requisições de imagem e servir arquivos diretamente do armazenamento local via `FileImage`, sem nenhuma chamada de rede.
- **`settings_functions.dart`**: Gerencia a conexão com servidores de editor desktop (via código de prévia ou URL) e a leitura de QR codes, acionando a sincronização e Live Reload via `SyncService` e WebSocket.

---

## 5. Camada de Widgets (`lib/widgets/`)

Componentes de UI reutilizáveis e independentes que encapsulam lógica visual e comportamento específico.

- **`crag_card.dart`**: Card modular interativo para exibição de picos na grade ou listagem (usado no Explorar/Browse). Encapsula status de download, exibição de progresso granular com `LinearProgressIndicator`, contagem de setores/vias e acionamento de telemetria de visualização.
- **`linha_credito_autor.dart`**: Widget padronizado para exibição dos créditos de autores e conquistadores do croqui. Suporta quebra automática em múltiplas linhas para listas longas, mantendo o ícone `Icons.person_outline` alinhado ao topo.
- **`feedback/`**: Contém o `custom_feedback_builder.dart`, responsável por substituir e construir a interface de formulário do in-app feedback, mantendo coesão com as cores e design do aplicativo.
- **`global_search.dart`**: Componente de pesquisa agregada (Fuzzy Search) que funciona como ponte unificada para busca por Vias, Setores ou Picos.
- **`mapa_thumbnail.dart`**: Widget especializado para exibir uma prévia interativa de mapas de setores ou picos. Resolve automaticamente o caminho da imagem no armazenamento local offline e gerencia o estado de carregamento e a transição para o mapa interativo completo.
- **`banner_modo_online.dart`**: Banner informativo persistente que avisa o usuário quando o croqui está em modo online sob demanda.
- **`modal_confirmacao_saida.dart`**: Guardião de saída (`PopScope`) que alerta o usuário sobre a necessidade de salvar o croqui offline antes de sair para a montanha.
- **`provedor_imagem_aresta.dart`**: Provedor unificado com resolução em camadas (downloads permanente, cache volátil e streaming remoto CDN com query `?v=<sha256>`). Realiza auto-resolução de SHA-256 via `DatasetRepository`.
- **`imagem_arquivo_aresta.dart`**: Implementação especializada de `ImageProvider<ChaveImagemArquivoAresta>` que substitui o `FileImage` do Flutter, indexando a chave de cache nativa por caminho, escala e `checksumSha256` para invalidar texturas em disco reativamente sem piscar a UI.
- **`app_version_checker.dart`**: Widget e telas de verificação de versão mínima com alerta de obsolescência e bloqueio rígido.

---

## 6. Camada de Utilitários e Traçados Vetoriais (`lib/utils/`)

Reúne utilitários de domínio para manipulação de dados, resolução de índices e renderização vetorial.

- **`formatador_creditos.dart`**: Validação de placeholders genéricos e formatação de listas de autores/créditos em frases amigáveis (`"Croqui por ..."`).
- **`construtor_caminho_trajeto.dart`**: Barreira arquitetural exclusiva para o subsistema de desenho vetorial com `package:path_drawing/`. Converte dados compilados SVG (`M ... C ...`) em `ui.Path` nativo, aplica estilos de traçado FEMEMG (sólido, tracejado, pontilhado), mantém cache em memória por rota/estilo para garantir 60/120 FPS no `InteractiveViewer`, realiza conversão defensiva de cores hexadecimais (`ponto.cor`) e amostra polilinhas para detecção ergonômica de toques (hit-testing por menor distância euclidiana com tolerância de 16dp).
- **`croqui_map_index.dart`**: Índice de busca de mapas em árvore por identificador de pico/setor.
- **`dataset_resolver.dart`**: Resolução dinâmica de referências cruzadas entre marcadores do mapa e entidades do dataset (`Escalada`, `Setor`, `Pico`).


