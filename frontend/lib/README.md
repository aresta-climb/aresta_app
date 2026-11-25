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

Substitui o empilhamento livre de rotas por uma **Árvore de Nós** (`ArvoreNavegacao` / `NavegadorArvore`):
- **`NavNode` (`arvore/`)**: Cada nó guarda a referência ao `parent` e apenas identificadores em texto (`cragId`, `setorNome`, `escaladaNome`, etc.). Se o destino já estiver entre os ancestrais ativos, a árvore recua até ele em vez de duplicar páginas.
- **`PageListenableBuilder` (`construtor_reativo_pagina.dart`)**: Observa o `DatasetRepository` e resolve os objetos Protobuf atuais a partir dos IDs do nó, atualizando a tela em hot-reloads e sincronizações.
- **`AppNav` (`funcoes_navegacao.dart`)**: API estática para transições (`toPico`, `toSetor`, `toGrupo`, `toVia`, `toViaPorUid`, `toMapas`, `toMapaGlobal`, `toLogin`, `toPerfil`, `abrirPerfilOuLogin`, `toCaderneta`, `toSettings`, `back`, `home`, `canGoBack`).

---

## 4. Camada de Apresentação (`lib/view/`)

- **`function_library/`**: Construtores declarativos de UI (`buildCommonAppBar`, `CorpoDetalhesVia`, cabeçalhos, listas e marcadores de mapa) sem estado de negócio.
- **`view_models/`**: Classes `ChangeNotifier` e modelos de apresentação que expõem estado formatado e comandos para cada página ou modal (`LoginViewModel`, `ViaViewModel`, `PerfilViewModel`, `HubPerfilCadernetaViewModel`, `AlertasMapaInterativoViewModel`, `PicoViewModel`, `HomeViewModel`, `BrowseViewModel`, etc.).

---

## 5. Camada de Widgets (`lib/widgets/`)

Componentes visuais reutilizáveis e desacoplados de `services/`:
- **`navegacao/botao_voltar_com_retorno_inicio.dart`**: Botão de retorno padrão das páginas secundárias (toque volta um nível; segurar anima o anel de progresso e a pílula `"Início"` e executa `AppNav.home`).
- **`autenticacao/`, `perfil/`, `caderneta/` e `via/`**: Componentes declarativos de login sem senha, diálogos de perfil, registro/histórico de cadenas, alertas do usuário, consenso de grau, bolhas de alerta e passaporte da via.
- **`provedor_imagem_aresta.dart` e `imagem_arquivo_aresta.dart`**: Resolução de imagens em três níveis (`downloads/`, `temp_cache/` e CDN) com chave de cache vinculada ao SHA-256.
- **`busca_global.dart`, `card_pico.dart`, `painel_filtros_indice.dart`, `mapa_thumbnail.dart` e `bottom_sheets/`**: Pesquisa no catálogo, cartões de picos, filtros de escaladas e modais.

---

## 6. Utilitários (`lib/utils/`)

Funções puras de domínio e geometria:
- **`construtor_caminho_trajeto.dart`**: Conversão de paths SVG para `ui.Path`, estilos de linha FEMEMG, cache de paths/rótulos e cálculo de distância de toque (único arquivo autorizado a importar `package:path_drawing/`).
- **`consulta_dataset.dart`**: Índice em memória (`DatasetResolver`) por `uid` para picos, grupos, setores, escaladas e referências de mapas.
- **`filtro_grau_escalada.dart`, `formatador_escalada.dart` e `calculadora_delta_grau.dart`**: Normalização de graus, cálculo de mediana de setor, filtros e consolidação de votos de grau.
- **`extrator_detalhes_tecnicos_via.dart` e `modelos_apresentacao_via.dart`**: Extração de dados técnicos das cinco modalidades de escalada para apresentação na `ViaPage`.
- **`gerador_uid.dart` e `formatador_creditos.dart`**: Geração/validação de NanoID 14c e UUID v4 e formatação de nomes de autores.
