# Design: Unificação da Aba Explorar com Globo 3D em 4 LODs, Filtros de Grau e RainTracker

## 1. Visão Geral e Princípios Arquiteturais

Esta mudança funde a aba `Explorar` e o antigo `MapaGlobalPage` em uma única superfície offline-first, detalhada no documento mestre `docs/arquitetura/mds/arquitetura_unificada_explorar_globo_lods_e_clima.md` e guiada pelos princípios do `AGENTS.md`:

1. **Orçamento Estrito de Meio Frame (`< 4ms` a 120fps — Princípio IX)**:
   - O mapa não utiliza SDKs nativos baseados em `PlatformView` (`google_maps_flutter`) na aba `Explorar`.
   - Toda a projeção esférica/perspectiva e renderização dos 4 LODs roda sobre `CustomPainter` / `Canvas.drawVertices` alimentados por `Float32List` pré-alocados, repintando exclusivamente durante gestos ativos ou animações (`Ticker`), com consumo `0%` de CPU em repouso.
2. **Offline-First Integral e Payload Mínimo**:
   - Contornos continentais e estaduais vêm embutidos no pacote do aplicativo (`< 400 KB`).
   - A filtragem por graduação usa os registros já sincronizados em `catalogo.db` (`catalogo_aresta`).
   - O cálculo de secagem de 5 dias roda localmente a partir da data da última chuva gravada em cache, mantendo precisão mesmo durante dias sem sinal em campo.
3. **Corte Limpo e Fail-Fast (Princípio VIII)**:
   - `MapaGlobalPage`, `MapaGlobalViewModel`, `MapaGlobalNode` e `AppNav.toMapaGlobal` são integralmente removidos, eliminando caminhos duplicados de descoberta geográfica.
4. **Tudo em Português, MVVM e Espelhamento 1:1 com Fakes Determinísticos (Princípios I, II, III, IV e V)**:
   - Nomenclatura 100% em português brasileiro, widgets passivos (*Dumb UI*) e fronteira HTTP isolada por interface com `ClienteClimaAltimetriaFake` testado em `cliente_clima_altimetria_fake_test.dart`.

---

## 2. Arquitetura de Requisições Externas (RainTracker + Altimetria + Malhas IBGE)

### 2.1. Malhas Geográficas Oficiais (Tempo de Build — IBGE + Natural Earth)
* **Observação Técnica sobre APIs do IBGE**: A plataforma `servicodados.ibge.gov.br` fornece malhas políticas oficiais (`/api/v3/malhas/estados` e `/paises`), mas não disponibiliza endpoint REST de modelo digital de elevação contínuo `(lat, lon) -> metros` para consulta de relevo montanhoso.
* **Solução**: Um utilitário de build (`frontend/tool/gerar_malha_geografica_offline.dart`) obtém os polígonos oficiais das UFs na API de Malhas do IBGE e continentes vizinhos (Natural Earth), aplica simplificação topológica e grava `frontend/assets/geometria/malha_globo_brasil.json` (ou binário compacto `< 350 KB`), carregado em `Isolate.run` na abertura.

### 2.2. Altimetria Externa de Alta Resolução (NASA SRTM 30m / NASADEM — Estática por Pico)
* Como os arquivos `.binarypb` dos croquis não contêm altitude e o campo `localizacao` frequentemente aponta para o estacionamento na base, a altimetria é extraída externamente a partir dos modelos globais públicos de **30 metros** da NASA (**NASADEM / SRTM GL1**, disponibilizados sem chave via *OpenTopography NASADEM* e *Registry of Open Data Terrain Tiles*).
* **Por que NASA SRTM/NASADEM (30m) em vez de grades de 90m+**: Monólitos e agulhas de escalada (como Pão de Açúcar, Pedra do Baú ou Quixadá) têm cristas estreitas (`150m–400m`) que são achatadas em modelos de baixa resolução; a grade de `30m` preserva a proeminência real da parede.
* **Por que não usar NASA POWER para chuva diária em tempo real**: A API `NASA POWER` (`PRECTOTCORR`) é pública e sem chave, mas possui latência de processamento de `2 a 3 dias` e grade de `~55 km`, o que omitiria chuvas da véspera ou da madrugada. Por isso usamos **NASADEM / SRTM 30m** para o relevo/altitude e **Open-Meteo** (zero atraso temporal) para a precipitação recente.
* Para cada coordenada de pico, o extrator analisa uma janela local (`~2,5 km x 2,5 km`):
  * `altitude_base_m`: cota na coordenada de acesso/estacionamento.
  * `altitude_pico_m`: maior cota rochosa na janela imediata do maciço (exibida como `Alt. 1430m` e usada para escalonar a proeminência vertical no `LOD 3`, podendo opcionalmente amostrar uma micro-grade `16x16` compacta de `256 bytes`/pico).
* Como a altitude geográfica não muda, ela é gravada permanentemente na tabela `public.altimetria_picos` no Supabase **e** embarcada no snapshot inicial `frontend/assets/dados/altimetria_picos_inicial.json` (`< 4 KB`), garantindo exibição offline desde o primeiro boot.

### 2.3. Precipitação Regional e Bolhas de Chuva (Dinâmica a cada 3h)
```mermaid
sequenceDiagram
    participant Cron as Supabase pg_cron (3h)
    participant Edge as Edge Function sincronizar-clima-picos
    participant Ext as NASA SRTM 30m + Open-Meteo API
    participant DB as Supabase PostgREST (Slots atual + copia_seguranca)
    participant App as App Flutter (ClienteClimaAltimetria)

    Cron->>Edge: Dispara a cada 3 horas
    Edge->>DB: Lê coordenadas dos picos e altimetrias já conhecidas
    Edge->>Ext: Consulta precipitação (5 dias) + altimetria 30m de picos novos
    Edge->>Edge: Valida integridade; se válido, agrupa bolhas (>=1mm) e chuva por pico
    Edge->>DB: Rotação transacional: 'atual' -> 'copia_seguranca' (descarta antigo) e grava novo 'atual'
    App->>DB: 1 GET /rest/v1/estado_clima_picos?slot=eq.atual (TTL local 3h)
    App->>App: Rotaciona cache local (atual -> copia_seguranca) e avalia curva de 5 dias offline
```

* **Tabelas e Rotação de Cópia Única de Segurança (`docs/arquitetura/sql/supabase_clima_e_altimetria_picos.sql`)**:
  1. `public.snapshots_altimetria_picos` e `public.estado_clima_picos`:
     * Ambas operam com `slot TEXT PRIMARY KEY CHECK (slot IN ('atual', 'copia_seguranca'))`, RLS habilitado e política `SELECT` pública (`anon` e `authenticated`).
     * Funções PL/pgSQL transacionais `rotacionar_estado_clima_picos` e `rotacionar_snapshot_altimetria_picos` copiam o `atual` vigente sobre `copia_seguranca` (descartando a versão antiga) antes de gravar o novo `atual`.
     * Se os serviços do IBGE, NASA ou Open-Meteo estiverem offline ou responderem com erro/payload inválido, a coleta aborta a escrita sem sobrescrever `atual` nem `copia_seguranca`.
  2. **Mesma Regra em Build e no Cliente**:
     * `gerar_malha_geografica_offline.dart` mantém `*.seguranca.json` ao lado do asset ativo, atualizando a cópia de segurança e descartando a anterior a cada coleta íntegra do IBGE/NASA.
     * `ArmazenamentoClimaLocal` mantém `<docs>/clima_altimetria_atual.json` e `<docs>/clima_altimetria_seguranca.json` via gravação `.tmp` validada antes da rotação.
* **Economia de Requisições no Cliente**:
  * O aplicativo realiza **no máximo 1 `GET` leve (`~5 KB`) a cada 3 horas** para `/rest/v1/estado_clima_picos?slot=eq.atual` (e sincroniza `snapshots_altimetria_picos?slot=eq.atual` apenas se houver picos sem altitude no cache local).
  * Timeout curto (`4 segundos`), não bloqueante: se o aparelho estiver sem sinal, a UI renderiza imediatamente com o cache local sem exibir erro intrusivo ao usuário; falhas inesperadas de protocolo/parsing ou restauração via `copia_seguranca` são registradas via `AppLogger`.

---

## 3. Regra de Negócio: Curva Determinística de Secagem (5 Dias)

A calculadora pura `CalculadoraUmidadePico` recebe `(precipitacaoMm, dataChuvaUtc, dataReferenciaLocal)`:

1. **Classificação Inicial no Dia do Evento (`diasDecorridos == 0`)**:
   * `< 1.0 mm`: `NivelUmidadePico.seco`
   * `1.0 mm` a `< 5.0 mm`: `NivelUmidadePico.levementeMolhado` (duração: **1 dia**)
   * `5.0 mm` a `< 15.0 mm`: `NivelUmidadePico.molhado` (duração neste estágio: **2 dias**, depois decai para `levementeMolhado` por **1 dia** -> total **3 dias** até `seco`)
   * `>= 15.0 mm`: `NivelUmidadePico.muitoMolhado` (duração neste estágio: **2 dias** -> `molhado` por **2 dias** -> `levementeMolhado` por **1 dia** -> total **5 dias** até `seco`)
2. **Múltiplos Dias de Chuva nos Últimos 5 Dias**:
   * Para cada um dos últimos 5 dias no histórico do pico, calcula-se o estado remanescente hoje e adota-se o **maior nível de umidade vigente** (e maior tempo restante para secagem), registrando a data do evento dominante (`Chuva dia DD/MM`).
3. **Regra de Exibição Contextual**:
   * Quando `nivel == NivelUmidadePico.seco`, **nenhum** badge, texto ou ícone meteorológico é exibido no pino ou no card do pico.
   * Quando `nivel != seco`, exibe-se a paleta azul/musgo:
     * `muitoMolhado`: azul índigo intenso (`#6366F1` / `#818CF8`)
     * `molhado`: azul médio (`#3B82F6` / `#60A5FA`)
     * `levementeMolhado`: verde musgo do tema (`dryMoss` `#7B8B6F` / `#9BB38A`)

---

## 4. Motor de Câmera Contínua e 4 LODs (`GloboTerrenoController` + `PintorGloboTerreno`)

Uma única função matemática `projetarCoordenadaMundo(lat, lon, elevacaoMetros)` governa todos os 4 LODs usando escala exponencial do raio planetário (`R = R0 * pow(base, lod)`, `lod` em `[0.0, 3.2]`):

| Estágio | Intervalo `lod` | Geometria Renderizada | Marcadores / Pinos |
|---|---|---|---|
| **LOD 0 • Globo** | `0.00 – 0.75` | Esfera 3D ortográfica com iluminação atmosférica, continentes e Brasil | Clusters limpos por UF (`MG · 12`, `RJ · 8`) sem nomes individuais |
| **LOD 1 • Região** | `0.75 – 1.65` | Divisas estaduais IBGE + bolhas orgânicas translúcidas de chuva | Pinos com prevenção automática de colisão de rótulos |
| **LOD 2 • Serra e Vale** | `1.65 – 2.50` | Câmera inclina suavemente (`0° -> 32°`), lente circular de terreno sombreado + curvas `250m` + bolhas sobre o relevo | Pílulas com nome do pico e altitude (`Alt. 1120m`) |
| **LOD 3 • Maciço 3D** | `2.50 – 3.20` | Câmera alpina (`~54°`) com névoa de horizonte, maciço 3D escalonado por `altitudePicoM`, curvas `80m` e trilha animada | Cume com altitude + micro-marcadores de setor principal e base/trilha |

* **Modo `2D`**: Zera a inclinação (`tilt = 0`, `yaw = 0`) e alterna a projeção esférica para projeção cilíndrica/plana equidistante centrada na câmera, mantendo os mesmos 4 níveis de detalhe e curvas de nível.
* **Adaptação para Dispositivos Modestos (`ClassificadorDispositivo`)**: Em aparelhos classificados com RAM baixa (`<= 3 GB`), a subdivisão da malha nos `LODs 2–3` reduz automaticamente de `32x32` para `22x22` vértices (`< 0.8ms`/frame).

---

## 5. Agregação de Graus e Modalidades no Catálogo (`RepositorioCatalogo`)

Para evitar acoplamento com recompilação imediata do submódulo `aresta_api`, `RepositorioCatalogo` expõe `carregarPerfisGrauPorCroqui()`:
* Executa uma query SQL única em `catalogo_aresta` (`WHERE tipo = 'escalada'`), convertendo `escalada_grau` e `escalada_tipo` em máscaras de bits / intervalos por `id_slug` usando a tabela de pesos existente em `filtro_grau_escalada.dart` (executada em `< 3 ms` e cacheada em memória até `versaoNotificador` mudar).
* No filtro da aba `Explorar`:
  * **Barra Superior**: Campo de busca textual + botão rápido `Grau` (abre popover com `RangeSlider` duplo para Vias `1º–12a` e Boulder `V0–V15`) + botão `Icons.tune_rounded` com contador de filtros ativos (abre modal completo com Ordenação, Modalidades `Esportiva`, `Boulder`, `Móvel / Trad`, `Paredão` e `Highline`, Faixa de Grau, `Salvos Offline` e raio de distância).
  * **Cabeçalho da Gaveta**: Pílulas rápidas sincronizadas (`Esportiva`, `Boulder`, `Móvel / Trad`, `Paredão`).

---

## 6. Sincronia Mapa <-> Gaveta e Micro-Animações

1. **Auto-Scroll Sincronizado (`ScrollController` + índices determinísticos)**:
   - A lista da gaveta usa `ListView.builder` (ou alturas fixas/medidas por chave) mantendo a ordem de classificação ativa.
   - Tocar em um pino no mapa:
     1. Se a gaveta estiver no estágio recolhido (`Mapa`), expande suavemente para `Dividir`.
     2. Anima o scroll da lista (`animateTo` com `Curves.easeOutCubic`, `320ms`) até posicionar o card do pico selecionado no topo visível e aciona o destaque temporário de borda no card.
     3. Dispara a onda sonar no pino e, se o pico estiver úmido, realça temporariamente o contorno da bolha de chuva correspondente.
2. **Voo Parabólico (`Fly-To`)**:
   - Ao selecionar um pico distante (`distanciaGeodesica > 250 km`), `GloboTerrenoController` interpola `(lat, lon)` com `Curves.easeInOutCubic` aplicando um recuo parabólico temporário em `lod` (`-dip * sin(pi * t)`).
3. **Centro Óptico Acoplado**:
   - `ValueListenable<double> alturaGavetaPx` desloca continuamente o centro vertical `cy` da projeção no `CustomPainter` sem reconstruir a lista de cards.
