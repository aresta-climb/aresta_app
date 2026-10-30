# Documentação de Serviços — Aresta Climb

Este diretório contém a lógica de negócios e os serviços centrais do aplicativo. A arquitetura é construída com princípios de Clean Architecture e separação de responsabilidades, suportando tanto o modo de produção oficial quanto o modo experimental de Live Reload para editores.

---

## Arquivos

| Arquivo / Pasta | Responsabilidade |
|---|---|
| `repositorio_dataset.dart` | Fachada e gerenciador de estado central: downloads, índice, metadados e prioridade |
| `dataset/` | Submódulos desacoplados de responsabilidade única (`modelos/`, `armazenamento/`, `metadados/`, `sessao_online/`) |
| `editor_croqui.dart` | Controle de contexto: modo ativo, caminhos de diretório, temporizador experimental |
| `http/` | Módulo de rede e sincronização (downloads, atualizações OTA, `ServicoCroquiOnline`, `ServicoDownloadSegundoPlano`) |
| `notificacoes/` | Gerenciamento de notificações nativas de download (`GerenciadorNotificacaoDownload`) com suporte a Foreground Services e progresso contínuo |
| `firebase/` | Diretório isolado contendo toda integração com Firebase (Analytics, Crashlytics, Remote Config) |
| `feedback/` | Gerenciamento de envio de In-App Feedbacks via fila local (SharedPreferences) e despacho assíncrono em background (Workmanager) para o Supabase |
| `inicializacao_app.dart` | Rotinas de inicialização e ciclo de vida: gestão de memória/vitals (`configurarGestaoMemoria`), exibição de ponta a ponta (`configurarExibicaoPontaAPonta`), foreground takeover (`setupAppServices`), ouvintes WebSocket (`registrarOuvintesLiveReload`) e migração de termos legais (`migrarTermosLegais`) |
| `configuracao_recursos.dart` | Controle de flags de compilação (`--dart-define`) e chaves secretas de acesso para recursos em desenvolvimento (Perfil do Escalador e Caderneta Esportiva) |

---

## Modo Experimental & Live Reload — Ciclo de Vida

O Modo Experimental permite testar croquis e alterações em tempo real diretamente do Editor Desktop via WebSocket e Live Reload.

### Acesso e Segurança

- **Easter Egg**: As opções de desenvolvedor ficam ocultas. O usuário precisa tocar **7 vezes seguidas** no ícone de status da página de Configurações para desbloqueá-las.
- **Sem Limite de Tempo**: O modo experimental permanece ativo durante toda a sessão de uso no aplicativo, sem contagem regressiva ou auto-destruição automática.
- **Sessão Volátil (Nuke on Startup)**: Para garantir a integridade da base oficial e evitar que o usuário fique preso em dados de teste desatualizados, todos os dados experimentais são limpos automaticamente quando o app é fechado e reaberto do zero.

### Isolamento de Dados

O `EditorDeCroqui` gerencia dois contextos de armazenamento isolados:

| Contexto | URL base | Diretório de índice | Catálogo SQLite | Diretório de downloads |
|---|---|---|---|---|
| **Oficial** | `https://aresta-climb.github.io/aresta_serving` | `<docs>/indice.binarypb` | `<docs>/catalogo.db` | `<docs>/downloads/` |
| **Experimental** | URL de Prévia / Live Reload do Editor | `<docs>/editor/experimental/indice.binarypb` | `<docs>/editor/experimental/catalogo.db` | `<docs>/editor/experimental/downloads/` |

### Fluxo de Conexão com Editor Desktop

1. O usuário digita o código de 8 caracteres ou escaneia o QR Code gerado no Editor Desktop.
2. O app realiza a resolução híbrida (Smart LAN-First com fallback para Cloudflare Relay).
3. Conexão WebSocket para escuta de eventos `live_reload` em tempo real.
4. O `SyncService` (reutilizando `SyncService.instance`) sincroniza o índice e baixa o `catalogo.db` experimental com `forceBypassCache: true`, habilitando Busca Global (`GlobalSearch`) e Deep Links (`LocalizadorDestinoUid`) imediatamente para o escopo da sessão experimental.

### Saída do Modo Experimental & Restauração de Produção

Ao sair do Modo Experimental (via botão `[ SAIR ✕ ]` no `BannerModoExperimental`, programaticamente ou automaticamente por expiração da sessão):
1. **Limpeza e Desconexão Coordenada (`nukeExperimentalData`)**: Encerra o WebSocket de Live Reload, aguarda o fechamento serializado da conexão SQLite ativa (`await aoAntesDeLimparDadosExperimentais?.call()` -> `repositorioCatalogo.fechar()`), remove recursivamente os diretórios voláteis (`editor/experimental` e `edited`), grava a configuração atômica e redefine `isExperimentalMode.value = false` antes de zerar `editorUrl.value`. Isso previne `FileSystemException` por arquivo bloqueado no Windows e impede que ouvintes tentem ler arquivos no caminho experimental já excluído.
2. **Restauração Imediata em Memória (`DatasetRepository.init`)**: Ao alternar o modo (`_handleModeChange`), o repositório limpa a sessão online em memória (`gerenciadorSessaoOnline.limparTudo()`) e a tabela de hashes (`_tabelaSha256PorPico.clear()`), fecha a conexão SQLite anterior e recarrega imediatamente o índice de produção oficial (`indice.binarypb`) a partir do disco, populando `activeDataset` sem esvaziamentos prévios (`loadEmpty()`) ou piscadas na interface.
3. **Encerramento Automático de Sessão Expirada (`HTTP 404`)**: Quando o Editor Desktop é fechado pelo autor ou o túnel Cloudflare Relay (`previa.arestaclimb.com`) expira e `SyncNetwork.fetchIndiceWithRetries` retorna `IndiceErroServidor(statusCode: 404)` com `isExperimentalMode.value == true`, o `SyncService` executa `nukeExperimentalData()`, restaura o índice oficial em memória (`datasetRepository.init()`), define `syncStatus.value = SyncStatus.updated` e aciona `notificarSessaoExperimentalExpirada()`. O widget raiz `MyApp` escuta `notificadorSessaoExpirada`, redireciona a navegação para a Home (`AppNav.home`) e apresenta o diálogo `ModalSessaoExperimentalEncerrada`.
4. **Resiliência a Cache HTTP 304 (`SyncService`)**: Caso o servidor retorne HTTP 304 Not Modified, o `SyncService` detecta se a memória local está vazia (`isEmpty`) e força o recarregamento do arquivo local de índice, garantindo que o catálogo oficial permaneça 100% disponível offline e online.

### Estabilização de Cotas e Proteção do Relay (Cloudflare & WebSocket)

Para evitar exaustão de requisições e consumo excessivo de cotas em túneis de retransmissão remotos (`aresta-previa-relay` / Cloudflare Durable Objects):
- **Suporte a ETag e HTTP 304 no Túnel Retransmissor Desktop**: O retransmissor Python avalia o cabeçalho `If-None-Match` comparando com o SHA-256 do arquivo local e devolve status `304 Not Modified` com corpo vazio quando não há alterações, evitando re-downloads contínuos de arquivos inalterados.
- **Dormência de Polling com WebSocket Conectado**: O `ServicoCroquiOnline` consulta `isLiveReloadConectado` e mantém os timers de polling periódicos de 30 segundos totalmente dormentes (sem chamadas HTTP) enquanto houver conexão WebSocket ativa, utilizando o canal de push em tempo real para disparar atualizações.
- **Coalescência de Requisições Ativas (*In-Flight Request Sharing*)**: O `SyncService.syncIndex()` compartilha a `Future` em trânsito entre chamadas simultâneas, impedindo disparos concorrentes duplicados de requisições de rede.
- **Debounce de Transição de Modos e Eventos Push**: Ouvintes de transição de modo em `main.dart` e ouvintes de Live Reload em `registrarOuvintesLiveReload` utilizam um debounce de 50ms para consolidar atualizações múltiplas em uma única sincronização atômica.

---

## Principais Classes e Responsabilidades

### `DatasetRepository`
- Singleton acessível via `DatasetRepository.instance`
- Notificadores reativos: `activeDataset`, `indiceData`, `notificadorCroquiAtualizado`, `homeResetTrigger`
- Converte os resumos do `Indice` Protobuf em instâncias fortemente tipadas de `ResumoPico` via `ExtensaoMetadadosIndice.paraResumoPico` e vincula entidades `Croqui`/`Pico` via `ExtratorMetadadosCroqui` (sem pré-carregar imagens de capa em disco durante a carga de metadados, delegando a resolução de mídias sob demanda ao `ProvedorImagemAresta`)
- **Reordenação em Memória e Reaproveitamento de Instâncias**: Em `updatePriorityAfterNavigation()`, persiste a ordem de acesso em `recent_picos.yaml` e reordena diretamente em memória as listas `picosBaixados` e `croquisBaixados` sem reconsultar o disco. Em `loadIndiceToMemory()` e `_refreshActiveDataset()`, paraleliza verificações de armazenamento local (`Future.wait`) e reaproveita instâncias de `Croqui` já desserializadas em memória para picos inalterados.
- **Tabela de Dispersão $O(1)$ de Mídias**: Mantém tabela de dispersão `_tabelaSha256PorPico` populada em `loadIndiceToMemory` e `getCroqui`, indexando hashes SHA-256 de miniaturas (`Indice.checksumSha256Thumbnail`) e mídias de croqui (`Croqui.arquivosExternos`). Expõe `obterSha256DaMidia(picoId, caminho)` e `indexarMidiasDoCroqui(picoId, croqui)` para invalidação reativa de cache de imagens sem varreduras lineares.
- **Hierarquia Estrita de Resolução de Croquis em 4 Etapas**: Em `getCroqui()`, resolve o binário sem recalcular hashes em tempo de execução nas etapas locais para poupar CPU e bateria:
  1. *RAM*: Consulta o `GerenciadorSessaoOnline` e `activeDataset.value?.picosBaixados`.
  2. *Downloads*: Consulta `GerenciadorArquivosLocais` procurando `compilado.binarypb` (com *lazy rename* do formato legado `<picoId>.binarypb`).
  3. *Cache Temporário*: Consulta `/temp_cache/<picoId>/compilado.binarypb.<sha256>`.
  4. *Rede (1 RTT Otimista)*: Quando o pico já consta no índice local em memória, baixa imediatamente via `ServicoCroquiOnline` com `?v=<checksum_local>` em **1 RTT** e só dispara `unawaited(syncAtivo.syncIndex())` silenciosamente em segundo plano se o download remoto obtiver sucesso (`croquiRemoto != null`) — evitando retentativas ociosas e notificações de `activeDataset` quando o dispositivo está offline. Quando o pico ainda não existe no índice local, aguarda `syncIndex()` de forma síncrona como fallback e aplica curto-circuito imediato (`return null`) caso resulte em `SyncStatus.offline`. O `ServicoCroquiOnline` calcula o SHA-256 real em memória na chegada do HTTP, grava atomicamente via `.tmp` para `compilado.binarypb.<sha256_real>` antes de expurgar versões antigas e, se offline, utiliza eventual versão anterior presente no `temp_cache` como fallback de emergência.

### `EditorDeCroqui`
- Singleton acessível via `EditorDeCroqui.instance`
- Notificadores: `editorUrl`, `isExperimentalMode`, `isDevModeEnabled`, `notificadorGatilhoRecarregamento`, `notificadorSessaoExpirada`
- `activeBaseUrl` retorna a URL correta para o modo ativo
- `EditorDeCroqui.isUrlExperimental(url)` identifica se uma URL pertence a uma sessão efêmera do Editor Desktop (`previa.arestaclimb.com`, IPs privados de LAN ou modo experimental ativo)
- `downloadsPath(docsPath)` e `indicePath(docsPath)` retornam os caminhos corretos por modo
- Gerencia o listener de WebSocket para Live Reload e emite `dispararPulsoRecarregamento()` ao receber atualizações, além de `notificarSessaoExperimentalExpirada()` quando a sessão do editor expira
- Persiste configuração em `editor_config.yaml`

### `BannerModoExperimental` (Widget Global)
- Exibido via `MaterialApp.builder` no topo de toda a árvore de navegação
- Apresenta o indicador textual limpo do modo experimental ativo sem contagem regressiva
- Fornece botão de saída rápida `[ SAIR ✕ ]` que aciona `nukeExperimentalData()`, restaura o índice oficial e redireciona para a raiz (`HomeNode`)
- Animação de pulso luminoso (300ms) reativa disparada quando o WebSocket recebe eventos de Hot Reload

### `SyncService` e `SyncIsolate`
- Orquestra toda a checagem Delta via API utilizando as variantes seladas de `FetchIndiceResult` (`IndiceUpdated`, `IndiceUnchanged`, `IndiceOffline`, `IndiceErroServidor`) retornadas por `SyncNetwork.fetchIndiceWithRetries`.
- Executa os processamentos pesados (SHA256, parseamento de arrays binários, escritas de dezenas de imagens no disco local e compactação) em background via Dart Isolates (`downloadIsolateMain`).
- **Padronização de Downloads e Limpeza de Resíduos**: Grava os dados do croqui permanentemente como `compilado.binarypb` (em substituição a `<picoId>.binarypb`) e remove resíduos de arquivos legados após a finalização atômica do commit no disco.
- **Reutilização de Cache Volátil (`temp_cache`)**: Ao realizar o download de croquis offline, o isolate recebe o caminho `tempCacheDirPath`. Caso uma mídia externa já tenha sido baixada previamente durante a navegação online sob demanda (persistida como `<temp_cache>/<picoId>/<caminho>.<hash>`), o isolate copia o arquivo localmente para o destino final via escrita atômica (`.tmp` seguido de renomeação), zerando requisições de rede redundantes para a CDN.
- Reflete o progresso percentual diretamente via `DatasetRepository.instance!.downloadingCrags`.
- Expõe `lastSyncWasAuto` e `quantidadeCroquisBaixadosAtualizadosNoUltimoSync` para controle fino de notificações de atualização de dados offline na abertura do aplicativo.
- No **Modo Experimental**, notificações intrusivas (SnackBar / toasts) são suprimidas para garantir atualização contínua e silenciosa enquanto o `BannerModoExperimental` pulsa visualmente.

### Módulo de In-App Feedback (`feedback/`)
- **`FeedbackQueueService`**: Gerencia a fila persistente local. Salva imagens no diretório temporário, cria o payload JSON no `SharedPreferences` com categoria `tipo_feedback` (`croqui` ou `app`) e agenda as rotinas de disparo em background (via Workmanager).
- **`OrquestradorFeedback` (`orquestrador_feedback.dart`)**: Tarefa executada em background pelo SO (independente se o app estiver aberto ou não). Despacha a fila de requisições pendentes via `multipart/form-data` para a Edge Function `app-feedback` no Supabase, anexando também os binários reais `indice.binarypb` e `compilado.binarypb` como `indice_file` e `croqui_file`. A Edge Function publica o relato como uma issue pública no repositório GitHub `aresta-climb/aresta_db` com etiquetagem automática por labels (`feedback:croqui/app`, `so:android/ios`, `pico:<id>`) e segrega dados confidenciais (UUIDs, modelo do aparelho e IP) na tabela restrita `feedback_diagnosticos` (RLS), gerando um link restrito para o Supabase Dashboard.
- **`FeedbackMetadataCollector`**: Coleta dados cruciais do dispositivo no momento do report (bateria, conectividade, versão do app, resolução e tema da UI, e estado atual do NavNode) e executa **Auditoria Criptográfica de Hashes sob demanda** (calculando SHA-256 do índice local, miniatura e croqui em visualização para rotular os estados como `INTEGRO`, `DIVERGENTE` ou `NAO_BAIXADO`).

---

## Navegação Online Sob Demanda (Clean Architecture)

A partir da versão atual, o usuário pode navegar livremente por qualquer croqui do catálogo sem ser obrigado a baixá-lo previamente para o dispositivo.

### Componentes Chave:
- **`ClienteHttpAresta` (`http/cliente_http_aresta.dart`)**: Cliente HTTP encapsulado e centralizado de todo o aplicativo. Mantém pool de conexões TCP/TLS persistente (*HTTP Keep-Alive* com `idleTimeout` de 120 segundos e `connectionTimeout` de 10 segundos). Possui construtor privado com apenas dois pontos de obtenção (`ClienteHttpAresta.instancia` em produção e `@visibleForTesting ClienteHttpAresta.paraTestes` em testes), omite deliberadamente o método `.close()` para impedir o encerramento acidental do pool compartilhado e isola `package:http/http.dart` do restante do código de produção (fiscalizado por `isolamento_cliente_http_test.dart`).
- **`GerenciadorSessaoOnline` (`dataset/sessao_online/`)**: Mantém instâncias de `Croqui` carregadas sob demanda em memória RAM (e cache volátil `/temp_cache`), atualizando reativamente o estado sem exigir downloads prévios.
- **`ServicoCroquiOnline` (`http/`)**: Baixa arquivos `.binarypb` leves sob demanda diretamente para a sessão volátil utilizando o `ClienteHttpAresta` compartilhado, calcula o SHA-256 real em memória na chegada do HTTP (prevenindo corrupção de nome de arquivo em *cache misses* da CDN por evicção LRU), grava atomicamente via `.tmp` para `compilado.binarypb.<sha256_real>` antes de expurgar versões antigas, oferece fallback offline para versões anteriores salvas em `/temp_cache`, suporta re-fetch com bypass de cache HTTP (`recarregarCroquiOnline`) e processa respostas HTTP 200 OK no polling periódico de ETag.
- **`ProvedorImagemAresta` (`widgets/provedor_imagem_aresta.dart`)**: Resolução de imagens em camadas com persistência em disco sob demanda:
  1. Armazenamento local permanente (`$downloadsRoot/<picoId>/<caminho>` ou thumbnails permanentes em `$downloadsRoot/thumbnails/<picoId>.webp`).
  2. Cache temporário volátil endereçado por conteúdo (`/temp_cache/<picoId>/<caminho>.<hash>` e `/temp_cache/thumbnails/<picoId>.webp.<hash>`).
  3. Download atômico da CDN com streaming, validação de integridade por checksum SHA-256 obrigatório, expurgo de versões antigas do mesmo arquivo com hashes divergentes, deduplicação de downloads concorrentes e persistência imediata em disco no `/temp_cache` (com fallback para `NetworkImage` sem persistência, emitindo `logError` quando o croqui está baixado offline ou `logAviso` durante navegação online caso o hash esteja ausente).
  4. Suporte a downsampling integrado via `ResizeImage.resizeIfNeeded` com `larguraAlvo`/`alturaAlvo` (padronizado em 300px para miniaturas de cartões e carrosséis).
- **Invalidação Reativa de Cache em Live Reload**: Ao receber eventos de recarregamento push via WebSocket, o aplicativo purga o cache de imagens do Flutter (`PaintingBinding.instance.imageCache.clear()` e `clearLiveImages()`), garantindo a substituição visual instantânea de texturas na GPU sem necessidade de desempilhar ou reabrir telas, tanto para croquis baixados quanto para croquis em sessão online.
- **Guardião de Saída & Banner Online**: Componentes de UI (`BannerModoOnline`, `ModalConfirmacaoSaida`) que garantem que o usuário saiba que está online e possa salvar o croqui offline antes de ir para a pedra com recarregamento contínuo em tempo real.
- **Notificações Reativas Simétricas**: No modo experimental, a recarga por WebSocket ou ETag é seamless com animação no `BannerModoExperimental`; fora do modo experimental, a interface exibe um aviso amigável via `SnackBar` informando que o guia do pico foi atualizado.
- **`GerenciadorNotificacaoDownload` (`notificacoes/gerenciador_notificacao_download.dart`)**: Gestão de notificações nativas na barra de status do sistema operacional. No Android, ancora a execução a um Foreground Service nativo ininterrupto com notificação contínua sticky (`ongoing: true`), barra de progresso e ícone principal `@mipmap/ic_launcher` (`anydpi-v26`, garantido no APK base sem depender de recursos de densidade em Split APKs), transitando atomicamente para uma notificação dispensável de sucesso/erro. No iOS, emite a notificação nativa ao concluir o salvamento.
- **`AppLogger` e Crash Reporting (`firebase/app_logger.dart`)**: Falhas graves de integridade no pipeline de download offline e sincronização de índice (como divergência de checksum SHA-256 ou HTTP 404/500 na CDN oficial `serving.arestaclimb.com`) são tratadas no Crashlytics. Já erros HTTP originados de sessões efêmeras do Editor Desktop (`EditorDeCroqui.isUrlExperimental(url) == true`, como `previa.arestaclimb.com` ou LAN local) são registrados apenas como `logAviso` (breadcrumb) em `SyncNetwork`, evitando alertas falsos quando o autor encerra o editor. Para evitar falsos positivos quando o escalador estiver sem conexão na rocha (`SocketException`, `ClientException`, `TimeoutException` ou HTTP `502/503/504/429`), apenas a camada que possui o objeto `error` original (`ServicoCroquiOnline.carregarCroquiRemoto` e `SyncService.tratarErroDownloadIsolate`) invoca `logFalhaSyncOuDownload`, enquanto orquestradores de nível superior (`handlePicoSelection`, `SyncService.downloadCrag` e `ServicoDownloadSegundoPlano.executarDownload`) registram o encerramento sem sucesso como breadcrumb (`logAviso`).
- **`TelemetryService` e Analytics (`firebase/telemetria.dart`)**: Rastreamento de telemetria analítica com taxonomia padronizada em português via GA4:
  - *Deep Links & QR Codes*: `logDeepLinkAberto` captura parâmetros de rota, tipo de inicialização (`cold_start`/`warm_start`), status de sucesso/falha e dimensões UTM (`utm_source`, `utm_medium`, `utm_campaign`, etc.).
  - *Índice de Escaladas*: `logAcaoIndiceEscaladas` instrumenta alternância de abas de modalidade e aplicação de filtros dinâmicos de graduação (`filtrar_grau`), setor (`filtrar_setor`), conquistadores (`filtrar_conquistador`), clássicas (`filtrar_classicas`) e limpeza (`limpar_filtros`) com valores no parâmetro `detalhe`.
  - *Pico Hub e Subpáginas*: `logNavegacaoPicoHub` para os cards centrais (Setores, Explorar Local, Regras, Comunidade, Créditos, Índice) e `logApoioPix` para cópia de chave PIX em Apoie o Pico.
  - *Guardião de Saída e Banner*: `logAcaoGuardiaoSaida` e `logSalvarOfflineBanner` para monitorar a conversão de salvamento offline antes de ir à pedra.
  - *Interações Gerais*: `logAcaoBetaAberto` para o modal de beta, `logLinkExterno` para abertura de redes sociais e referências de desenvolvedores, e `logAlterarOrdenacao` para alternância de ordenação de listas em setores, grupos e catálogo.
  - *Registro de Primeira Visita*: `RegistroPrimeiraVisita` (`registro_primeira_visita.dart`) gerencia a persistência de croquis já visitados pelo usuário para enriquecer o evento `abrir_croqui`.

## Manutenção e Debug

- Falhas no pipeline de download offline ou no Isolate são sinalizadas com `🛑 [SyncIsolate]`, `🛑 [SyncService]` ou `💥 [AppLogger CRASH]`.
- Monitore os logs com o prefixo `[EditorConfig]` para eventos do temporizador e Nuke.
- Logs com `[DatasetRepo]` mostram verificações de download e caminhos de arquivo.
- Logs com `[LiveReload]` mostram conexões e eventos push recebidos pelo servidor de desenvolvimento.
- O banner vermelho global `BannerModoExperimental` é injetado via `MaterialApp.builder` para persistir em todas as telas.
- O estado de **Developer Mode** persiste no disco; os **Dados Experimentais** não persistem entre sessões.

---

## Controle de Recursos em Desenvolvimento (Feature Flags & Chaves de Acesso)

Para garantir que funcionalidades em desenvolvimento (como o **Perfil do Escalador** e a **Caderneta Esportiva**) não fiquem expostas prematuramente em compilações de produção e versões de release, o acesso é protegido por flags de compilação gerenciadas pela classe `ConfiguracaoRecursos` (`configuracao_recursos.dart`).

### Comportamento Padrão (Produção / Release)
Em qualquer compilação ou execução convencional (`flutter build apk --release`, `flutter run`) onde nenhuma chave ou flag for explicitamente informada:
- `ConfiguracaoRecursos.perfilHabilitado` avalia como `false`.
- O botão de Perfil (`btn_home_perfil`) na AppBar da Home (`ArestaHomeAppBar`) permanece oculto.
- O cartão e o botão de registro de ascensão/cadena (`btn_registrar_cadena`) na tela da via (`via_functions.dart`) permanecem ocultos.
- Tentativas programáticas ou diretas de navegação via `AppNav.toPerfil` são bloqueadas silenciosamente.

### Como Desbloquear Recursos em Desenvolvimento
Desenvolvedores e testadores podem liberar o acesso completo aos recursos durante a execução ou build passando flags via `--dart-define`:

```bash
# Opção 1: Via chave de API / Segredo (conforme exemplo em desenvolvimento)
flutter run --dart-define=API_KEY=my_secret_key --dart-define=APP_MODE=production

# Opção 2: Via chave específica de acesso ao perfil
flutter run --dart-define=CHAVE_ACESSO_PERFIL=aresta_segredo_perfil_2026

# Opção 3: Via flag booleana direta
flutter run --dart-define=HABILITAR_PERFIL=true
```

### Chaves Secretas Autorizadas
O sistema reconhece o seguinte conjunto de chaves padronizadas:
- `my_secret_key`
- `aresta_segredo_perfil_2026`
- `minha_chave_secreta`
- `aresta_dev_secret`

### Testes Automatizados
Para testes unitários e de widget, a classe provê métodos estáticos com a anotação `@visibleForTesting`:
- `ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true)`: Força o estado habilitado.
- `ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(false)`: Força o estado desabilitado.
- `ConfiguracaoRecursos.redefinirParaTestes()`: Restaura o estado original derivado do ambiente.

