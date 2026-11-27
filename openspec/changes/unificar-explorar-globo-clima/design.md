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

