# Arquitetura Principal do Aplicativo Kmon

Este documento descreve a estrutura e o fluxo lógico do aplicativo, com foco em como os dados são buscados, gerenciados e apresentados ao usuário. O aplicativo consiste em uma camada de Serviços (Services) para o gerenciamento de dados, uma camada de Funções (Functions) para componentes de interface/callbacks desacoplados e uma camada de Páginas (Pages) para roteamento e layout.

## 1. Camada de Serviços (`lib/services/`)

A camada de serviços é responsável por toda a comunicação externa (requisições HTTP), gerenciamento de armazenamento local, análise de dados (Protobuf) e estado do aplicativo.

### `DatasetRepository` (`dataset_repository.dart`)
Este é o gerenciador de estado central do aplicativo, orquestrando o fluxo de dados de escalada do armazenamento local até as camadas reativas da interface do usuário (UI). Ele expõe instâncias reativas de `ValueNotifier` (ex: `activeDataset`, `syncStatus`, `downloadingCrags`) que a árvore de widgets do Flutter escuta para atualizações instantâneas e sem travamentos.
- **Gerenciamento de Armazenamento Local**: Garante um verdadeiro isolamento offline criando diretórios dedicados para cada Pico (Crag) baixado dentro do diretório de documentos do aplicativo no dispositivo (`<app_docs>/downloads/<pico_id>/`). Essa estrutura de diretório por pico evita colisões de nomes e torna atualizações ou exclusões direcionadas extremamente eficientes.
- **Download e Análise de Picos**: Lida com a tarefa crucial de baixar os payloads binários do Protocol Buffer (`.binarypb`) que representam um Pico. Uma vez buscado, ele atua como uma ponte, mapeando modelos complexos de protobuf em Maps/Lists mais simples do Dart para que a interface consuma sem precisar conhecer o protocolo de dados subjacente. Ele também é responsável por extrair e rotear o download de ativos explícitos externos.
- **Rastreamento de Prioridade e Migração**: Gerencia um arquivo `recent_picos.yaml` para rastrear a ordem cronológica dos guias acessados recentemente pelo usuário. Isso garante que o carrossel da página inicial (Home) mude dinamicamente para apresentar primeiro o conteúdo mais relevante. Ele também contém uma lógica de fallback automatizada para migrar perfeitamente os arquivos antigos `recent_picos.json` para o formato YAML sem perda de dados.

### `SyncService` (`sync_service.dart`)
Atua como o trabalhador em segundo plano responsável por manter o conjunto de dados local perfeitamente sincronizado com o repositório remoto do GitHub Pages (`acecmg.github.io/kmon_serving`). Ele executa os fluxos HTTP, o tratamento robusto de erros e as atualizações silenciosas em segundo plano sem bloquear a interface do usuário.
- **Sincronização na Inicialização (`syncOnLaunch`)**: É disparada automaticamente na inicialização do aplicativo para buscar o índice mestre mais recente (`indice.binarypb`). Se o servidor retornar um erro 304 (Não Modificado) ou estiver completamente inacessível, o serviço reverte graciosamente para o índice em cache local, atualizando o estado global `SyncStatus` para `error` ou `updated` de acordo.
- **Validação de Checksum em Segundo Plano**: Após a busca do índice, este processo itera pelos Picos baixados localmente e compara seus checksums SHA-256 com o novo índice mestre. Se um Pico desatualizado for encontrado, ele baixa silenciosamente o binário mais recente. Ele então compara de forma inteligente os checksums de imagens individuais dentro do Pico antigo e do novo para limpar imagens obsoletas e baixar apenas as novas, economizando largura de banda e armazenamento.
- **Extração de Imagens Markdown**: Como as descrições em markdown podem conter imagens vinculadas dinamicamente que não estão listadas no array de ativos externos do protobuf, este serviço verifica a string JSON raw do Protobuf de um Pico baixado usando uma expressão regular (`RegExp(r'!\[.*?\]\((.*?)\)')`). Isso extrai de forma confiável todos os caminhos de imagem Markdown incorporados (ex: `![texto alternativo](caminho.jpg)`) e aciona um download suplementar dessas imagens diretamente no diretório isolado do Pico, garantindo disponibilidade offline total.

## 2. Camada de Páginas (`lib/pages/`)

A camada de páginas é responsável pelo roteamento de nível superior, estrutura do Scaffold e montagem dos widgets.

### Navegação Principal (`main.dart`)
O `main.dart` inicializa as ligações (bindings) do Flutter, cria instâncias do `DatasetRepository` e `SyncService`, aciona a sincronização inicial e configura um `BottomNavigationBar` (via `MainNavigationWrapper`) para navegar entre as principais páginas raiz: Início (Home), GPS e Explorar (Browse).

### Páginas de Nível Superior
- **`home.dart`**: O principal ponto de entrada. Escuta o `activeDataset` e exibe:
  1. Um Carrossel dos picos baixados de maior prioridade (acessados recentemente) do usuário.
  2. Uma lista suspensa (dropdown) de todos os picos disponíveis localmente.
- **`browse.dart`**: Exibe uma lista abrangente de todos os guias disponíveis no índice mestre, mostrando quais estão baixados, quais estão ausentes e permitindo que o usuário acione downloads.
- **`gps.dart`**: A visualização de mapa do aplicativo.

### Páginas Hierárquicas de Guias
Essas páginas representam a estrutura topológica profundamente aninhada de um guia de escalada. O estado flui perfeitamente para baixo na árvore de widgets passando a instância de `DatasetRepository` e o `cragId` de nível superior por toda a hierarquia:
- **`pico.dart` (Pico/Montanha)**: O nó raiz de um guia específico. Exibe um resumo de nível superior, informações logísticas e de localização, e uma lista de todos os subgrupos ou setores pertencentes à montanha.
- **`grupo.dart` / `setor.dart` (Setor/Área)**: Representa uma subárea geográfica distinta. Essas páginas adaptam sua nomenclatura de interface dinamicamente (ex: rotulando seções como "Vias" vs "Boulders") dependendo do tipo de conteúdo de escalada presente dentro do conjunto de dados do setor.
- **`via.dart` (Via/Problema de Boulder)**: O nó folha da hierarquia contendo o beta específico, descrições detalhadas e imagens croqui (topográficas) de alta resolução necessárias para escalar com sucesso uma via.

## 3. Camada de Funções (`lib/functions/`)

Para evitar que os arquivos de página se tornem enormes "códigos espaguete" monolíticos, todos os construtores de UI complexos, estilização e lógicas de callback são extraídos para o diretório `functions/`.

- **Funções Específicas de Funcionalidades** (`home_functions.dart`, `browse_functions.dart`, `pico_functions.dart`, etc.): Contêm as funções `build...` (como `buildPicosCarousel` ou `buildAllGuidesDropdown`) e manipuladores de ação (como `handlePicoSelection`) para suas respectivas páginas.
- **`common_functions.dart`**: Contém o sistema de design. Define as paletas de cores (ex: `beastHide`, `nobleBlack`), estilos de texto padrão e componentes comuns (como o `buildPrimaryBottomNav`).
- **`offline_markdown.dart`**: Um visualizador Markdown personalizado profundamente adaptado para o mandato "offline-first" do aplicativo. Widgets Markdown padrão tentam inerentemente resolver `![texto alternativo](caminho)` por meio de uma conexão ativa com a internet. Este módulo substitui o `imageBuilder` padrão para interceptar essas requisições de rede. Ao corresponder o caminho da imagem higienizado — extraído previamente pela lógica Regex do SyncService — ele contorna completamente a camada de rede. Em vez disso, ele utiliza `FileImage` para construir e renderizar a imagem diretamente do armazenamento local isolado do dispositivo (`<app_docs>/downloads/<pico_id>/...`). Isso permite que betas de rich text complexos sejam renderizados instantaneamente e perfeitamente a quilômetros de distância do serviço de celular.
