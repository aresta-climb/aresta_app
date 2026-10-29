# Tasks

## 1. Idempotência de Normalização e Cache Compartilhado de DatasetResolver

- [x] 1.1 Escrever testes comportamentais em `frontend/test/services/dataset/normalizador_croqui_test.dart` e `frontend/test/utils/consulta_dataset_test.dart` verificando que chamadas repetidas a `NormalizadorCroqui.normalizarCroqui`/`normalizarPico` e `DatasetResolver` na mesma instância de `Pico`/`Croqui` reutilizam a instância indexada em $O(1)$ e que novas instâncias geram novo índice; implementar o cache via `Expando` em `normalizador_croqui.dart` e `consulta_dataset.dart` e validar com `flutter test`
- [x] 1.2 Escrever testes em `frontend/test/navigation/construtor_reativo_pagina_test.dart` e `frontend/test/pages/mapa_interativo_test.dart` garantindo que `PageListenableBuilder` e `MapaInterativoPage._buildReferenceMaps` reutilizam o `DatasetResolver` compartilhado do `Pico` (eliminando o loop $O(M \times N)$); atualizar `construtor_reativo_pagina.dart`, `construtor_view_arvore.dart`, `via_functions.dart` e `mapa_interativo.dart` e verificar que todos os testes passam

## 2. Lazy Loading de Croquis Baixados e Lazy Tabs no Cold Start

- [x] 2.1 Atualizar e adicionar testes comportamentais em `frontend/test/services/repositorio_dataset_test.dart` e `frontend/test/services/dataset/metadados/extrator_metadados_croqui_test.dart` comprovando que `loadIndiceToMemory` e `_refreshActiveDataset` não leem nem desserializam arquivos `compilado.binarypb` do disco na inicialização, carregando-os sob demanda em `getCroqui` (ou no `PageListenableBuilder` quando aberto diretamente); implementar o carregamento preguiçoso em `repositorio_dataset.dart` e `construtor_reativo_pagina.dart` e verificar com `flutter test`
- [x] 2.2 Escrever testes de widget em `frontend/test/navigation/wrapper_navegacao_arvore_test.dart` validando que no primeiro frame do Cold Start apenas a aba inicial ativa (`HomePage`) é construída no `IndexedStack` e que as abas secundárias (`BrowsePage`, `MeusCroquisPage`, `ComunidadePage`) são montadas sob demanda na primeira seleção preservando seu estado depois; implementar em `wrapper_navegacao_arvore.dart` e verificar com `flutter test`

## 3. Preservação da Pilha de Navegação e Otimização de Repaint no Mapa Interativo

- [x] 3.1 Escrever testes de widget em `frontend/test/navigation/wrapper_navegacao_arvore_test.dart` e `frontend/test/navigation/construtor_view_arvore_test.dart` verificando que empilhar ou desempilhar rotas filhas (`SetorNode`, `ViaNode`, `MapasCarrosselNode`) preserva a instância da `Page` e do `PicoViewModel` das rotas subjacentes na pilha do `Navigator`; implementar o cache de páginas da pilha em `wrapper_navegacao_arvore.dart` e validar com `flutter test`
- [x] 3.2 Escrever testes em `frontend/test/pages/mapa_interativo_test.dart` e `frontend/test/utils/construtor_caminho_trajeto_test.dart` verificando que a animação de pulso (`_highlightController`) repinta o `MarkerPainter` via `Listenable` sem disparar `setState` na página, que a camada do mapa possui `RepaintBoundary` e que os layouts de `TextPainter` dos marcadores são cacheados; implementar em `mapa_interativo.dart` e `construtor_caminho_trajeto.dart`, atualizar `frontend/lib/README.md` e validar com `flutter test`

## 4. Classificador de Dispositivo, Memória Adaptativa e Telemetria de Fluidez (Jank)

- [x] 4.1 Criar `frontend/lib/services/firebase/classificador_dispositivo.dart` e seu teste espelhado `frontend/test/services/firebase/classificador_dispositivo_test.dart` (usando TDD e injeção determinística sem mocks internos) para classificar `tier_dispositivo` (`'baixo'` ≤ 3 GB, `'medio'` 4–6 GB, `'alto'` ≥ 8 GB, `'desconhecido'`) e calcular o teto adaptativo de `imageCache` (50 MB / 100 MB / 150 MB); integrar em `configurarGestaoMemoria` (`inicializacao_app.dart` e `main.dart`) e verificar com `flutter test` em `inicializacao_app_test.dart`
- [x] 4.2 Expandir `frontend/test/services/firebase/performance_telemetria_test.dart` e `frontend/test/services/firebase/telemetria_test.dart` para validar a anexação automática de `tier_dispositivo` e `ram_gb` em todas as traces/eventos e a medição de `FrameTiming` (`iniciarMonitoramentoFluidez` / `encerrarMonitoramentoFluidez` emitindo `fluidez_sessao_tela` com `total_frames`, `frames_jank`, `taxa_jank_pct`, `p95_ui_ms` e `p95_raster_ms`); implementar em `performance_telemetria.dart`, `telemetria.dart` e integrar no ciclo de vida de `MapaInterativoPage`, atualizando `frontend/lib/services/firebase/README.md`

## 5. Validação de Integração, Arquitetura e Cobertura

- [x] 5.1 Executar a suíte completa de testes (`flutter test`) e os testes de arquitetura (`test/architecture/firebase_isolation_test.dart` e espelhamento 1:1), garantindo 100% de aprovação e cobertura comportamental nos arquivos alterados
