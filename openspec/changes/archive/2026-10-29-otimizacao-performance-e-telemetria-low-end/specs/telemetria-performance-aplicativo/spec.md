## MODIFIED Requirements

### Requirement: Dupla Emissão com Atributos de Fatiamento (Firebase Performance + GA4 / Looker Studio)
Para cada fluxo crítico monitorado, o sistema DEVE (MUST) emitir simultaneamente uma trace customizada no Firebase Performance (contendo atributos e métricas numéricas para análise de percentis P50, P90 e P99) e um evento no Google Analytics 4 contendo o parâmetro numérico `duracao_ms` acompanhado das dimensões de fatiamento (*slicing*), incluindo obrigatoriamente o porte do aparelho (`tier_dispositivo` e `ram_gb`), permitindo agregação e filtragem cruzada no Looker Studio. Todo o código de integração com pacotes `firebase_*` DEVE residir exclusivamente dentro de `lib/services/firebase/`.

#### Scenario: Emissão simultânea de trace e evento analítico com duração e dimensões
- **WHEN** uma operação monitorada conclui sua medição até o frame interativo
- **THEN** o sistema finaliza a trace correspondente com seus atributos anexados (incluindo `tier_dispositivo` e `ram_gb`) e despacha o evento analítico contendo `duracao_ms` e os mesmos atributos de fatiamento

## ADDED Requirements

### Requirement: Classificação Determinística de Tier de Dispositivo
O sistema DEVE (MUST) classificar o hardware do usuário uma única vez na inicialização nas categorias `'baixo'` (RAM ≤ 3 GB), `'medio'` (RAM entre 4 GB e 6 GB) ou `'alto'` (RAM ≥ 8 GB), expondo `tier_dispositivo` e `ram_gb` para enriquecimento automático de telemetria e configuração de memória, com fallback seguro para `'desconhecido'` caso a leitura do sistema operacional não esteja disponível.

#### Scenario: Classificação de aparelho Android de entrada (≤ 3 GB RAM)
- **WHEN** o serviço de classificação inspeciona um dispositivo com 3072 MB de RAM total
- **THEN** o dispositivo é classificado com `tier_dispositivo: 'baixo'` e `ram_gb: '3'`

#### Scenario: Classificação de aparelho topo de linha (≥ 8 GB RAM)
- **WHEN** o serviço de classificação inspeciona um dispositivo com 12288 MB de RAM total
- **THEN** o dispositivo é classificado com `tier_dispositivo: 'alto'` e `ram_gb: '12'`

### Requirement: Medição de Fluidez de Quadros e Jank em Sessões Interativas
O sistema DEVE (MUST) monitorar os tempos de construção (UI thread) e rasterização (Raster thread) via `SchedulerBinding.addTimingsCallback` durante sessões de uso do `MapaInterativoPage` e transições de navegação, registrando ao encerrar a sessão a trace e o evento `fluidez_sessao_tela` com as métricas `total_frames`, `frames_jank` (> 16ms), `taxa_jank_pct`, `p95_ui_ms` e `p95_raster_ms` fatiados por `tela` e `tier_dispositivo`.

#### Scenario: Registro de fluidez ao encerrar sessão de Mapa Interativo
- **WHEN** o usuário interage com o `MapaInterativoPage` gerando quadros renderizados e fecha ou navega para fora da tela
- **THEN** o `ServicoPerformance` calcula `p95_ui_ms`, `p95_raster_ms`, `frames_jank` e `taxa_jank_pct` dos quadros coletados e emite a trace `fluidez_sessao_tela` e o evento analítico correspondente
