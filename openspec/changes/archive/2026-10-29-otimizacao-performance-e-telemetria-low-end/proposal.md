# Proposal

## Why

O perfilamento de performance em modo `--profile` revelou três pontos críticos que impactam desproporcionalmente dispositivos de entrada (*low-end*, com 2–4 GB de RAM, armazenamento flash eMMC lento e GPUs modestas), mas que ficam mascarados em aparelhos topo de linha (como o Galaxy S24 Ultra):
1. **Latência e consumo de memória no Cold Start**: O `DatasetRepository.loadIndiceToMemory` lê do disco e desserializa em Protobuf (`compilado.binarypb` + `NormalizadorCroqui`) **todos** os croquis baixados pelo usuário antes de liberar a inicialização, além de montar simultaneamente as 4 abas do `IndexedStack` no primeiro frame — penalizando usuários que baixam múltiplos guias para viagens offline.
2. **Picos de >20ms em todas as transições de página e redraws no Mapa Interativo**: A cada navegação na árvore (`TreeNavigationWrapper`), toda a pilha de páginas e seus ViewModels (`PicoViewModel`, `PicoCategorizedData`) são recriados; um novo `DatasetResolver` é instanciado repetidamente (chegando a $O(M \times N)$ dentro do loop de referências do `MapaInterativoPage`, re-normalizando e re-indexando o pico inteiro para cada via do mapa); e animações de destaque no mapa disparam `setState` na página inteira e recriam `TextPainter.layout()` dentro do `paint()`.
3. **Ponto cego na telemetria de produção para aparelhos fracos**: O `ServicoPerformance` atual mede tempos de abertura (*Time to Interactive*), mas não fatia as métricas pelo porte de hardware do usuário (`tier_dispositivo` / RAM) nem mede a fluidez real de renderização (*Frame Timing* / taxa de *jank* > 16ms na UI e Raster thread durante transições e uso do mapa).

## What Changes

- **Lazy Loading Estrito de `compilado.binarypb` e Abas Principais**:
  - Fazer com que `DatasetRepository.loadIndiceToMemory` e `_refreshActiveDataset` confiem exclusivamente nos metadados leves de `indice.binarypb` (`ResumoCroqui`) e `catalogo.db` durante o bootstrap e listagens, carregando e desserializando `compilado.binarypb` estritamente sob demanda (`getCroqui`) quando o usuário abre um pico, mantendo cache em memória dos croquis acessados na sessão.
  - Tornar a montagem das abas secundárias do `IndexedStack` em `TreeNavigationWrapper` (`BrowsePage`, `MeusCroquisPage`, `ComunidadePage`) preguiçosa (*lazy initialization*), construindo apenas a aba ativa no primeiro frame e preservando o estado no `IndexedStack` após a primeira visita.
- **Reutilização do `DatasetResolver` a Nível de Croqui/Pico e Cache de Pilha na Navegação**:
  - Vincular e cachear uma instância única de `DatasetResolver` ao ciclo de vida do `Croqui`/`Pico` carregado (e evitar re-normalizações redundantes em `NormalizadorCroqui`), propagando o `DatasetResolver` através do `PageListenableBuilder` para todas as páginas do croqui (`PicoDetailsPage`, `SetoresPage`, `SetorPage`, `GrupoPage`, `ViaPage`, `MapasCarrosselPage` e `MapaInterativoPage`).
  - Eliminar o loop $O(M \times N)$ em `MapaInterativoPage._buildReferenceMaps` consumindo o `DatasetResolver` compartilhado do pico em $O(1)$.
  - Preservar as instâncias de `Page` e ViewModels (`PicoViewModel`) das rotas subjacentes na pilha do `TreeNavigationWrapper` durante transições de navegação, reconstruindo apenas quando o nó ou o dataset do croqui sofrer alteração real.
- **Otimização de Renderização (UI/Raster) no `MapaInterativoPage`**:
  - Substituir o `setState(() {})` global no listener de `_highlightController` pelo repasse direto de `Listenable` (`repaint`) ao `MarkerPainter`, evitando rebuilds de widgets a cada frame do pulso de destaque.
  - Cachear instâncias de `TextPainter` já medidas (`.layout()`) nos marcadores de linha e isolar a superfície do mapa com `RepaintBoundary`.
- **Classificador de Tier de Dispositivo, Teto de Memória Adaptativo e Telemetria de Fluidez (Jank)**:
  - Criar serviço de classificação de hardware (`ClassificadorDispositivo` em `lib/services/firebase/` ou utilitário injetável) que determina o `tier_dispositivo` (`'baixo'` para ≤ 3 GB RAM, `'medio'` para 4–6 GB RAM, `'alto'` para ≥ 8 GB RAM) e metadados de RAM/SO.
  - Ajustar `configurarGestaoMemoria` para dimensionar dinamicamente o teto do `imageCache.maximumSizeBytes` conforme a RAM do dispositivo (50 MB para `'baixo'`, 100 MB para `'medio'`/fallback padrão, 150 MB para `'alto'`).
  - Enriquecer todas as traces do `ServicoPerformance` e eventos de performance do GA4 (`TelemetryService`) com o atributo `tier_dispositivo` e `ram_gb`.
  - Instrumentar a captura de `FrameTiming` (`SchedulerBinding.instance.addTimingsCallback`) no `ServicoPerformance` para medir a fluidez real (`p95_ui_ms`, `p95_raster_ms`, `taxa_jank_pct`, `frames_lentos`, `frames_totais`) durante sessões do `MapaInterativoPage` e transições de navegação do croqui.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capability isolada; os comportamentos estendem diretamente as especificações existentes abaixo. -->

### Modified Capabilities
- `offline-first-initialization`: Adiciona carregamento sob demanda (*lazy loading*) dos arquivos `compilado.binarypb` baixados (sem desserialização em massa no bootstrap) e inicialização preguiçosa das abas não visíveis do `IndexedStack` no Cold Start.
- `croqui-uid-resolution`: Adiciona cache e compartilhamento da instância de `DatasetResolver` e idempotência de `NormalizadorCroqui` a nível de `Croqui`/`Pico`, propagando o resolvedor para todas as páginas da hierarquia do croqui sem reinstanciação por página ou por referência de mapa.
- `navigation`: Adiciona preservação de instâncias de `Page` e `ViewModel` das rotas estacionárias na pilha declarativa do `TreeNavigationWrapper` durante transições de navegação e disponibiliza o `DatasetResolver` via `PageListenableBuilder`.
- `interactive-map`: Atualiza a pré-computação de referências para reutilizar o `DatasetResolver` compartilhado em $O(1)$ e exige repintura reativa via `Listenable` (`repaint`), isolamento por `RepaintBoundary` e cache de layout de `TextPainter` no `MarkerPainter`.
- `gestao-memoria-vitals`: Torna o limite de `imageCache.maximumSizeBytes` adaptativo ao `tier_dispositivo` (RAM física do aparelho: 50 MB / 100 MB / 150 MB), mantendo 100 MB como fallback padrão.
- `telemetria-performance-aplicativo`: Adiciona classificação automática por `tier_dispositivo` (`baixo`, `medio`, `alto`) e `ram_gb` em todas as medições de performance e introduz a coleta de métricas de fluidez de quadros (`FrameTiming`: P95 UI/Raster e taxa de *jank*) em sessões de mapa interativo e navegação.

## Impact

- **Serviços de Dados e Inicialização**: `lib/services/repositorio_dataset.dart`, `lib/services/dataset/metadados/extrator_metadados_croqui.dart`, `lib/services/dataset/normalizador_croqui.dart`, `lib/services/inicializacao_app.dart`, `lib/main.dart`.
- **Navegação e Resolução de Croqui**: `lib/utils/consulta_dataset.dart`, `lib/navigation/construtor_reativo_pagina.dart`, `lib/navigation/construtor_view_arvore.dart`, `lib/navigation/wrapper_navegacao_arvore.dart`.
- **Páginas de Croqui e Mapa Interativo**: `lib/pages/mapa_interativo.dart`, `lib/pages/mapas_carrossel.dart`, `lib/pages/pico.dart`, `lib/pages/setor.dart`, `lib/pages/via.dart`, `lib/view/function_library/via_functions.dart`.
- **Telemetria e Monitoramento**: `lib/services/firebase/performance_telemetria.dart`, `lib/services/firebase/telemetria.dart`, novo módulo `lib/services/firebase/classificador_dispositivo.dart` (e/ou coletor de `FrameTiming`), mais testes espelhados 1:1 em `test/`.
