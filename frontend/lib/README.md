# Arquitetura Principal do Aplicativo Aresta Climb

Este documento descreve a estrutura e o fluxo lógico do aplicativo, com foco em como os dados são buscados, gerenciados e apresentados ao usuário. O aplicativo consiste em uma camada de **Serviços** para o gerenciamento de dados, uma camada de **Funções de Visualização** para componentes de interface/callbacks desacoplados e uma camada de **Páginas** para roteamento e layout.

## 1. Camada de Serviços (`lib/services/`)

A camada de serviços é responsável pelo gerenciamento de estado do aplicativo e da arquitetura baseada em **MVVM**. Classes geradas via **Protobuf** (`ResumoCroqui`, `Indice`, `Croqui`) atuam como nossos **Models** fortemente tipados. O `DatasetRepository` atua como a **ViewModel** principal.

### `DatasetRepository` (`dataset_repository.dart`)
O gerenciador de estado central do aplicativo (Singleton), orquestrando o fluxo de dados de escalada do armazenamento local até as camadas reativas da interface. Expõe `ValueNotifier`s reativos (`activeDataset`, `syncStatus`, `downloadingCrags`) que a árvore de widgets escuta para atualizações instantâneas.

- **Gerenciamento de Armazenamento Local**: Cria diretórios dedicados para cada pico baixado em `<app_docs>/downloads/<pico_id>/`, evitando colisões de nomes e tornando atualizações e exclusões eficientes.
- **Tipagem Forte**: Ao invés de trafegar mapas fracamente tipados para a camada de negócios, o repositório consome e despacha objetos do tipo `ResumoCroqui` nativamente, garantindo integridade das requisições e downloads.
- **Agrupamento de Metadados**: Converte metadados complexos do protobuf em agrupamentos simples (`Map<String, dynamic>`) apenas para o consumo otimizado pelas *Views* de renderização rápida (`home.dart`, `browse.dart`).
- **Rastreamento de Prioridade e Migração**: Gerencia `recent_picos.yaml` para ordenar os guias mais acessados recentemente no carrossel da Home. Contém lógica de migração automática do formato antigo `.json` para YAML.

### Módulo HTTP e Conectividade (`http/`)
Diretório isolado que retém todas as responsabilidades que interagem com tráfego de rede, conexões externas e simulações do *Ghost Protocol*. A arquitetura geral do aplicativo é completamente agnóstica à internet (offline-first) fora desse módulo.

- **`SyncService` (`sync_service.dart`)**: Trabalhador em segundo plano responsável por manter o conjunto de dados local sincronizado. Trabalha de forma tipada, lendo `ResumoCroqui`. Valida checksums SHA-256 e aciona os downloads atômicos apenas de arquivos alterados.
- **`SyncNetwork` (`sync_network.dart`)**: Responsável pela comunicação HTTP pura, lidando com respostas (como *304 Not Modified* via ETag) e leitura do `.binarypb` mestre.
- **`SyncStorage` (`sync_storage.dart`)**: Trata a persistência atômica no disco, lidando com criação, download em arquivos intermediários (`.tmp`) e substituições seguras em caso de erro na conexão.
- **`ZipInterceptorClient` (`zip_interceptor_client.dart`)**: Implementa o **Ghost Protocol** (`aresta-zip://`). Lê arquivos transparentemente do interior de ZIPs `.croqui` criptografados (XOR) servindo os bytes decodificados como se fosse uma resposta HTTP normal.
- **`UpdateDownloader` (`update_downloader.dart`)**: Verificação OTA (Over-The-Air) e download de atualizações via novos `.apk`.

### `EditorDeCroqui` (`editor_croqui.dart`)
O controlador de contexto e configuração do aplicativo. Rastreia qual modo está ativo e fornece caminhos de diretório dinâmicos para os outros serviços.

- **Modos de operação**:
  - **Oficial**: Dados do servidor GitHub Pages. URL base: `https://aresta-climb.github.io/aresta_serving`.
  - **Editor (URL)**: Servidor local via IP. URL base: a URL fornecida pelo desenvolvedor.
  - **Experimental (aresta-zip)**: Arquivo `.croqui` importado localmente. URL base: `aresta-zip:///caminho/para/o/arquivo.croqui`.
- **Temporizador de Auto-Destruição**: O modo experimental tem vida útil de 20 minutos. Um cronômetro regressivo é exibido em um banner global e, ao chegar em zero, executa um "Nuke" dos dados de teste.
- **Persistência**: Salva o estado em `editor_config.json` para sobreviver reinicializações parciais.

### `ArchiveService` (`archive.dart`)
O utilitário legado de manipulação de arquivos `.croqui`. Ainda é usado para a **importação inicial** do arquivo pelo seletor de arquivos (file picker), extraindo o `indice.binarypb` e copiando o `.croqui` para a pasta de trabalho. Após a importação, o fluxo de leitura é assumido pelo `ZipInterceptorClient`.

### Integração Firebase (`firebase/`)
Subdiretório responsável por isolar o SDK do Firebase do restante da aplicação. Contém serviços para inicialização centralizada, Remote Config e Telemetry (Analytics). Consulte o [`firebase/README.md`](services/firebase/README.md) para detalhes de arquitetura e testes de linter que previnem vazamento de dependências do Firebase para a UI.

---

## 2. Camada de Páginas (`lib/pages/`)

A camada de páginas é responsável pelo roteamento de nível superior, estrutura do Scaffold e montagem dos widgets.

### Navegação Principal (`main.dart`)
Inicializa os bindings do Flutter, cria instâncias do `DatasetRepository` e `SyncService`, aciona a sincronização inicial e configura o `TreeNavigationWrapper` (que monitora o `TreeNavigationController`) para renderizar condicionalmente as visualizações raiz: Início (Home), Explorar (Browse) e Configurações. As transições hierárquicas (GPS, Setores, Vias) reconstroem a interface reativamente com base no nó ativo.

### Páginas de Nível Superior
- **`home.dart`**: Exibe um carrossel dos picos de maior prioridade e uma lista suspensa de todos os picos disponíveis localmente.
- **`browse.dart`**: Lista todos os guias disponíveis no índice mestre com thumbnails dinâmicos, indicadores de download e ações de download inline.
- **`mapao_global.dart`**: O "Mapão Global", uma visão 2D no Google Maps exibindo todos os croquis disponíveis com interações de bottom sheet.
- **`settings.dart`**: Gerenciamento do aplicativo, cache e ferramentas de editor experimental.
- **`terms_of_use.dart`**: Exibe a interface de visualização dos documentos legais do aplicativo (Termos de Uso e Privacidade).

### Páginas Hierárquicas de Guias
Representam a estrutura topológica aninhada de um guia de escalada. O estado flui para baixo passando `DatasetRepository` e `cragId` por toda a hierarquia:

- **`pico.dart`**: Nó raiz de um guia. Exibe resumo, informações logísticas e a lista de setores ou grupos.
- **`grupo.dart` / `setor.dart`**: Subárea geográfica. Adapta a nomenclatura dinamicamente ("Vias" vs "Boulders") de acordo com o tipo de conteúdo do setor.
- **`via.dart`**: Nó folha com beta, descrições e imagens croqui (topo) de alta resolução.

---

## 3. Camada de Navegação (`lib/navigation/`)

A camada de navegação gerencia o fluxo de telas do aplicativo utilizando uma arquitetura baseada em **Árvore de Nós** (Tree Navigation) em vez do tradicional Navigator em pilha (push/pop) do Flutter. Isso previne o acúmulo infinito de páginas redundantes (loops) e otimiza o consumo de memória.

### `navigation_tree.dart`
Contém as definições da estrutura lógica dos nós e o controlador central de estado da navegação.
* **`NavNode`**: Classe base abstrata. Cada nó na árvore mantém uma referência opcional para o seu nó pai (`parent`). Nós da raiz (como `HomeNode`) possuem `parent` nulo. Os nós implementados incluem: `HomeNode`, `BrowseNode`, `MapaoGlobalNode`, `SettingsNode`, `PicoNode`, `SetorNode`, `GrupoNode`, `ViaNode`, `GPSNode`, `MapaInterativoNode` e `MapaGeralPicoNode`.
* **`TreeNavigationController`**: Um `ChangeNotifier` que rastreia o nó ativo (`currentNode`).
  * **Prevenção de Loops (Ancestor Rewinding)**: Ao navegar para um nó que já existe no histórico (cadeia de ancestrais), o controlador realiza um retrocesso (*rewind*) para o nó original em vez de empilhar uma nova página redundante.
  * **Botão de Voltar**: Gerencia a navegação física para o pai correspondente através do método `goBack()`.
  * **Retorno à Raiz**: O método `goHome()` reseta instantaneamente a navegação para o `HomeNode`.

### `navigation_functions.dart`
Expõe a API pública estática **`AppNav`**, que simplifica a navegação no aplicativo fornecendo métodos limpos com resolução automática de dependências (como herança de contexto do Pico, Croqui e Crag ID do nó atual).
* **Métodos Principais**: `AppNav.toPico`, `AppNav.toMapaoGlobal`, `AppNav.toSetor`, `AppNav.toGrupo`, `AppNav.toVia`, `AppNav.toGPS`, `AppNav.back`, `AppNav.home`, e `AppNav.canGoBack`.

---

## 4. Camada de Funções de Visualização (`lib/view_functions/`)

Para evitar arquivos de página monolíticos, todos os construtores de UI complexos, estilização e callbacks são extraídos para o diretório `view_functions/`.

- **Funções específicas** (`home_functions.dart`, `browse_functions.dart`, `mapao_global_functions.dart`, etc.): Contêm funções `build...` e manipuladores de ação para suas respectivas páginas. Reduzem o tamanho dos arquivos em `pages/`.
- **`mapao_marker.dart`**: Renderiza programaticamente, usando `Canvas` e `Path`, o `BitmapDescriptor` personalizado em formato de gota (teardrop) contendo a logotipo do app para os marcadores do Mapão Global.
- **`common_functions.dart`**: Sistema de design. Define paletas de cores (`beastHide`, `nobleBlack`), estilos de texto, componentes genéricos como `buildSortMenu<T>` e a renderização das barras de navegação primária (`buildPrimaryBottomNav`) e secundária (`buildSecondaryBottomNav`).
- **`offline_markdown.dart`**: Visualizador Markdown customizado para o mandato _offline-first_. Substitui o `imageBuilder` padrão para interceptar requisições de imagem e servir arquivos diretamente do armazenamento local via `FileImage`, sem nenhuma chamada de rede.
- **`settings_functions.dart`**: Gerencia a importação de arquivos `.croqui` (via file picker ou URL), a conexão com servidores de editor e a leitura de QR codes. Após a importação, constrói a URL `aresta-zip://` e aciona a sincronização via `SyncService`.

---

## 5. Camada de Widgets (`lib/widgets/`)

Componentes de UI reutilizáveis e independentes que encapsulam lógica visual e comportamento específico.

- **`global_search.dart`**: Componente de pesquisa agregada (Fuzzy Search) que funciona como ponte unificada para busca por Vias, Setores ou Picos.
- **`mapa_thumbnail.dart`**: Widget especializado para exibir uma prévia interativa de mapas de setores ou picos. Resolve automaticamente o caminho da imagem no armazenamento local offline e gerencia o estado de carregamento e a transição para o mapa interativo completo.
