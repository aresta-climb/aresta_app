# Documentação de Serviços — Aresta Climb

Este diretório contém a lógica de negócios e os serviços centrais do aplicativo. A arquitetura é construída com princípios de Clean Architecture e separação de responsabilidades, suportando tanto o modo de produção oficial quanto o modo experimental de Live Reload para editores.

---

## Arquivos

| Arquivo / Pasta | Responsabilidade |
|---|---|
| `dataset_repository.dart` | Fachada e gerenciador de estado central: downloads, índice, metadados e prioridade |
| `dataset/` | Submódulos desacoplados de responsabilidade única (`modelos/`, `armazenamento/`, `metadados/`, `sessao_online/`) |
| `editor_croqui.dart` | Controle de contexto: modo ativo, caminhos de diretório, temporizador experimental |
| `http/` | Módulo de rede e sincronização (downloads, atualizações OTA, `ServicoCroquiOnline`, `ServicoDownloadSegundoPlano`) |
| `notificacoes/` | Gerenciamento de notificações nativas de download (`GerenciadorNotificacaoDownload`) com suporte a Foreground Services e progresso contínuo |
| `firebase/` | Diretório isolado contendo toda integração com Firebase (Analytics, Crashlytics, Remote Config) |
| `feedback/` | Gerenciamento de envio de In-App Feedbacks via fila local (SharedPreferences) e despacho assíncrono em background (Workmanager) para o Supabase |

---

## Modo Experimental & Live Reload — Ciclo de Vida

O Modo Experimental permite testar croquis e alterações em tempo real diretamente do Editor Desktop via WebSocket e Live Reload.

### Acesso e Segurança

- **Easter Egg**: As opções de desenvolvedor ficam ocultas. O usuário precisa tocar **7 vezes seguidas** no ícone de status da página de Configurações para desbloqueá-las.
- **Sem Limite de Tempo**: O modo experimental permanece ativo durante toda a sessão de uso no aplicativo, sem contagem regressiva ou auto-destruição automática.
- **Sessão Volátil (Nuke on Startup)**: Para garantir a integridade da base oficial e evitar que o usuário fique preso em dados de teste desatualizados, todos os dados experimentais são limpos automaticamente quando o app é fechado e reaberto do zero.

### Isolamento de Dados

O `EditorDeCroqui` gerencia dois contextos de armazenamento isolados:

| Contexto | URL base | Diretório de índice | Diretório de downloads |
|---|---|---|---|
| **Oficial** | `https://aresta-climb.github.io/aresta_serving` | `<docs>/indice.binarypb` | `<docs>/downloads/` |
| **Experimental** | URL de Prévia / Live Reload do Editor | `<docs>/editor/experimental/indice.binarypb` | `<docs>/editor/experimental/downloads/` |

### Fluxo de Conexão com Editor Desktop

1. O usuário digita o código de 8 caracteres ou escaneia o QR Code gerado no Editor Desktop.
2. O app realiza a resolução híbrida (Smart LAN-First com fallback para Cloudflare Relay).
3. Conexão WebSocket para escuta de eventos `live_reload` em tempo real.
4. O `SyncService` sincroniza o índice e dados atualizados instantaneamente.

---

## Principais Classes e Responsabilidades

### `DatasetRepository`
- Singleton acessível via `DatasetRepository.instance`
- Notificadores reativos: `activeDataset`, `syncStatus`, `downloadingCrags`, `homeResetTrigger`
- Converte Protobuf em `Map<String, dynamic>` para consumo pela UI
- Gerencia `recent_picos.yaml` para ordenação por prioridade
- **Tabela de Dispersão $O(1)$ de Mídias**: Mantém tabela de dispersão `_tabelaSha256PorPico` populada em `loadIndiceToMemory` e `getCroqui`, indexando hashes SHA-256 de miniaturas (`Indice.checksumSha256Thumbnail`) e mídias de croqui (`Croqui.arquivosExternos`). Expõe `obterSha256DaMidia(picoId, caminho)` e `indexarMidiasDoCroqui(picoId, croqui)` para invalidação reativa de cache de imagens sem varreduras lineares.
- **Hierarquia Estrita de Resolução de Croquis em 4 Etapas**: Em `getCroqui()`, resolve o binário sem recalcular hashes em tempo de execução para poupar CPU e bateria:
  1. *RAM*: Consulta o `GerenciadorSessaoOnline`.
  2. *Downloads*: Consulta `GerenciadorArquivosLocais` procurando `compilado.binarypb` (com *lazy rename* do formato legado `<picoId>.binarypb`).
  3. *Cache Temporário*: Consulta `/temp_cache/<picoId>/compilado.binarypb.<sha256>`.
  4. *Rede*: Baixa via `ServicoCroquiOnline` com URL contendo cache-busting mandatório (`?v=<sha256>`), salvando em `temp_cache` e expurgando versões divergentes de execuções anteriores.

### `EditorDeCroqui`
- Singleton acessível via `EditorDeCroqui.instance`
- Notificadores: `editorUrl`, `isExperimentalMode`, `isDevModeEnabled`, `notificadorGatilhoRecarregamento`
- `activeBaseUrl` retorna a URL correta para o modo ativo
- `downloadsPath(docsPath)` e `indicePath(docsPath)` retornam os caminhos corretos por modo
- Gerencia o listener de WebSocket para Live Reload e emite `dispararPulsoRecarregamento()` ao receber atualizações
- Persiste configuração em `editor_config.yaml`

### `BannerModoExperimental` (Widget Global)
- Exibido via `MaterialApp.builder` no topo de toda a árvore de navegação
- Apresenta o indicador textual limpo do modo experimental ativo sem contagem regressiva
- Fornece botão de saída rápida `[ SAIR ✕ ]` que aciona `nukeExperimentalData()`, restaura o índice oficial e redireciona para a raiz (`HomeNode`)
- Animação de pulso luminoso (300ms) reativa disparada quando o WebSocket recebe eventos de Hot Reload

### `SyncService` e `SyncIsolate`
- Orquestra toda a checagem Delta via API.
- Executa os processamentos pesados (SHA256, parseamento de arrays binários, escritas de dezenas de imagens no disco local e compactação) em background via Dart Isolates (`downloadIsolateMain`).
- **Padronização de Downloads e Limpeza de Resíduos**: Grava os dados do croqui permanentemente como `compilado.binarypb` (em substituição a `<picoId>.binarypb`) e remove resíduos de arquivos legados após a finalização atômica do commit no disco.
- **Reutilização de Cache Volátil (`temp_cache`)**: Ao realizar o download de croquis offline, o isolate recebe o caminho `tempCacheDirPath`. Caso uma mídia externa já tenha sido baixada previamente durante a navegação online sob demanda (persistida como `<temp_cache>/<picoId>/<caminho>.<hash>`), o isolate copia o arquivo localmente para o destino final via escrita atômica (`.tmp` seguido de renomeação), zerando requisições de rede redundantes para a CDN.
- Reflete o progresso percentual diretamente via `DatasetRepository.instance!.downloadingCrags`.
- Expõe `lastSyncWasAuto` e `quantidadeCroquisBaixadosAtualizadosNoUltimoSync` para controle fino de notificações de atualização de dados offline na abertura do aplicativo.
- No **Modo Experimental**, notificações intrusivas (SnackBar / toasts) são suprimidas para garantir atualização contínua e silenciosa enquanto o `BannerModoExperimental` pulsa visualmente.

### Módulo de In-App Feedback (`feedback/`)
- **`FeedbackQueueService`**: Gerencia a fila persistente local. Salva imagens no diretório temporário, cria o payload JSON no `SharedPreferences` e agenda as rotinas de disparo em background (via Workmanager).
- **`FeedbackOrchestrator`**: Tarefa executada em background pelo SO (independente se o app estiver aberto ou não). Despacha a fila de requisições pendentes via `multipart/form-data` para o Supabase (Edge Functions), anexando também os binários reais `indice.binarypb` e `compilado.binarypb` como `indice_file` e `croqui_file` para download imediato pela equipe de engenharia no Discord.
- **`FeedbackMetadataCollector`**: Coleta dados cruciais do dispositivo no momento do report (bateria, conectividade, versão do app, resolução e tema da UI, e estado atual do NavNode) e executa **Auditoria Criptográfica de Hashes sob demanda** (calculando SHA-256 do índice local, miniatura e croqui em visualização para rotular os estados como `INTEGRO`, `DIVERGENTE` ou `NAO_BAIXADO`).

---

## Navegação Online Sob Demanda (Clean Architecture)

A partir da versão atual, o usuário pode navegar livremente por qualquer croqui do catálogo sem ser obrigado a baixá-lo previamente para o dispositivo.

### Componentes Chave:
- **`GerenciadorSessaoOnline` (`dataset/sessao_online/`)**: Mantém instâncias de `Croqui` carregadas sob demanda em memória RAM (e cache volátil `/temp_cache`), atualizando reativamente o estado sem exigir downloads prévios.
- **`ServicoCroquiOnline` (`http/`)**: Baixa arquivos `.binarypb` leves sob demanda diretamente para a sessão volátil, suporta re-fetch com bypass de cache HTTP (`recarregarCroquiOnline`) e processa respostas HTTP 200 OK no polling periódico de ETag, integrando-se diretamente ao ciclo de Live Reload.
- **`ProvedorImagemAresta` (`widgets/provedor_imagem_aresta.dart`)**: Resolução de imagens em camadas com persistência em disco sob demanda:
  1. Armazenamento local permanente (`/downloads` ou thumbnails permanentes em `/thumbnails/<picoId>.webp`).
  2. Cache temporário volátil endereçado por conteúdo (`/temp_cache/<picoId>/<caminho>.<hash>` e `/temp_cache/thumbnails/<picoId>.webp.<hash>`).
  3. Download atômico da CDN com streaming, validação de integridade por checksum SHA-256 obrigatório, expurgo de versões antigas do mesmo arquivo com hashes divergentes, deduplicação de downloads concorrentes e persistência imediata em disco no `/temp_cache` (com fallback para `NetworkImage` sem persistência e log de erro no `AppLogger` caso o hash esteja ausente).
  4. Suporte a downsampling integrado via `ResizeImage.resizeIfNeeded` com `larguraAlvo`/`alturaAlvo` (padronizado em 300px para miniaturas de cartões e carrosséis).
- **Invalidação Reativa de Cache em Live Reload**: Ao receber eventos de recarregamento push via WebSocket, o aplicativo purga o cache de imagens do Flutter (`PaintingBinding.instance.imageCache.clear()` e `clearLiveImages()`), garantindo a substituição visual instantânea de texturas na GPU sem necessidade de desempilhar ou reabrir telas, tanto para croquis baixados quanto para croquis em sessão online.
- **Guardião de Saída & Banner Online**: Componentes de UI (`BannerModoOnline`, `ModalConfirmacaoSaida`) que garantem que o usuário saiba que está online e possa salvar o croqui offline antes de ir para a pedra com recarregamento contínuo em tempo real.
- **Notificações Reativas Simétricas**: No modo experimental, a recarga por WebSocket ou ETag é seamless com animação no `BannerModoExperimental`; fora do modo experimental, a interface exibe um aviso amigável via `SnackBar` informando que o guia do pico foi atualizado.
- **`GerenciadorNotificacaoDownload` (`notificacoes/gerenciador_notificacao_download.dart`)**: Gestão de notificações nativas na barra de status do sistema operacional. No Android, ancora a execução a um Foreground Service nativo ininterrupto com notificação contínua sticky (`ongoing: true`) e barra de progresso, transitando atomicamente para uma notificação dispensável de sucesso/erro. No iOS, emite a notificação nativa ao concluir o salvamento.
- **`AppLogger` e Crash Reporting (`firebase/app_logger.dart`)**: Falhas graves no pipeline de download offline e sincronização de índice são tratadas com a mesma seriedade de um crash (`logCrash`, `fatal: true`), impactando imediatamente as métricas de estabilidade no Firebase Crashlytics e disparando alertas para a equipe de desenvolvimento.
- **`TelemetryService` e Analytics (`firebase/telemetry_service.dart`)**: Rastreamento de telemetria analítica com taxonomia padronizada em português via GA4:
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
