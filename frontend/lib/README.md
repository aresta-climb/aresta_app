# Arquitetura Principal do Aplicativo Aresta Climb

Este documento descreve a estrutura e o fluxo lógico do aplicativo, com foco em como os dados são buscados, gerenciados e apresentados ao usuário. O aplicativo consiste em uma camada de **Serviços** para o gerenciamento de dados, uma camada de **Apresentação e Visualização** (`lib/view/`) contendo funções de interface (`function_library/`) e modelos de apresentação (`view_models/`), e uma camada de **Páginas** para roteamento e layout.

## 1. Camada de Serviços (`lib/services/`)

A camada de serviços é responsável pelo gerenciamento de estado do aplicativo e da arquitetura baseada em **MVVM**. Classes geradas via **Protobuf** (`ResumoCroqui`, `Indice`, `Croqui`) atuam como nossos **Models** fortemente tipados. O `DatasetRepository` atua como o repositório principal de guias.

### `DatasetRepository` (`repositorio_dataset.dart` e `dataset/`)
O gerenciador de estado central do aplicativo (Singleton), orquestrando o fluxo de dados de escalada do armazenamento local e das sessões online até as camadas reativas da interface. Foi decomposto em submódulos desacoplados de responsabilidade única:

- **`dataset/modelos/`**: Modelo de dados em memória `TopoDataset` e tipos auxiliares fortemente tipados.
- **`dataset/normalizador_croqui.dart`**: Utilitário central de normalização in-place (`NormalizadorCroqui`) executado na leitura de bytes ou desserialização de croquis (`Croqui`, `Pico`, `Mapa`). Garante que entidades legadas recebam UIDs canônicos sintéticos, mapas migrem `label` para `rotulo` e `id` para `uid`, e referências preencham `alvoUid` e `pontosUids`, assegurando que toda a UI opere exclusivamente na especificação v5 sem branches legados.
- **`dataset/armazenamento/`**: `GerenciadorArmazenamento` responsável pela estrutura de diretórios em `<app_docs>/downloads/<pico_id>/` e integridade física.
- **`dataset/metadados/`**: `FormatadorMetadados` e `GerenciadorPrioridade` para ordenação, normalização e manipulação de `recent_picos.yaml`.
- **`dataset/sessao_online/`**: `GerenciadorSessaoOnline` responsável pelo gerenciamento de croquis visualizados sob demanda na RAM e cache volátil (`/temp_cache`), além de notificações de atualização de versão via ETag.

### Autenticação, Mídia Nativa e Caderneta (`autenticacao/`, `midia/` e `caderneta/`)
Subsistema responsável pela identidade esportiva do escalador, autenticação com o Supabase e gestão local-first da caderneta de ascensões:

- **`ServicoAutenticacaoLocal` (`autenticacao/servico_autenticacao.dart`)**: Valida credenciais locais, coordena os fluxos de entrada por e-mail/senha, criação de conta, login Google OAuth e atualização remota de perfil, e persiste o `PerfilEscalador` no `RepositorioCaderneta` preservando o `autorIdPublico` (NanoID 14c) e as cadenas registradas offline.
- **`ClienteSupabaseAutenticacao` (`autenticacao/cliente_supabase_autenticacao.dart`)**: Isola os protocolos HTTP e OAuth 2.0 (PKCE `S256` e `Implicit`) com o Supabase GoTrue (`/auth/v1/token`, `/auth/v1/signup`, `/auth/v1/authorize`, `/auth/v1/user`), o espelhamento em `public.perfis` via PostgREST (`/rest/v1/perfis`) e o upload de fotos de perfil para o bucket `avatars` no Supabase Storage (`/storage/v1/object/avatars/<userId>/avatar.jpg`).
- **`SeletorFotoPerfilNativo` (`midia/seletor_foto_perfil.dart`)**: Aciona o canal nativo `app.escalada.croquis/seletor_midia` (implementado em Kotlin no Android via `GetContent` + `Bitmap` e em Swift no iOS via `PHPickerViewController` + `UIGraphicsImageRenderer`) para selecionar uma imagem da galeria, recortá-la em quadrado central `256x256` e comprimi-la em JPEG (`data:image/jpeg;base64,...`).
- **`RepositorioCadernetaLocal` e `CatalogoViasCaderneta` (`caderneta/`)**: Gerenciam a persistência local de ascensões (`Cadena`) e perfil (`PerfilEscalador`), a compilação da pirâmide de graus (`CompiladorEstatisticasCaderneta`) e a resolução reativa de nomes de vias, graus e picos a partir do `catalogo.db` e dos croquis em memória.

### Módulo HTTP e Conectividade (`http/`)
Diretório isolado que retém todas as responsabilidades que interagem com tráfego de rede, conexões externas, downloads em background e streaming sob demanda.

- **`SyncService` (`sync_service.dart`)**: Trabalhador em segundo plano responsável por manter o conjunto de dados local sincronizado. Trabalha de forma tipada, lendo `ResumoCroqui`. Em `syncIndex()`, executa um fluxo em duas fases: na Fase 1 (rápida), aguarda apenas o download condicional de `indice.binarypb` e a sincronização delta de `catalogo.db` (`sincronizarCatalogoSeNecessario`), retornando imediatamente com deduplicação por janela de *cooldown* de 30s; na Fase 2 (em segundo plano via `tarefaMidiasEmSegundoPlano`), sincroniza *thumbnails*, atualiza picos baixados via `Isolate`, realiza o *commit* atômico dos arquivos `.tmp` antes de publicar o novo `activeDataset` e recarrega reativamente croquis abertos em sessão online cujo SHA-256 mudou. Expõe `lastSyncWasAuto` e `quantidadeCroquisBaixadosAtualizadosNoUltimoSync` para que a UI notifique o usuário quando croquis forem alterados.
- **`SyncIsolate` (`sync_isolate.dart`)**: Executa as validações pesadas de integridade (SHA256) e gere o fluxo das Delta Syncs (baixando apenas arquivos que mudaram) em uma thread separada para não causar travamentos ou "lag" na UI.
- **`SyncNetwork` (`sync_rede.dart`)**: Responsável pela comunicação HTTP de sincronização, lidando com respostas (como *304 Not Modified* via ETag) e leitura do `.binarypb` mestre.
- **`SyncStorage` (`sync_armazenamento.dart`)**: Trata a persistência atômica no disco, lidando com criação, download em arquivos intermediários (`.tmp`) e substituições seguras em caso de erro na conexão.
- **`ServicoCroquiOnline` (`servico_croqui_online.dart`)**: Baixa arquivos `.binarypb` sob demanda em milissegundos para navegação imediata sem exigir download prévio e executa polling periódico leve de ETag.
- **`ServicoDownloadSegundoPlano` (`servico_download_segundo_plano.dart`)**: Realiza downloads permanentes resilientes em segundo plano com notificações persistentes (`ongoing: true`).
- **`UpdateDownloader` (`baixador_atualizacoes.dart`)**: Verificação OTA (Over-The-Air) e download de atualizações via novos `.apk`.

### `EditorDeCroqui` (`editor_croqui.dart`)
O controlador de contexto e configuração do aplicativo. Rastreia qual modo está ativo e fornece caminhos de diretório dinâmicos para os outros serviços.

- **Modos de operação**:
  - **Oficial**: Dados do servidor CDN/GitHub Pages. URL base: `https://aresta-climb.github.io/aresta_serving`.
  - **Experimental / Live Reload**: Conexão com Editor Desktop via WebSocket e Live Reload.
- **Persistência**: Salva o estado em `editor_config.yaml` para sobreviver reinicializações parciais e limpa dados experimentais ao reiniciar do zero.

### Integração Firebase (`firebase/`)
Subdiretório responsável por isolar o SDK do Firebase do restante da aplicação. Contém serviços para inicialização centralizada, Firebase App Check (atestação de integridade para Play Integrity / App Attest), Remote Config (incluindo fallbacks de URL e chave pública do Supabase), Telemetry (Analytics) e `ServicoPerformance` (`performance_telemetria.dart`). O `ServicoPerformance` instrumenta 8 jornadas críticas de usabilidade (`cold_start_home`, `cold_start_deep_link`, `warm_start_deep_link`, `sync_index_fase1`, `sync_index_fase2`, `abrir_croqui`, `navegacao_interna_croqui` e `abrir_mapa_interativo`) com dupla emissão (Custom Traces no Firebase Performance + parâmetro `duracao_ms` e dimensões de fatiamento como `modo_acesso`, `origem_imagem` e `status_http` no GA4/BigQuery/Looker Studio) e bloqueio estrito em modo debug (`kDebugMode == true`). Consulte o [`firebase/README.md`](services/firebase/README.md) para detalhes de arquitetura e testes de linter que previnem vazamento de dependências do Firebase para a UI.

---

## 2. Camada de Páginas (`lib/pages/`)

A camada de páginas é responsável pelo roteamento de nível superior, estrutura do Scaffold e montagem dos widgets.

### Ponto de Entrada e Bootstrap (`main.dart` e `tela_splash_inicial.dart`)
Inicializa os bindings do Flutter, executa tarefas independentes de *bootstrap* em paralelo (`Future.wait`), preserva o bloqueio de `DatabaseMigrationScreen` em mudanças estruturais (`needsMigration == true`), cria instâncias do `DatasetRepository` e `SyncService` e monta o widget raiz `MyApp`. Durante a abertura a frio (*Cold Start*), `MyApp` exibe a `TelaSplashInicial` (com a mesma identidade visual da splash nativa `#ffffff` + `assets/logo_splash.png`) enquanto `resolverDestinoInicialColdStart` verifica se o aplicativo foi aberto por um Deep Link (`getInitialLink()`) e resolve o `NavNode` de destino (com fallback automático ao `syncIndex()` quando um `uid` recém-publicado ainda não consta no `catalogo.db` local). Assim que resolvido, `MyApp` realiza um *cross-fade* suave via `AnimatedSwitcher` (~250ms, `Curves.easeOut`) diretamente para o `TreeNavigationWrapper` na página de destino (sem piscar a `HomePage`), registra o tempo até interatividade (`addPostFrameCallback`) via `ServicoPerformance` e `setupAppServices` aciona a sincronização em segundo plano.

### Páginas de Nível Superior
- **`home.dart`**: Exibe um carrossel dos picos de maior prioridade e uma lista suspensa de todos os picos disponíveis localmente.
- **`explorar.dart`**: Lista todos os guias disponíveis no índice mestre com thumbnails dinâmicos, indicadores de download e ações de download inline.
- **`mapa_global.dart`**: O "Mapa Global", uma visão 2D no Google Maps exibindo todos os croquis disponíveis com marcadores escalonados por faixas de zoom (Macro, Regional e Local), balões compactos com truncamento automático de texto e interações de bottom sheet.
- **`comunidade.dart`**: Hub central com mídias, apoios e links interativos (WhatsApp, Instagram, Discord, GitHub).
- **`login.dart`**: Tela de entrada e criação de conta com suporte a Google OAuth, e-mail/senha e opção de continuar sem conta no modo offline.
- **`hub_perfil_caderneta.dart`**: Hub do Perfil do Escalador, exibindo foto de perfil com botão de câmera para atualização instantânea, nome esportivo, 4 cartões de métricas rápidas (`CADENAS`, `TENTATIVAS`, `PICOS`, `VIAS`) e menu de ações (entrar na conta, minha caderneta, configurações, dados/privacidade e sair).
- **`caderneta.dart`**: Página detalhada da caderneta esportiva pessoal com pirâmide de graduação (vias e boulders), estatísticas e histórico cronológico de ascensões.
- **`configuracoes.dart`**: Gerenciamento do aplicativo, preferência de visibilidade da caderneta, cache e ferramentas de editor experimental.
- **`termos_de_uso.dart`**: Exibe a interface de visualização dos documentos legais do aplicativo (Termos de Uso e Privacidade).

### Páginas Hierárquicas de Guias
Representam a estrutura topológica aninhada de um guia de escalada. O estado flui para baixo passando `DatasetRepository` e `cragId` por toda a hierarquia:

- **`pico.dart`**: Nó raiz de um guia. Exibe resumo, informações logísticas e a lista de setores ou grupos.
- **`mapas_carrossel.dart`**: Navegação em formato carrossel horizontal (swiping) contendo múltiplos `mapa_interativo.dart`, oferecendo transições de mapa mais fluidas entre hierarquias e subsetores do guia de escalada.
- **`mapa_interativo.dart`**: Visualizador de mapas e croquis vetoriais com zoom livre, POIs interativos, card flutuante responsivo de detalhes e botão de recentralizar (GPS) dinamicamente posicionado acima do card para evitar sobreposição de elementos na interface.
- **`grupo.dart` / `setor.dart`**: Subárea geográfica. Adapta a nomenclatura dinamicamente ("Vias" vs "Boulders") de acordo com o tipo de conteúdo do setor.
- **`via.dart`**: Nó folha com beta, descrições, imagens croqui (topo) de alta resolução e seção interativa de registro de cadenas.

---

## 3. Camada de Navegação (`lib/navigation/`)

A camada de navegação gerencia o fluxo de telas do aplicativo utilizando uma arquitetura baseada em **Árvore de Nós** (Tree Navigation) em vez do tradicional Navigator em pilha (push/pop) do Flutter. Isso previne o acúmulo infinito de páginas redundantes (loops) e otimiza o consumo de memória.

### `arvore_navegacao.dart`
Contém as definições da estrutura lógica dos nós e o controlador central de estado da navegação.
* **`NavNode`**: Classe base abstrata. Cada nó na árvore mantém uma referência opcional para o seu pai (`parent`) e armazena **apenas identificadores em texto** (como `cragId`, `setorNome`, etc.), nunca objetos do banco de dados, para garantir a resiliência a hot-reloads de dados. Os nós implementados incluem: `HomeNode`, `BrowseNode`, `MapaGlobalNode`, `LoginNode`, `PerfilNode`, `CadernetaNode`, `PicoNode`, `SetorNode`, `ViaNode`, `MapaInterativoNode`, entre outros.
* **`TreeNavigationController`**: Um `ChangeNotifier` que rastreia o nó ativo (`currentNode`).
  * **Prevenção de Loops**: Realiza um retrocesso (*rewind*) para o nó original em vez de empilhar uma nova página redundante se o nó já existir no histórico.
  * **Botão de Voltar / Home**: Gerencia o retorno de telas (`goBack`) e reset para a tela inicial (`goHome`).

### `construtor_reativo_pagina.dart`
O coração do **Hot-Reload Reativo**. Atua como o elo entre a Árvore de Navegação e a UI.
* Fica escutando as mudanças no `activeDataset` do `DatasetRepository` (acionadas em background pelo `SyncService`).
* Em vez de injetar objetos engessados na inicialização da página, este Builder intercepta as transições, lê os identificadores (IDs) do `NavNode` atual e busca em tempo real os dados mais recentes do modelo `TopoDataset` para injetar nas views (`PicoView`, `SetorView`, etc.).
* É o que permite que as telas do Aresta se atualizem instantaneamente quando um croqui sofre um hot-reload pelo Editor.

### `funcoes_navegacao.dart`
Expõe a API pública estática **`AppNav`**, que simplifica a navegação no aplicativo.
* **Métodos Principais**: `AppNav.toPico`, `AppNav.toMapaGlobal`, `AppNav.toSetor`, `AppNav.toGrupo`, `AppNav.toVia`, `AppNav.toViaPorUid`, `AppNav.toGPS`, `AppNav.toLogin`, `AppNav.toPerfil`, `AppNav.abrirPerfilOuLogin`, `AppNav.toCaderneta`, `AppNav.back`, `AppNav.home`, e `AppNav.canGoBack`.

---

## 4. Camada de Apresentação e Visualização (`lib/view/`)

A camada de visualização é dividida de forma modular em duas subcamadas complementares, seguindo o padrão MVVM e mantendo os arquivos de `pages/` enxutos, focados apenas na estrutura do Scaffold e ciclo de vida:

### Subcamada de Funções de Interface (`lib/view/function_library/`)
Reúne os construtores visuais, componentes de layout específicos de cada tela e callbacks de interação do usuário:
- **Funções específicas por página** (`funcoes_home.dart`, `funcoes_explorar.dart`, `funcoes_hub_perfil_caderneta.dart`, `funcoes_caderneta.dart`, `setor_functions.dart`, `sobre_time_functions.dart`, `meus_croquis_functions.dart`, `comunidade_functions.dart`, `pico_functions.dart`, `via_functions.dart`, etc.): Contêm funções `build...` e despachadores de ação. Modelos tipados (`RotulosVia`, `MembroTime`, `MetadadosIndice`, `Croqui`) e funções dedicadas eliminam aninhamentos condicionais complexos e facilitam testes de widget granulares.
- **`mapa/` (Subdiretório)**: Organiza as funções exclusivas do mapa de visualização global (`mapa_global_functions.dart`) e o `mapa_marker.dart`, que renderiza programaticamente via `Canvas` e `Path` o marcador personalizado na cor oficial da marca.
- **`biblioteca_funcoes_comuns.dart`**: Sistema de design compartilhado. Define componentes como menus (`buildSortMenu<T>`), barras de navegação primária (`buildPrimaryBottomNav`) e secundária, e utilitários de texto seguro.
- **`markdown_offline.dart`**: Visualizador Markdown customizado para o modelo *offline-first*. Intercepta requisições de imagem para servir arquivos diretamente do armazenamento local via `FileImage`, sem chamadas de rede.
- **`funcoes_configuracoes.dart`**: Gerencia a conexão com servidores de editor desktop (via código de prévia ou URL) e leitura de QR codes, acionando a sincronização e Live Reload via `SyncService` e WebSocket.

### Subcamada de Modelos de Apresentação (`lib/view/view_models/`)
Encapsula o estado da interface, cálculos visuais derivados (como distâncias geográficas de picos próximos e status de download) e prepara os dados de domínio para renderização passiva:
- **`login_view_model.dart`**: Orquestra os modos de entrada/criação de conta por e-mail e senha, login com Google OAuth e estados de carregamento/erro.
- **`hub_perfil_caderneta_view_model.dart`**: Orquestra os dados do `PerfilEscalador` (nome, `fotoUrl`, `autorIdPublico`, `estaAutenticado`), métricas rápidas e sincronização de nome e foto de perfil com o Supabase.
- **`perfil_view_model.dart`**: Gerencia o histórico de ascensões e estatísticas da caderneta esportiva.
- **`card_croqui_view_model.dart`**: Modela a apresentação de cartões de croqui na Home e na Busca Global, expondo getters tipados para contagem de vias, setores, download e identificadores.
- **`mapa_pico_view_model.dart`**: Encapsula dados de coordenadas, visibilidade, nome e cálculo de marcadores para projeção no Google Maps.
- **`pico_proximo_view_model.dart`**: Calcula distâncias geográficas relativas à posição do usuário e disponibilidade offline para alimentação do carrossel de picos próximos.
- **View Models de Páginas** (`explorar_view_model.dart`, `home_view_model.dart`, `meus_croquis_view_model.dart`, `pico_view_model.dart`, `configuracoes_view_model.dart`, `comunidade_view_model.dart`, `mapa_global_view_model.dart`): Gerenciam os estados reativos locais, ordenações e filtros de cada tela correspondente.

---

## 5. Camada de Widgets (`lib/widgets/`)

Componentes de UI reutilizáveis e independentes que encapsulam lógica visual e comportamento específico.

- **`perfil/dialogos_hub_perfil.dart`**: Reúne os diálogos e modais do Hub de Perfil (`DialogoEditarPerfil` com prévia de avatar e botão para escolher nova foto da galeria, `ModalDadosPrivacidade` exibindo o NanoID 14c para cópia e `DialogoConfirmarSaida`).
- **`caderneta/`**: Componentes modulares da caderneta esportiva (`ModalRegistroCadena`, `GraficoPiramideGraus`, `CardEstatistica` e controles de formulário).
- **`card_pico.dart`**: Card modular interativo para exibição de picos na grade ou listagem (usado no Explorar/Browse e no carrossel de picos próximos). Consome diretamente metadados de catálogo ([`MetadadosIndice`]) com acesso O(1) a pré-computados, contagem de setores/vias, status de download e telemetria de visualização.
- **`linha_credito_autor.dart`**: Widget padronizado para exibição dos créditos de autores e conquistadores do croqui. Suporta quebra automática em múltiplas linhas para listas longas, mantendo o ícone `Icons.person_outline` alinhado ao topo.
- **`feedback/`**: Contém o `construtor_feedback_usuario.dart`, responsável por substituir e construir a interface de formulário do in-app feedback, mantendo coesão com as cores e design do aplicativo.
- **`busca_global.dart`**: Componente de pesquisa agregada (Fuzzy Search) que funciona como ponte unificada para busca por Vias, Setores ou Picos.
- **`mapa_thumbnail.dart`**: Widget especializado para exibir uma prévia interativa de mapas de setores ou picos. Resolve automaticamente o caminho da imagem no armazenamento local offline e gerencia o estado de carregamento e a transição para o mapa interativo completo.
- **`banner_modo_online.dart`**: Banner informativo persistente que avisa o usuário quando o croqui está em modo online sob demanda.
- **`modal_confirmacao_saida.dart`**: Guardião de saída (`PopScope`) que alerta o usuário sobre a necessidade de salvar o croqui offline antes de sair para a montanha.
- **`provedor_imagem_aresta.dart`**: Provedor unificado com resolução em camadas (downloads permanente, cache volátil e streaming remoto CDN com query `?v=<sha256>`). Realiza auto-resolução de SHA-256 via `DatasetRepository`.
- **`imagem_arquivo_aresta.dart`**: Implementação especializada de `ImageProvider<ChaveImagemArquivoAresta>` que substitui o `FileImage` do Flutter, indexando a chave de cache nativa por caminho, escala e `checksumSha256` para invalidar texturas em disco reativamente sem piscar a UI.
- **`verificador_versao_app.dart`**: Widget e telas de verificação de versão mínima com alerta de obsolescência e bloqueio rígido.
- **`micro_badge_beta.dart`**: Micro-badge ultracompacto para sinalização do estágio de "Beta Aberto" no cabeçalho da Home com proteção contra overflow em larguras a partir de 320dp e abertura interativa do modal informativo.
- **`modal_beta_aberto.dart`**: Modal explicativo em BottomSheet com título em destaque, tópicos do estágio comunitário do projeto, botões em largura total com forte ênfase para o Instagram Oficial, Comunidade no WhatsApp e acionamento nativo de feedback (`BetterFeedback`).
- **`badges_modalidades.dart`**: Renderiza chips compactos e responsivos (`Wrap`) com as contagens e nomes das modalidades de escalada presentes em um setor ou grupo (esportivas, móveis, boulders, multienfiadas, highlines), com concordância gramatical automática (singular/plural) e cores do tema.

---

## 6. Camada de Utilitários e Traçados Vetoriais (`lib/utils/`)

Reúne utilitários de domínio para manipulação de dados, resolução de índices e renderização vetorial.

- **`consolidador_modalidades.dart`**: Utilitário responsável pela agregação quantitativa de modalidades de escalada em setores e grupos, tratamento de singular e plural para cada modalidade, formatação do resumo quantitativo de grupos (`"X setores • Y escaladas"`) e fallback automático para dados pré-computados quando disponíveis.
- **`formatador_creditos.dart`**: Validação de placeholders genéricos e formatação de listas de autores/créditos em frases amigáveis (`"Croqui por ..."`).
- **`construtor_caminho_trajeto.dart`**: Barreira arquitetural exclusiva para o subsistema de desenho vetorial com `package:path_drawing/`. Converte dados compilados SVG (`M ... C ...`) em `ui.Path` nativo, aplica estilos de traçado FEMEMG (sólido, tracejado, pontilhado), mantém cache em memória por rota/estilo e de layouts tipográficos de rótulos (`TextPainter` via `obterTextPainterMarcador`) para garantir 60/120 FPS no `InteractiveViewer`, realiza conversão defensiva de cores hexadecimais (`ponto.cor`) e amostra polilinhas para detecção ergonômica de toques (hit-testing por menor distância euclidiana com tolerância de 16dp).
- **`resolvedor_rotulos_referencia.dart`**: Resolvedor determinístico local de rótulos visuais (`extrairRotuloReferencia`) a partir de `ref.pontosUids` e `ponto.rotulo` no escopo da coleção de pontos de interesse de cada mapa.
- **`consulta_dataset.dart`**: Catálogo relacional e resolvedor em tempo constante $O(1)$ de entidades estruturais ([`Botao`], [`Grupo`], [`Setor`], [`Escalada`]) indexadas exclusivamente por `uid` permanente através de [`DatasetResolver`] (cacheado por instância de [`Pico`] via `Expando` e propagado na árvore por `PageListenableBuilder`). Associa referências visuais pré-computadas ([`ReferenciaNoMapa`]) e gera os dados do carrossel unificado ([`resolverCarrosselUnificado`]), eliminando recursões lineares repetidas na renderização de páginas e substituindo definitivamente o antigo `CroquiMapIndex`.
