# Arquitetura de `lib/` — Aresta Climb

Este documento descreve a organização dos módulos em `frontend/lib/`. O código segue o padrão **MVVM**: páginas e widgets apenas renderizam estado e encaminham eventos aos ViewModels, que consultam repositórios e serviços.

---

## 1. Camada de Serviços (`lib/services/`)

Gerencia persistência local, chamadas HTTP, sincronização em segundo plano, autenticação e telemetria. Mensagens Protobuf (`Indice`, `ResumoCroqui`, `Croqui`) e classes em `lib/data/modelos/` compõem os modelos de domínio.

### `DatasetRepository` (`repositorio_dataset.dart` e `dataset/`)
Repositório central dos guias de escalada:
- **`dataset/modelos/`**: Estrutura `TopoDataset` e metadados em memória.
- **`dataset/normalizador_croqui.dart`**: Normaliza estruturas `Croqui`, `Pico` e `Mapa` na leitura para o formato v5 (preenchendo `uid`, `rotulo`, `alvoUid` e `pontosUids`).
- **`dataset/armazenamento/`**: Leitura e escrita em `<app_docs>/downloads/<pico_id>/`.
- **`dataset/metadados/`**: Ordenação de acesso recente (`recent_picos.yaml`) e extração de metadados.
- **`dataset/sessao_online/`**: Cache em RAM e em `/temp_cache` para croquis abertos sem download permanente.

### Autenticação, Mídia, Caderneta e Comunidade (`autenticacao/`, `midia/`, `caderneta/`, `comunidade/`)
- **`ServicoAutenticacaoLocal`**: Coordena login sem senha (código OTP de 6 dígitos por e-mail, Google e Apple), atualização de perfil, saída e exclusão de conta, mantendo o `autorIdPublico` (NanoID 14c) e as cadenas locais.
- **`ClienteSupabaseAutenticacao` e `SincronizadorPerfilSupabase`**: Comunicam-se com Supabase Auth (`/auth/v1`), tabela `public.perfis` (`/rest/v1/perfis`), RPC `excluir_minha_conta` e bucket `avatars` no Supabase Storage.
- **`SeletorFotoPerfilNativo`**: Usa o canal `app.escalada.croquis/seletor_midia` (Android e iOS) para corrigir EXIF, recortar a imagem em `256x256` e comprimir em WebP (`data:image/webp;base64,...`).
- **`RepositorioCadernetaLocal`, `ClienteCadenasSupabase` e `CatalogoViasCaderneta`**: Armazenam ascensões localmente, sincronizam com `public.cadenas`, calculam estatísticas (`CompiladorEstatisticasCaderneta`) e resolvem nomes/graus de vias pelo `catalogo.db` e memória.
- **`RepositorioInteracoesViaMemoria` e `ClienteFilaInteracoesSupabase`**: Sincronizam votos de grau (`-2` a `+2`), comentários públicos e alertas de segurança (`FAUNA`, `ROCHA_AGARRA_INSTAVEL`, `PROTECAO_PRECARIA`, `EXPOSICAO_E4_MAIS`) com `public.fila_interacoes`, mantendo fila offline e deduplicação por `autorIdPublico`.

### Rede e Sincronização (`http/`)
- **`ClienteHttpAresta`**: Único ponto de acesso ao pacote `http`, mantendo pool de conexões Keep-Alive.
- **`SyncService`**: Executa sincronização em duas fases: Fase 1 valida `indice.binarypb` e atualiza `catalogo.db`; Fase 2 baixa miniaturas e atualiza croquis salvos em background.
- **`SyncIsolate`, `SyncNetwork` e `SyncStorage`**: Executam download HTTP com suporte a ETag (`304`), validação SHA-256 em `Isolate` e gravação via arquivo `.tmp` antes da substituição final (`compilado.binarypb`).
- **`ServicoCroquiOnline` e `ServicoDownloadSegundoPlano`**: Carregam croquis sob demanda com `?v=<sha256>` e gerenciam downloads em segundo plano com notificação nativa.

### `EditorDeCroqui` (`editor_croqui.dart`)
Alterna entre o contexto oficial (CDN) e o contexto experimental (Editor Desktop via WebSocket e diretórios isolados em `editor/experimental/`). Limpa os dados experimentais ao reiniciar o aplicativo ou encerrar a sessão.

### Firebase e Logs (`firebase/`)
Isola os pacotes do Firebase e do Sentry do restante do código (`AppLogger`, `TelemetryService`, `ServicoPerformance`, `RemoteConfigService`, `ValidadorApp`). Consulte [`services/firebase/README.md`](services/firebase/README.md).

---

## 2. Camada de Páginas (`lib/pages/`)

Monta o `Scaffold`, conecta o ViewModel correspondente e delega a construção de seções para `lib/view/` e `lib/widgets/`.

- **Inicialização (`main.dart` e `tela_splash_inicial.dart`)**: Inicializa serviços locais em paralelo, exibe `DatabaseMigrationScreen` quando há migração pendente, resolve eventual deep link inicial durante a `TelaSplashInicial` e monta `TreeNavigationWrapper`.
- **Abas Principais**: `home.dart`, `explorar.dart`, `meus_croquis.dart` e `comunidade.dart` permanecem em um `IndexedStack` na base do navegador.
- **Telas Globais**: `mapa_global.dart`, `gps.dart`, `login.dart`, `hub_perfil_caderneta.dart`, `caderneta.dart`, `configuracoes.dart`, `sobre_time.dart`, `termos_de_uso.dart` e `qr_scanner.dart`.
- **Hierarquia do Guia**: `pico.dart`, subpáginas em `pico_subpages/` (`setores_page.dart`, `explorar_local_page.dart`, `comunidade_pico_page.dart`, `apoie_pico_page.dart`), `grupo.dart`, `setor.dart`, `via.dart`, `mapas_carrossel.dart` e `mapa_interativo.dart`.

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
- **`login_view_model.dart`**: Orquestra o fluxo sem senha de código OTP de 6 dígitos por e-mail (janela deslizante 6/min), login in-app Google/Apple, cancelamento silencioso e estados de carregamento/erro.
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
