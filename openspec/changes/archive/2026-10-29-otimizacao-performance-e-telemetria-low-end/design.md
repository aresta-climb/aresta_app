# Design

## Context

Conforme detalhado em `proposal.md`, o diagnóstico empírico via Flutter DevTools (`--profile`) identificou gargalos estruturais na abertura do aplicativo (*Cold Start*) e nas transições entre telas, além da falta de visibilidade analítica por porte de dispositivo e fluidez de quadros (*jank*). Toda a implementação deve seguir rigorosamente os 8 princípios do `AGENTS.md` (100% em português brasileiro, modularidade, TDD com 100% de cobertura comportamental, espelhamento 1:1 de testes e proibição de mocks para código interno).

## Goals / Non-Goals

**Goals:**
- Garantir que o tempo de *Cold Start* e a memória inicial sejam $O(1)$ em relação ao número de croquis baixados em `/downloads` (carregando `compilado.binarypb` apenas sob demanda).
- Reduzir o tempo de construção do primeiro frame de *Cold Start* montando apenas a aba inicial (`HomePage`) no `IndexedStack`.
- Eliminar o custo $O(M \times N)$ na abertura de mapas e transições de página compartilhando uma única instância de `DatasetResolver` por `Croqui`/`Pico` e tornando `NormalizadorCroqui` idempotente em $O(1)$.
- Preservar instâncias de `Page` e ViewModels (`PicoViewModel`) das rotas subjacentes na pilha declarativa do `TreeNavigationWrapper`.
- Eliminar rebuilds da árvore de widgets durante animações do `MapaInterativoPage` e cachear `TextPainter` nos marcadores vetoriais.
- Classificar o dispositivo por memória RAM (`tier_dispositivo`: `'baixo'`, `'medio'`, `'alto'`), ajustar o teto do `imageCache` proporcionalmente (50 MB / 100 MB / 150 MB) e emitir métricas de `FrameTiming` (`fluidez_sessao_tela`) e atributos de hardware no `ServicoPerformance` e `TelemetryService`.

**Non-Goals:**
- Aplicar `ResizeImage` nas imagens de mapas interativos (descartado após validação no Memory Profiler demonstrar estabilidade de RSS graças ao limite de 2.5 MP já aplicado no servidor).
- Alterar o formato binário Protobuf (`indice.binarypb` ou `compilado.binarypb`) ou o schema do `catalogo.db`.

## Decisions

### 1. Lazy Loading de `compilado.binarypb` em `DatasetRepository`
- **Decisão**: Em `DatasetRepository.loadIndiceToMemory` e `_refreshActiveDataset`, remover a chamada em lote a `extratorMetadados.carregarMetadadosLocais` que invocava `getCroqui(pico.id)` para todos os picos baixados. Em vez disso:
  - `picosDisponiveis` e `picosBaixados` são construídos imediatamente a partir de `ResumoCroqui.paraResumoPico(baseUrl: ..., isDownloaded: ...)`. Se o `Croqui` já estiver carregado em memória na sessão (ex: em `mapaBaixadosAtuais` com mesmo checksum ou em `gerenciadorSessaoOnline`), ele é anexado; caso contrário, `ResumoPico.croqui` e `ResumoPico.pico` permanecem `null` até que o pico seja efetivamente aberto via `getCroqui(id)`.
  - Quando `getCroqui(id)` carrega um croqui do disco (`/downloads`), além de indexar seus hashes SHA-256 (`indexarMidiasDoCroqui`), ele o registra em cache de memória (`gerenciadorSessaoOnline` ou cache interno de croquis carregados) e atualiza a entrada correspondente em `activeDataset` se necessário, garantindo que `PageListenableBuilder` encontre o `Croqui`/`Pico` imediatamente.
- **Alternativa considerada**: Desserializar todos os `compilado.binarypb` em um `Isolate` secundário no boot. Descartada porque ainda consumiria memória RAM desnecessária para dezenas de croquis que o usuário não abriu na sessão e atrasaria a disponibilidade em aparelhos com flash lento.

### 2. Idempotência em `NormalizadorCroqui` e Cache de `DatasetResolver` via `Expando`
- **Decisão**:
  - Usar um `Expando<bool> _instanciasNormalizadas` em `NormalizadorCroqui` para marcar instâncias de `Croqui`, `Pico` e `Mapa` que já passaram pela normalização in-place. Chamadas subsequentes à mesma referência em memória retornam imediatamente em $O(1)$.
  - Usar um `Expando<DatasetResolver> _cachePorPico` em `DatasetResolver` (exposto via construtor factory ou `DatasetResolver.obterParaPico(Pico pico, {Croqui? croqui, List<Botao>? botoes})`). Como `Expando` usa referências fracas (*weak references*), o índice vive exatamente enquanto a instância de `Pico` existir em memória e é coletado pelo Garbage Collector automaticamente quando o `Pico` é descartado ou substituído por um Live Reload.
  - Propagar o `DatasetResolver` resolvido no `PageListenableBuilder` (adicionando acesso ao resolvedor ou mantendo `DatasetResolver` reutilizado automaticamente em `DatasetResolver.resolve`, `DatasetResolver.resolveReferencia`, `PageListenableBuilder`, `ViaPage` e `MapaInterativoPage`).
- **Racional**: Elimina instantaneamente o loop $O(M \times N)$ em `MapaInterativoPage._buildReferenceMaps()` (onde 30 referências reconstruíam o `DatasetResolver` 30 vezes) sem exigir invalidação manual de cache nem risco de memory leak.

### 3. Lazy Tabs no `IndexedStack` e Cache de Rotas na Pilha do `TreeNavigationWrapper`
- **Decisão**:
  - Em `TreeNavigationWrapperState`, manter um `final Set<int> _abasVisitadas = {0}` (ou a aba inicial correspondente ao `baseNode`). No `IndexedStack`, para índices `i` que ainda não estão em `_abasVisitadas`, renderizar `const SizedBox.shrink()`; assim que a aba `i` é selecionada, adicioná-la a `_abasVisitadas` para que seja montada e preservada dali em diante.
  - Para as páginas empilhadas (`pushedNodes`), manter um cache em `TreeNavigationWrapperState` mapeando a chave canônica do `NavNode` (`node.toString()`) para a instância de `Page` construída (invalidando entradas que saíram de `pushedNodes`). Dentro das páginas filhas, o `PageListenableBuilder` já escuta `datasetRepo.activeDataset` reativamente, de modo que manter a mesma instância de `MaterialPage` e `PicoViewModel` na pilha evita recriar objetos e reexecutar `initState`/`didUpdateWidget` das páginas de fundo a cada push/pop.

### 4. Repintura via `Listenable` e Cache de `TextPainter` no `MapaInterativoPage`
- **Decisão**:
  - Remover `_highlightController.addListener(() { setState(() {}); })` de `MapaInterativoPage`.
  - Passar `repaint: Listenable.merge([_highlightAnimation, _transformationController])` para a superclasse `CustomPainter` de `MarkerPainter` e ler `highlightAnimation?.value ?? highlightIntensity` diretamente no método `paint()`.
  - Criar um cache estático leve em `ConstrutorCaminhoTrajeto` (ou no escopo do pintor) para instâncias de `TextPainter` já submetidas a `.layout()`, indexadas por `'$rotulo|${fontSize.toStringAsFixed(1)}'`, limitado a 256 entradas LRU/simples.
  - Envolver a imagem base e a camada de marcadores do mapa em `RepaintBoundary` para evitar que animações nos marcadores forcem a re-rasterização da textura do mapa e vice-versa.

### 5. `ClassificadorDispositivo`, Cache de Memória Adaptativo e `MonitorFluidezFrames`
- **Decisão**:
  - Criar `lib/services/firebase/classificador_dispositivo.dart` contendo `ClassificadorDispositivo`:
    - Lê a memória RAM total física do aparelho (no Android via `/proc/meminfo` `MemTotal` ou `DeviceInfoPlugin`, com injeção limpa para testes determinísticos sem mocks internos).
    - Classifica em:
      - `'baixo'`: RAM $\le 3584\text{ MB}$ ($\le 3.5\text{ GB}$) $\rightarrow$ teto de `imageCache` = **50 MB**;
      - `'medio'`: $3584\text{ MB} < \text{RAM} \le 6656\text{ MB}$ ($4\text{ a }6\text{ GB}$) $\rightarrow$ teto de `imageCache` = **100 MB**;
      - `'alto'`: $\text{RAM} > 6656\text{ MB}$ ($\ge 8\text{ GB}$) $\rightarrow$ teto de `imageCache` = **150 MB**;
      - Fallback (`'desconhecido'`): teto padrão de **100 MB**.
  - Integrar `ClassificadorDispositivo` no `ServicoPerformance`:
    - Toda trace (`registrarTrace`) e evento de performance inclui automaticamente os atributos `tier_dispositivo` e `ram_gb`.
    - Adicionar medição de `FrameTiming` (`iniciarMonitoramentoFluidez(String tela)` / `encerrarMonitoramentoFluidez(String tela, {Map<String, String>? atributosExtras})`) usando `SchedulerBinding.instance.addTimingsCallback` (ou injeção de `FrameTiming` para testes determinísticos 100% cobertos) que calcula `total_frames`, `frames_jank` (buildDuration > 16ms ou rasterDuration > 16ms), `taxa_jank_pct`, `p95_ui_ms` e `p95_raster_ms`, emitindo a trace `fluidez_sessao_tela` e evento analítico no GA4.

## Risks / Trade-offs

- **[Risco] Código ou testes legados que esperavam `picosBaixados[i].croqui != null` logo após `init()`** $\rightarrow$ **Mitigação**: Auditar todos os consumidores de `picosBaixados` e `croquisBaixados`. Quando um consumidor precisar apenas de metadados de listagem (nome, contagem de setores/vias, estado, cidade, data), ele já os possui em `ResumoPico` / `MetadadosIndice`. No `PageListenableBuilder` (quando uma página de croqui é montada sem que `getCroqui` tenha sido aguardado previamente, como em testes de widget que montam a rota diretamente), acionar o carregamento sob demanda ou resolver síncrono/assíncrono para manter compatibilidade total.
- **[Risco] Leitura de `/proc/meminfo` em plataformas não-Android (iOS / Desktop / Testes)** $\rightarrow$ **Mitigação**: Prover leitura multiplataforma segura com fallback gracioso para `'desconhecido'` (100 MB) e injeção de provedor de bytes de RAM nos testes.
