# Proposal

## Why

Ao retomar o aplicativo já aberto em segundo plano (*Warm Start*), especialmente via Deep Links externos (`ACTION_VIEW`), o usuário sofre uma piscada branca abrupta antes de visualizar o croqui ou tela em tema escuro (`#181312`), causada tanto pelo `android:launchMode="singleTop"` (que instancia uma segunda `MainActivity` com `LaunchTheme` branco quando outra atividade está no topo da tarefa) quanto pelo fundo branco remanescente da janela nativa Android durante a recriação da `SurfaceView`. Além disso, a transição de saída da `TelaSplashInicial` no *Cold Start* ocorre em corte seco, e o aplicativo ainda não coleta métricas de performance ponta a ponta (*Time to Interactive*) que permitam medir e fatiar (no Firebase Performance e no Looker Studio via GA4) os tempos reais de inicialização, sincronização em duas fases, abertura de croquis, navegação interna e renderização de mapas interativos exclusivamente em builds fora do modo debug.

## What Changes

- **Eliminação da Piscada Branca no Warm Start e Transição Suave da Splash (3 Camadas)**:
  - **Camada 1 (`AndroidManifest.xml`)**: Alterar `android:launchMode="singleTop"` para `android:launchMode="singleTask"` na `MainActivity`, garantindo que qualquer intent `ACTION_VIEW` recebido com o aplicativo em segundo plano reutilize a instância única existente via `onNewIntent` sem criar uma segunda atividade nem reexibir a splash branca.
  - **Camada 2 (`MainActivity.kt`)**: Sobrescrever `onStop()` na `MainActivity` para alterar o fundo da janela nativa (`window.setBackgroundDrawable`) para `#181312` (`deepBasalt`), mantendo 0% de impacto na primeira abertura a frio (*Cold Start* continua `#FFFFFF` até a splash sair) e eliminando qualquer flash branco ao restaurar a `SurfaceView` do Flutter em reaberturas (*Warm/Hot Start*).
  - **Camada 3B (`main.dart`)**: Envolver a transição entre `TelaSplashInicial` e `TreeNavigationWrapper` em um `AnimatedSwitcher` (~250ms com `Curves.easeOut`), suavizando a saída da splash branca para o tema escuro no *Cold Start*.
- **Telemetria Abrangente de Performance até a Interatividade Real (`Time to Interactive`)**:
  - **Bloqueio Estrito em Modo Debug**: Desativar explicitamente a coleta do Firebase Performance em modo debug (`FirebasePerformance.instance.setPerformanceCollectionEnabled(!isDebug)`) durante a inicialização do Firebase e garantir que, quando `kDebugMode` for `true`, o serviço de performance registre os tempos apenas no console (`AppLogger`) sem enviar traces ou eventos ao Firebase/GA4.
  - **Dupla Emissão (Firebase Performance + GA4 / Looker Studio) Isolada em `lib/services/firebase/`**: Criar o serviço modular de telemetria de performance dentro de `lib/services/firebase/` que registra simultaneamente *Custom Traces* no `FirebasePerformance` (para análise de percentis P50/P90/P99 no console do Firebase) e eventos/parâmetros `duracao_ms` com atributos de fatiamento (*slicing*) no `TelemetryService` (GA4), permitindo cruzar todas as métricas no Looker Studio.
  - **8 Métricas de Performance Ponta a Ponta (medidas até o frame pós-renderização / página pronta para uso)**:
    1. **Cold Start ➔ Home (`cold_start_home` / `performance_abertura_app`)**: Da entrada em `main()` até o `addPostFrameCallback` após a saída da `TelaSplashInicial` com a `HomePage` interativa. Atributos: `tipo_start: cold_start`, `destino: home`.
    2. **Cold Start ➔ Deep Link (`cold_start_deep_link` / `deep_link_aberto` com `duracao_ms`)**: Da entrada em `main()` até o `addPostFrameCallback` da página de destino (`pico`, `grupo`, `setor`, `via` ou `mapa`). Atributos: `destino`, `modo_acesso` (`memoria`, `offline`, `temp_cache`, `cdn_online`), `sucesso`, `abrir_mapa`.
    3. **Warm Start ➔ Deep Link (`warm_start_deep_link` / `deep_link_aberto` com `duracao_ms`)**: Do recebimento da URI no `GerenciadorDeepLinks` até o `addPostFrameCallback` da página de destino renderizada. Atributos: `destino`, `modo_acesso` (`memoria`, `offline`, `temp_cache`, `cdn_online`), `sucesso`, `abrir_mapa`.
    4. **SyncIndex Fase 1 (`sync_index_fase1` / `performance_sync_index`)**: Do início de `syncIndex()` até o retorno da Fase 1 (`indice.binarypb` + delta do `catalogo.db`). Atributos: `fase: fase1_indice_catalogo`, `status_http` (`304`, `200`, `offline`, `erro`), `origem` (`auto`, `manual`), `modo` (`oficial`, `experimental`).
    5. **SyncIndex Fase 2 (`sync_index_fase2` / `performance_sync_index`)**: Do início da atualização de mídias em segundo plano até o commit atômico dos arquivos `.tmp` e atualização da UI. Atributos e contadores: `fase: fase2_midias_background`, `teve_atualizacao` (`true`/`false`), `qtd_picos_atualizados`, `qtd_thumbs`.
    6. **Abrir Croqui (`abrir_croqui` / `acao_croqui` com `duracao_ms`)**: Do clique no card de pico (`handlePicoSelection`) até a resolução de `getCroqui` e o `addPostFrameCallback` da página do pico. Atributos: `id_croqui`, `modo_acesso` (`memoria`, `offline`, `temp_cache`, `cdn_online`), `origem` (`home`, `explorar`, `meus_croquis`, `mapa_global`).
    7. **Navegação Interna do Croqui (`navegacao_interna_croqui` / `abrir_setor`, `abrir_grupo`, `acao_escalada` com `duracao_ms`)**: Do toque em um setor, grupo ou via até o `addPostFrameCallback` da tela de destino. Atributos: `id_croqui`, `destino` (`setor`, `grupo`, `via`), `modo_acesso` (`offline`, `online`).
    8. **Abrir Mapa Interativo (`abrir_mapa_interativo` / `abrir_mapa` com `duracao_ms`)**: Da inicialização do mapa em `MapaInterativoPage` até que `ProvedorImagemAresta.resolver` conclua **e** o primeiro frame da imagem `.webp` do mapa seja efetivamente decodificado e pintado na tela (`frame != null` no `Image.frameBuilder`). Atributos: `id_croqui`, `modo_acesso` (`offline`, `online`), `origem_imagem` (`downloads`, `temp_cache`, `cdn_remoto`).

## Capabilities

### New Capabilities
- `telemetria-performance-aplicativo`: Coleta estruturada de métricas de performance ponta a ponta (*Time to Interactive*) com dupla emissão (Firebase Performance Custom Traces + eventos GA4 com `duracao_ms` e dimensões de fatiamento para o Looker Studio) e desativação estrita em modo debug (`kDebugMode`).

### Modified Capabilities
- `offline-first-initialization`: Transição suave (`AnimatedSwitcher`) na saída da `TelaSplashInicial` no Cold Start e aplicação do fundo escuro `#181312` (`deepBasalt`) na janela nativa após o primeiro `onStop()` para eliminar flashes brancos em retomadas de segundo plano (*Warm Start*).
- `qr-deep-linking`: Prevenção de múltiplas instâncias da `MainActivity` ao abrir deep links em segundo plano (`android:launchMode="singleTask"`) e medição de `duracao_ms` e `modo_acesso` (`memoria`, `offline`, `temp_cache`, `cdn_online`) na abertura de deep links em Cold Start e Warm Start.

## Impact

- **Android Nativo**:
  - `frontend/android/app/src/main/AndroidManifest.xml` (`android:launchMode="singleTask"`).
  - `frontend/android/app/src/main/kotlin/com/example/frontend/MainActivity.kt` (sobrescrita de `onStop()` aplicando `ColorDrawable(0xFF181312.toInt())` na janela).
- **Serviços Firebase e Telemetria (`lib/services/firebase/`)**:
  - `frontend/lib/services/firebase/inicializar_firebase.dart` (inicialização de `ServicoPerformance` com bloqueio em modo debug).
  - `frontend/lib/services/firebase/performance_telemetria.dart` (novo serviço isolado encapsulando `FirebasePerformance`, cronômetros até `addPostFrameCallback` e dupla emissão com `TelemetryService`).
  - `frontend/lib/services/firebase/telemetria.dart` (novos parâmetros opcionais `duracaoMs` e `modoAcesso` / `origemImagem` e eventos `performance_abertura_app` e `performance_sync_index`).
- **Repositório, Imagens, Sincronização e Navegação/UI**:
  - `frontend/lib/services/repositorio_dataset.dart` (registro da origem de resolução de `getCroqui`: `memoria`, `offline`, `temp_cache`, `cdn_online`).
  - `frontend/lib/services/imagens/provedor_imagem_aresta.dart` (exposição da origem da imagem resolvida: `downloads`, `temp_cache`, `cdn_remoto`).
  - `frontend/lib/services/sincronizacao.dart` (medição das Fases 1 e 2 do `syncIndex` com fatiamento por `status_http`, `origem` e `modo`).
  - `frontend/lib/main.dart`, `frontend/lib/services/deep_link/gerenciador_deep_links.dart`, `frontend/lib/services/deep_link/deep_link_navigator_service.dart`, `frontend/lib/view/function_library/biblioteca_funcoes_comuns.dart` e `frontend/lib/pages/croqui/mapa_interativo_page.dart`.
