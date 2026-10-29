# Tasks

## 1. Eliminação de Flash Branco no Warm Start e Transição Suave da Splash (Camadas 1, 2 e 3B)

- [x] 1.1 Alterar `android:launchMode="singleTop"` para `android:launchMode="singleTask"` na `MainActivity` em `frontend/android/app/src/main/AndroidManifest.xml` e verificar via inspeção do manifesto que intents `ACTION_VIEW` reutilizam a instância única da atividade
- [x] 1.2 Sobrescrever `onStop()` em `frontend/android/app/src/main/kotlin/com/example/frontend/MainActivity.kt` aplicando `window.setBackgroundDrawable(ColorDrawable(0xFF181312.toInt()))` para pintar o fundo da janela nativa de escuro (`deepBasalt`) apenas após a primeira ida para segundo plano, verificando com `flutter build apk --debug` que a compilação Kotlin/Android sucede sem alertas
- [x] 1.3 Envolver a transição entre `TelaSplashInicial` e `TreeNavigationWrapper` em `frontend/lib/main.dart` com `AnimatedSwitcher` (~250ms, `Curves.easeOut`) e validar em `frontend/test/main_test.dart` (TDD) que a transição entre a splash e a tela inicial ocorre suavemente

## 2. Fundação do Serviço de Performance, Isolamento Firebase e Bloqueio em Modo Debug

- [x] 2.1 Criar os testes orientados a comportamento em `frontend/test/services/firebase/performance_telemetria_test.dart` e implementar `ServicoPerformance` em `frontend/lib/services/firebase/performance_telemetria.dart` com suporte a dupla emissão (Firebase Performance `Trace` + `TelemetryService` GA4 `duracao_ms`), truncamento seguro de atributos, `aguardarProximoFrame` e bloqueio estrito quando `kDebugMode == true` (`setPerformanceCollectionEnabled(false)`), verificando com `flutter test test/services/firebase/performance_telemetria_test.dart`
- [x] 2.2 Expandir `TelemetryService` em `frontend/lib/services/firebase/telemetria.dart` (e seus testes em `frontend/test/services/firebase/telemetria_test.dart` + `MockTelemetryService` em `frontend/test/helpers/mock_telemetry_service.dart`) para suportar `logPerformanceAberturaApp`, `logPerformanceSyncIndex` e os parâmetros opcionais `duracaoMs`, `modoAcesso` e `origemImagem` em `logDeepLinkAberto`, `logAcaoCroqui`, `logAbrirSetor`, `logAbrirGrupo`, `logAcaoEscalada` e `logAbrirMapa`, verificando com `flutter test test/services/firebase/telemetria_test.dart`
- [x] 2.3 Integrar a inicialização de `ServicoPerformance` em `initFirebase()` (`frontend/lib/services/firebase/inicializar_firebase.dart`), atualizar `frontend/test/services/firebase/inicializar_firebase_test.dart` e `frontend/lib/services/firebase/README.md`, e verificar com `flutter test test/services/firebase/ test/architecture/firebase_isolation_test.dart`

## 3. Rastreamento da Camada de Resolução (`modo_acesso` e `origem_imagem`) e Sincronização em 2 Fases

- [x] 3.1 Adicionar o registro e consulta da camada de resolução (`obterUltimaOrigemResolucao(String id)`: `'memoria'`, `'offline'`, `'temp_cache'`, `'cdn_online'`) em `DatasetRepository.getCroqui` (`frontend/lib/services/repositorio_dataset.dart`) e validar com testes comportamentais em `frontend/test/services/repositorio_dataset_test.dart`
- [x] 3.2 Adicionar o registro e consulta da origem da imagem (`obterUltimaOrigemImagem(String caminhoRelativo)`: `'downloads'`, `'temp_cache'`, `'cdn_remoto'`) em `ProvedorImagemAresta.resolver` (`frontend/lib/services/imagens/provedor_imagem_aresta.dart`) e validar com testes comportamentais em `frontend/test/services/imagens/provedor_imagem_aresta_test.dart`
- [x] 3.3 Instrumentar `SyncService.syncIndex` e `_executarAtualizacaoMidiasEmSegundoPlano` (`frontend/lib/services/sincronizacao.dart`) para medir e emitir `sync_index_fase1` (fatiado por `status_http`: `304`, `200`, `offline`, `erro`, `origem` e `modo`) e `sync_index_fase2` (fatiado por `teve_atualizacao`, `qtd_picos_atualizados` e `qtd_thumbs`), verificando com testes em `frontend/test/services/sincronizacao_test.dart`

## 4. Instrumentação Ponta a Ponta: Cold Start, Deep Links, Croquis, Navegação Interna e Mapas

- [x] 4.1 Instrumentar o fluxo de inicialização em `frontend/lib/main.dart`, `frontend/lib/services/deep_link/gerenciador_deep_links.dart` e `frontend/lib/services/deep_link/deep_link_navigator_service.dart` para medir `cold_start_home`, `cold_start_deep_link` e `warm_start_deep_link` até o `addPostFrameCallback` da página de destino (incluindo `modo_acesso` e `duracao_ms`), validando nos testes `frontend/test/main_test.dart`, `frontend/test/services/deep_link/gerenciador_deep_links_test.dart` e `frontend/test/services/deep_link/deep_link_navigator_service_test.dart`
- [x] 4.2 Instrumentar `handlePicoSelection` e as funções de navegação para Setor, Grupo e Via em `frontend/lib/view/function_library/biblioteca_funcoes_comuns.dart` (e pontos de chamada de abertura de setor/grupo/via) para medir `abrir_croqui` e `navegacao_interna_croqui` até o `addPostFrameCallback` da tela de destino, validando em `frontend/test/view/function_library/biblioteca_funcoes_comuns_test.dart`
- [x] 4.3 Instrumentar `MapaInterativoPage` (`frontend/lib/pages/croqui/mapa_interativo_page.dart`) para medir `abrir_mapa_interativo` desde o início do carregamento do mapa até o primeiro frame decodificado da imagem `.webp` (`frame != null` em `Image.frameBuilder`) com fatiamento por `modo_acesso` (`offline`/`online`) e `origem_imagem` (`downloads`/`temp_cache`/`cdn_remoto`), validando em `frontend/test/pages/croqui/mapa_interativo_page_test.dart`

## 5. Verificação Geral e Documentação Arquitetural

- [x] 5.1 Atualizar `frontend/lib/README.md` com o resumo da telemetria de performance e da proteção contra flash branco no Warm Start, e validar `flutter analyze` (0 avisos) e a suíte completa `flutter test` (100% de aprovação)
