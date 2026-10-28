# Design

## Context

Veja `proposal.md` para a motivação completa. Atualmente:
1. `AndroidManifest.xml` define `android:launchMode="singleTop"` na `MainActivity` e `styles.xml` define `NormalTheme` com `@android:color/white` (`#FFFFFF`). Quando o aplicativo está em segundo plano e recebe um intent `ACTION_VIEW` (ou quando a `SurfaceView` do Flutter é recriada ao retomar do background), o sistema operacional ou exibe uma nova instância da `MainActivity` com `LaunchTheme` branco, ou revela por 1 a 2 frames o fundo `#FFFFFF` do `NormalTheme` antes do motor gráfico do Flutter pintar o tema escuro (`#181312` `deepBasalt`).
2. Em `main.dart`, a saída da `TelaSplashInicial` para o `TreeNavigationWrapper` ocorre por substituição direta na árvore de widgets sem transição de opacidade.
3. O projeto já possui `firebase_performance: ^0.12.1` listado no `pubspec.yaml`, mas ainda não inicializa nem utiliza o `FirebasePerformance`, e o teste arquitetural `test/architecture/firebase_isolation_test.dart` exige estritamente que nenhum arquivo fora de `lib/services/firebase/` importe pacotes `firebase_*`.
4. O usuário analisa métricas operacionais e de produto no **Looker Studio** conectado ao Google Analytics 4 (GA4 / BigQuery), além do console do **Firebase Performance**. Enquanto o Firebase Performance calcula automaticamente percentis (P50, P90, P99) por atributo no console do Firebase, a integração nativa do Looker Studio consome os eventos do GA4 — portanto, precisamos de **dupla emissão** (Trace no Firebase Performance + parâmetro numérico `duracao_ms` com atributos de fatiamento nos eventos do `TelemetryService`).

## Goals / Non-Goals

**Goals:**
- Eliminar 100% da piscada branca em retomadas de segundo plano (*Warm Start* / *Hot Start*), com 0% de impacto visual na primeira abertura a frio (*Cold Start*).
- Suavizar a transição de saída da `TelaSplashInicial` no *Cold Start* com fade de ~250ms (`AnimatedSwitcher`).
- Garantir bloqueio estrito de coleta de telemetria de performance quando `kDebugMode == true` (`setPerformanceCollectionEnabled(false)` e não-envio ao Firebase/GA4 em modo debug).
- Criar `ServicoPerformance` em `lib/services/firebase/performance_telemetria.dart` (com espelhamento 1:1 em `test/services/firebase/performance_telemetria_test.dart`) encapsulando `FirebasePerformance` e coordenando a dupla emissão com `TelemetryService`.
- Medir as 8 métricas de performance até a interatividade real da página (`WidgetsBinding.instance.addPostFrameCallback` ou decodificação do primeiro frame da imagem em `MapaInterativoPage`), expondo os metadados necessários de resolução (`modo_acesso` no `DatasetRepository` e `origem_imagem` no `ProvedorImagemAresta`).

**Non-Goals:**
- Alterar a cor branca (`#FFFFFF`) da splash screen de *Cold Start*.
- Criar painéis externos no Looker Studio (este design garante que todos os eventos e parâmetros cheguem estruturados ao GA4 e ao Firebase Performance).

## Decisions

### 1. Arquitetura em 3 Camadas para Eliminação do Flash Branco e Transição da Splash
- **Camada 1 (`android:launchMode="singleTask"` no `AndroidManifest.xml`)**:
  - *Por quê*: Com `singleTop`, se o usuário tiver acionado qualquer `Activity` secundária (como o folha de compartilhamento nativo `SharePlus`, navegador Custom Tabs ou seletor de arquivos) ou se o intent `ACTION_VIEW` vier de outra tarefa, o Android cria uma segunda instância da `MainActivity`, disparando todo o ciclo de `LaunchTheme` branco e `TelaSplashInicial`. Com `singleTask`, o Android garante instância única da `MainActivity` e entrega o intent diretamente em `onNewIntent` para o plugin `app_links` (`uriLinkStream`).
- **Camada 2 (`onStop()` em `MainActivity.kt` aplicando `#181312`)**:
  - *Por quê*: Não podemos colocar `#181312` estaticamente no `NormalTheme` do `styles.xml` porque no *Cold Start* o Android aplica o `NormalTheme` assim que a `SplashScreen` nativa começa a sair, antes do primeiro frame do Flutter (`TelaSplashInicial`), o que causaria um flash escuro entre duas telas brancas. Ao sobrescrever `onStop()` na `MainActivity` para executar `window.setBackgroundDrawable(ColorDrawable(0xFF181312.toInt()))`, garantimos matematicamente que:
    1. No *Cold Start* (`onCreate` ➔ `onStart` ➔ `onResume`), `onStop()` ainda não rodou, logo a janela permanece `#FFFFFF`.
    2. Assim que o app vai para o background pela primeira vez (`onStop()`), a janela nativa passa a ser `#181312` (`deepBasalt`), de modo que qualquer *Warm Start* subsequente (`onRestart` ➔ `onStart` ➔ `onResume`) ocorre sobre fundo escuro idêntico ao tema do aplicativo.
- **Camada 3B (`AnimatedSwitcher` em `main.dart`)**:
  - *Por quê*: Substituir o `if (exibindoSplash) return const TelaSplashInicial();` por um `AnimatedSwitcher(duration: const Duration(milliseconds: 250), switchInCurve: Curves.easeOut, switchOutCurve: Curves.easeIn, ...)` dentro do `ValueListenableBuilder<bool>(valueListenable: exibindoSplashInicial)` cria um *cross-fade* suave entre a splash clara e o app escuro quando o bootstrap termina, sem atrasar a interatividade.

### 2. Isolamento de `ServicoPerformance` em `lib/services/firebase/performance_telemetria.dart` e Bloqueio em Debug
- **Decisão**: Criar `ServicoPerformance` dentro de `lib/services/firebase/performance_telemetria.dart` e inicializá-lo em `initFirebase()` (`lib/services/firebase/inicializar_firebase.dart`).
- **Racional**:
  - Cumpre a regra arquitetural verificada por `test/architecture/firebase_isolation_test.dart` (nenhum import de `package:firebase_performance` fora de `lib/services/firebase/`).
  - Durante `ServicoPerformance.instance.inicializar({bool? isDebugMode, FirebasePerformance? performanceInstance})`, calculamos `final emDebug = isDebugMode ?? kDebugMode;` e chamamos `await performance.setPerformanceCollectionEnabled(!emDebug);`.
  - Além de desabilitar o SDK nativo em modo debug, `ServicoPerformance` mantém a flag `_coletaAtiva = !emDebug`: quando `_coletaAtiva` é `false`, os métodos de medição continuam executando o `Stopwatch` e registrando o log informativo via `AppLogger.instance.logInfo('⏱️ [Performance] ...')` (facilitando inspeção local pelo desenvolvedor), mas **não** criam traces nativas nem despacham eventos de performance para o GA4.
  - Em `TelemetryService._logEvent`, também respeitamos o bloqueio em modo debug para não trafegar eventos analíticos de desenvolvimento quando `isDebug` estiver ativo.

### 3. Medição até a Interatividade Real (`Time to Interactive`) via `aguardarProximoFrame`
- **Decisão**: Para todas as métricas de abertura de tela (métricas 1, 2, 3, 6 e 7), o cronômetro (`Stopwatch`) inicia no instante do gatilho da ação e só é encerrado dentro de `WidgetsBinding.instance.addPostFrameCallback((_) { ... })` agendado **após** a mudança de estado de navegação (`AppNav.to...` ou `exibindoSplashInicial.value = false`).
- **Racional**: Medir apenas o retorno da função assíncrona (`getCroqui` ou `resolverDestinoInicialColdStart`) ignora o tempo de construção da árvore de widgets (`build`), layout e pintura (`paint`) do primeiro frame da página de destino. O `addPostFrameCallback` garante que o tempo reportado corresponde ao momento em que a página já está visível e pronta para receber toques do usuário.
- **Caso Especial — Mapa Interativo (Métrica 8)**: Em `MapaInterativoPage`, o primeiro frame do widget exibe apenas o `CircularProgressIndicator` enquanto `ProvedorImagemAresta.resolver` busca o `.webp` e o motor do Flutter decodifica os bytes da imagem. Portanto, para `abrir_mapa_interativo`, o cronômetro inicia no carregamento do mapa (`_carregarImagemMapa`) e só encerra quando o `frameBuilder` do widget `Image` recebe `frame != null` pela primeira vez (momento em que o mapa `.webp` está efetivamente pintado na tela).

### 4. Rastreamento da Camada de Resolução (`modo_acesso` e `origem_imagem`) para Fatiamento (*Slicing*)
- **Em `DatasetRepository` (`lib/services/repositorio_dataset.dart`)**:
  - Definiremos um enum/constantes em português `OrigemResolucaoCroqui` (`memoria`, `offline`, `temp_cache`, `cdn_online`) e registraremos em um mapa interno `final Map<String, String> _ultimaOrigemResolucaoPorPico = {};` qual das 4 etapas de `getCroqui(String id)` respondeu à solicitação, expondo `String? obterUltimaOrigemResolucao(String id)`.
  - Isso mantém 100% de compatibilidade com a assinatura atual `Future<Croqui?> getCroqui(String id, {bool allowOnline = false})` e permite que `handlePicoSelection`, `DeepLinkNavigatorService` e `resolverDestinoInicialColdStart` consultem imediatamente a camada real que serviu o croqui (`memoria`, `offline`, `temp_cache` ou `cdn_online`).
- **Em `ProvedorImagemAresta` (`lib/services/imagens/provedor_imagem_aresta.dart`)**:
  - Registraremos a origem da imagem resolvida (`downloads`, `temp_cache` ou `cdn_remoto`) acessível via `ProvedorImagemAresta.obterUltimaOrigemImagem(String caminhoRelativo)` (ou método equivalente), permitindo que `MapaInterativoPage` reporte `origem_imagem` com precisão sem quebrar os chamadores existentes de `ProvedorImagemAresta.resolver(...)`.
- **Em `SyncService` (`lib/services/sincronizacao.dart`)**:
  - Na Fase 1 de `syncIndex()`, rastrearemos o resultado HTTP da verificação do índice (`'304'`, `'200'`, `'offline'` ou `'erro'`), a origem (`isManual ? 'manual' : 'auto'`) e o modo (`isExperimental ? 'experimental' : 'oficial'`), registrando a medição no bloco `finally` da Fase 1.
  - Na Fase 2 (`_executarAtualizacaoMidiasEmSegundoPlano`), mediremos do início da tarefa em background até o término do commit atômico dos arquivos `.tmp`, reportando `teve_atualizacao`, `qtd_picos_atualizados` e `qtd_thumbs`.

### 5. Contrato de Dupla Emissão (Firebase Performance + GA4 / Looker Studio)

| # | Nome da Trace (Firebase Performance) | Evento GA4 (`TelemetryService`) | Parâmetros / Atributos de Fatiamento (*Slicing*) |
|---|---|---|---|
| 1 | `cold_start_home` | `performance_abertura_app` | `duracao_ms` (int), `tipo_start: 'cold_start'`, `destino: 'home'` |
| 2 | `cold_start_deep_link` | `deep_link_aberto` | `duracao_ms` (int), `tipo_start: 'cold_start'`, `destino`, `modo_acesso`, `abrir_mapa`, `sucesso` |
| 3 | `warm_start_deep_link` | `deep_link_aberto` | `duracao_ms` (int), `tipo_start: 'warm_start'`, `destino`, `modo_acesso`, `abrir_mapa`, `sucesso` |
| 4 | `sync_index_fase1` | `performance_sync_index` | `duracao_ms` (int), `fase: 'fase1_indice_catalogo'`, `status_http` (`304`/`200`/`offline`/`erro`), `origem` (`auto`/`manual`), `modo` (`oficial`/`experimental`) |
| 5 | `sync_index_fase2` | `performance_sync_index` | `duracao_ms` (int), `fase: 'fase2_midias_background'`, `teve_atualizacao` (`true`/`false`), `qtd_picos_atualizados` (int), `qtd_thumbs` (int) |
| 6 | `abrir_croqui` | `acao_croqui` (`acao: 'abrir_croqui'`) | `duracao_ms` (int), `id_croqui`, `modo_acesso` (`memoria`/`offline`/`temp_cache`/`cdn_online`), `origem`, `primeira_visita` |
| 7 | `navegacao_interna_croqui` | `abrir_setor` / `abrir_grupo` / `acao_escalada` | `duracao_ms` (int), `id_croqui`, `destino` (`setor`/`grupo`/`via`), `modo_acesso` (`offline`/`online`) |
| 8 | `abrir_mapa_interativo` | `abrir_mapa` | `duracao_ms` (int), `id_croqui`, `nome_setor`, `modo_acesso` (`offline`/`online`), `origem_imagem` (`downloads`/`temp_cache`/`cdn_remoto`) |

## Risks / Trade-offs

- **[Risk] Limite de tamanho de nomes e atributos no Firebase Performance (máx. 32 caracteres para nome de trace, 40 para chave de atributo, 100 para valor)** → **Mitigação**: Todos os nomes de traces (`cold_start_home`, `cold_start_deep_link`, `warm_start_deep_link`, `sync_index_fase1`, `sync_index_fase2`, `abrir_croqui`, `navegacao_interna_croqui`, `abrir_mapa_interativo`) possuem no máximo 24 caracteres, e `ServicoPerformance` truncará preventivamente valores de atributos que excedam 100 caracteres antes de chamar `putAttribute`.
- **[Risk] Múltiplas chamadas de `frameBuilder` durante o carregamento da imagem em `MapaInterativoPage`** → **Mitigação**: Usar uma flag booleana `_telemetriaMapaRegistrada` por caminho de imagem (`_currentMapPath`) em `MapaInterativoPageState`, garantindo que a medição de `abrir_mapa_interativo` seja disparada exatamente uma única vez no primeiro frame em que `frame != null`, e reiniciada apenas se o usuário trocar de mapa no carrossel.
- **[Risk] Execução de `WidgetsBinding.instance.addPostFrameCallback` em testes unitários sem árvore de widgets bombeada** → **Mitigação**: Encapsular o agendamento pós-frame em `ServicoPerformance.aguardarProximoFrame()`, que agenda `SchedulerBinding.instance.addPostFrameCallback` quando há frame ativo/agendado ou permite conclusão determinística em testes unitários puros.
