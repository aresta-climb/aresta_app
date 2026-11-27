# Recursos, Fontes de Dados, APIs e Infraestrutura (`aresta_app`)

Este documento é a **referência central e exaustiva de todos os recursos externos e internos** utilizados pelo aplicativo móvel **Aresta Climb** (`aresta_app`) e por suas rotinas acopladas de backend e compilação: APIs públicas científicas e governamentais, bases cartográficas e altimétricas, provedores meteorológicos, serviços em nuvem, contratos de rede, submódulos Git, ativos embarcados, fontes tipográficas, pacotes de terceiros e respectivas **licenças e atribuições obrigatórias**.

---

## Sumário

1. [Visão Geral do Fluxo de Dados e Fronteiras](#1-visão-geral-do-fluxo-de-dados-e-fronteiras)
2. [Fontes Geoespaciais, Cartográficas, Altimétricas e Viárias](#2-fontes-geoespaciais-cartográficas-altimétricas-e-viárias)
3. [Fontes Meteorológicas e Motor `RainTracker`](#3-fontes-meteorológicas-e-motor-raintracker)
4. [Infraestrutura Própria e APIs do Ecossistema Aresta](#4-infraestrutura-própria-e-apis-do-ecossistema-aresta)
5. [Autenticação, Integridade de Dispositivo e Armazenamento em Nuvem](#5-autenticação-integridade-de-dispositivo-e-armazenamento-em-nuvem)
6. [Observabilidade, Telemetria e Roteamento Operacional de Alertas](#6-observabilidade-telemetria-e-roteamento-operacional-de-alertas)
7. [Repositórios Acoplados e Submódulos Git](#7-repositórios-acoplados-e-submódulos-git)
8. [Ativos Embarcados (`assets/`), Tipografia (`fonts/`) e Cópia de Segurança](#8-ativos-embarcados-assets-tipografia-fonts-e-cópia-de-segurança)
9. [Dependências Dart/Flutter, Canais Nativos e Ferramentas de CI/CD](#9-dependências-dartflutter-canais-nativos-e-ferramentas-de-cicd)
10. [Matriz Consolidada de Licenciamento e Atribuições](#10-matriz-consolidada-de-licenciamento-e-atribuições)

---

## 1. Visão Geral do Fluxo de Dados e Fronteiras

Por operar sob arquitetura **Offline-First** (escaladores utilizam o aplicativo na base de falésias sem cobertura celular) e com custo operacional próximo de zero, o projeto **nunca expõe APIs científicas ou meteorológicas brutas diretamente ao tráfego individual dos celulares**. Os recursos externos são ingeridos em duas fronteiras controladas antes de chegarem ao dispositivo:

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ 1. TEMPO DE BUILD / COMPILAÇÃO DE DADOS (CLI & Pipeline aresta_db)                     │
│                                                                                        │
│  • IBGE API v3 (27 UFs + Brasil) ───────┐                                              │
│  • Natural Earth 110m (Continentes) ────┼─► gerar_malha_geografica_offline.dart        │
│  • NASA Blue Marble (Textura 4K) ───────┤   └─► frontend/assets/{geometria,dados}/     │
│  • NASA SRTM 30m / Terrarium (z=12) ────┘       (com cópia única *.seguranca.*)        │
│                                                                                        │
│  • OpenStreetMap / Overpass API ──────────► gerar_malha_estrada_lib.py (aresta_db)     │
│  • Croquis YAML + Fotos WebP ─────────────► indice.binarypb + catalogo.db + croquis    │
│                                             └─► CDN serving.arestaclimb.com/v4         │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                              │
                                              ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ 2. INGESTÃO PERIÓDICA NO SERVIDOR (Cron 3h • Supabase Edge Function)                   │
│                                                                                        │
│  • Open-Meteo Forecast API (Chuva 5d + Malha Sinótica 2D + Vento 10m)                  │
│  • NASA SRTM 30m / AWS Terrarium (Apenas quando surge pico inédito no índice)          │
│       │                                                                                │
│       ▼                                                                                │
│  supabase/functions/sincronizar-clima-picos/index.ts                                   │
│       ├─► Marching Squares + Suavização Chaikin (isoietas reais de tempestade)         │
│       └─► PostgreSQL: public.estado_clima_picos & public.snapshots_altimetria_picos    │
│           (rotação atômica de 2 slots: 'atual' + 'copia_seguranca')                    │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                              │
                                              ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ 3. APLICATIVO MÓVEL EM CAMPO (Flutter • Android & iOS)                                 │
│                                                                                        │
│  • CDN Oficial (serving.arestaclimb.com) ──► SyncService / SyncIsolate (SHA-256/ETag)  │
│  • Gateway Delta (catalogo.arestaclimb.com) ► Deltas SQLite (~1.5 KB) via Cloudflare D1│
│  • Supabase (Auth, PostgREST, Storage, Edge)► Login sem senha, Cadenas, Betas, Clima   │
│  • Links & Relay (aresta.cc / previa.*) ───► Deep links QR Inox e Live Reload WebSocket│
│  • Observabilidade (Firebase + Sentry) ────► Crashlytics, GA4, App Check, Breadcrumbs  │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Fontes Geoespaciais, Cartográficas, Altimétricas e Viárias

| Recurso / Conjunto de Dados | Provedor & Endpoint Oficial | Onde é Usado no Repositório | Modo de Coleta e Papel Funcional | Licença e Atribuição |
|---|---|---|---|---|
| **Malha Territorial do Brasil, 27 UFs e Sedes Municipais** | **IBGE** — API de Serviços de Dados v3 (`servicodados.ibge.gov.br/api/v3/malhas/paises/BR`) e Cadastro Oficial de Municípios Brasileiros | `frontend/tool/gerar_malha_geografica_offline.dart` $\rightarrow$ `frontend/assets/geometria/malha_globo_brasil.json` $\rightarrow$ `malha_relevo_lod.dart` / `superficie_globo_explorar.dart` | Coletado em tempo de ferramenta/build, simplificado via Ramer-Douglas-Peucker (`~171 KB` total) e embarcado offline para desenhar a costa brasileira, as divisas estaduais e as **283 cidades e vilas reais** próximas às regiões de escalada sobre o terreno contínuo. | **Domínio Público / Dados Abertos Governamentais (Brasil)** — Fonte: IBGE. |
| **Massas Continentais Globais (`1:110m Land`) e Rodovias (`1:10m Roads`)** | **Natural Earth** (`raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_110m_land.geojson` e `ne_10m_roads.geojson`) | `frontend/assets/geometria/malha_globo_brasil.json` $\rightarrow$ `malha_relevo_lod.dart` / `superficie_globo_explorar.dart` | Coletado em tempo de ferramenta/build para compor os polígonos continentais mundiais e os **332 segmentos reais de rodovias federais e estaduais** nas regiões de escalada. | **Domínio Público** (*Public Domain* — Natural Earth). |
| **Geoide Terrestre (`WGS84` + `NASA GSFC EGM96`)** | **NASA Goddard Space Flight Center / NGA** (*Earth Gravitational Model 1996* + Elipsoide Oblato `WGS84` $f = 1/298,257$) | `frontend/lib/widgets/explorar/controlador_camera_globo.dart` (`raioNormalizadoGeoide` e `construirCaminhoSilhuetaGeoide`) | Modela o achatamento polar e as anomalias gravitacionais reais da Terra (Baixa do Oceano Índico `-106m`, Alta da Nova Guiné `+85m`, Atlântico Norte `+68m`, Cordilheira Andina `+42m` e Mar de Ross `-62m`) na silhueta e na malha 3D do planeta. | **Domínio Público** (*NASA GSFC / NGA*). |
| **Textura Esférica Fotorrealista da Terra (`4096×2048`)** | **NASA Visible Earth — Blue Marble** (espelhos CDN: `cdn.jsdelivr.net/npm/three-globe/example/img/earth-blue-marble.jpg` e `unpkg.com/three-globe/...`) | `frontend/tool/gerar_malha_geografica_offline.dart` $\rightarrow$ `frontend/assets/geometria/textura_globo_nasa.jpg` $\rightarrow$ `malha_relevo_lod.dart` / `superficie_globo_explorar.dart` | Embarcada no pacote do aplicativo (`~1,46 MB`, decodificada em resolução nativa `4096×2048` 4K sem *downsampling*) para projeção equiretangular esférica nítida no globo 3D e no mapa 2D com `0` requisições de *tiles* em tempo de execução. | **Domínio Público** (*NASA Earth Observatory / Visible Earth*). |
| **Modelo Digital de Elevação (DEM `30m` — NASA SRTM GL1 / NASADEM)** | **AWS Registry of Open Data — Mapzen Terrain Tiles** (`https://s3.amazonaws.com/elevation-tiles-prod/terrarium/12/{x}/{y}.png`) | 1. Semente offline: `gerar_malha_geografica_offline.dart` $\rightarrow$ `frontend/assets/dados/altimetria_picos_inicial.json`<br>2. Coleta incremental: `supabase/functions/sincronizar-clima-picos/index.ts` $\rightarrow$ `public.snapshots_altimetria_picos`<br>3. Consumo: `servico_clima_altimetria.dart` e `malha_relevo_lod.dart` | Decodifica *tiles* PNG `256×256` Terrarium (`elev_m = R*256 + G + B/256 - 32768`, `~35 m/px` no zoom `12`) extraindo `altitude_base_m`, `altitude_pico_m` e uma grade real `13×13` (`±0,024°` / `~2,7 km`) por pico. Alimenta o selo `Alt. <N>m` nos cards e o relevo 3D real com sombreamento Gouraud e curvas de nível (`250m` no `LOD 2`, `80m` no `LOD 3` e `15m` em *close-up* `LOD 4+`). | **Domínio Público / Dados Abertos** — Dados primários NASA/USGS SRTM; compilação Terrain Tiles por Mapzen/Tilezen no AWS Open Data. |
| **Malha Viária para Distância e Tempo de Viagem Offline** | **OpenStreetMap (OSM) & Overpass API** (processado no repositório irmão `aresta_db` por `gerar_malha_estrada_lib.py` e compilado em `catalogo.db`) | `frontend/assets/preload/catalogo.db` (`catalogo_nos_estrada` e `catalogo_distancias_estrada`) $\rightarrow$ `repositorio_catalogo.dart` $\rightarrow$ `calculadora_distancia_estrada.dart` | Pré-calcula por Dijkstra os caminhos mais rápidos sem trânsito (ponderando `highway`, `maxspeed` e `surface`) em raio de até `~200 km` de cada pico. No celular, uma KD-Tree em memória estima em `< 1 ms` e 100% offline o tempo (`~40 min`, `~1h 20min`) e a distância rodoviária real a partir do GPS do usuário. | **ODbL 1.0** (*Open Database License* — `© Contribuidores do OpenStreetMap`). |
| **Navegação Veicular Externa até o Estacionamento/Pico** | **Google Maps Universal Cross-Platform URLs** (`https://www.google.com/maps/search/?api=1&query=<lat>,<lon>` ou link curto salvo no croqui) | `frontend/lib/utils/categorizacao_pico.dart` (`resolverUrlGoogleMapsPico`) e subpágina `Explorar Local` em `pico.dart` | Acionado via `url_launcher` apenas quando o usuário toca para abrir rotas no aplicativo de mapas do sistema, evitando o peso de memória e chaves pagas de SDKs nativos de mapa embarcado. | Termos padrão de abertura de links públicos do navegador/SO (sem SDK embarcado). |

---

## 3. Fontes Meteorológicas e Motor `RainTracker`

O subsistema climático avalia tanto **tempestades ao vivo em curso** quanto a **umidade residual da rocha nos últimos 5 dias** sem expor os dispositivos móveis a chamadas diretas de APIs meteorológicas externas.

| Recurso | Provedor & Endpoint | Onde é Processado e Consumido | Detalhamento Técnico | Licença e Atribuição |
|---|---|---|---|---|
| **Histórico Diário de Precipitação por Pico (5 dias)** | **Open-Meteo Forecast API** (`https://api.open-meteo.com/v1/forecast?latitude=...&longitude=...&daily=precipitation_sum&past_days=5&forecast_days=1&timezone=UTC`) | Coletado em lotes de até `45` picos por `supabase/functions/sincronizar-clima-picos/index.ts` $\rightarrow$ salvo em `public.estado_clima_picos` (`chuva_por_pico`) $\rightarrow$ avaliado localmente por `calculadora_umidade_pico.dart` e exibido por `selo_umidade_pico.dart` | Alimenta a curva determinística de secagem de 5 dias: precipitação $\ge 15\text{ mm}$ inicia em **Muito molhado** (`2d` $\rightarrow$ Molhado `2d` $\rightarrow$ Levemente molhado `1d` $\rightarrow$ Seco); $5\text{–}15\text{ mm}$ inicia em **Molhado** (`3d` totais); $1\text{–}5\text{ mm}$ inicia em **Levemente molhado** (`1d`). Exibido nos cards de `Explorar`, nas pílulas expandidas da lupa no globo e na tela `PicoDetailsPage`. | **CC BY 4.0** — Dados meteorológicos por [Open-Meteo.com](https://open-meteo.com/) (modelos públicos NOAA GFS, ECMWF IFS, DWD ICON e CPTEC/INPE). |
| **Malha Sinótica 2D de Tempestades ao Vivo, Rastro Histórico (`-6h` / `-3h`) e Vento (`10m`)** | **Open-Meteo Forecast API** (`https://api.open-meteo.com/v1/forecast?latitude=...&longitude=...&current=precipitation,rain,showers,wind_speed_10m,wind_direction_10m&hourly=precipitation&past_hours=6&forecast_hours=1&timezone=UTC`) | Coletado em lotes de até `85` células por `supabase/functions/sincronizar-clima-picos/index.ts` $\rightarrow$ salvo em `public.estado_clima_picos` (`bolhas_chuva` + `rastros_passados`) $\rightarrow$ renderizado a `60fps` por `pintor_tempestade_globo.dart` | Agrupa os picos em regiões sinóticas, amostra uma grade `8×8` a `14×14`, aplica filtro convolucional `3×3`, extrai isoietas fechadas reais (`0,15 mm/h` para a frente externa, `1,8 mm/h` para núcleos convectivos fortes e pegadas passadas em `-6h` e `-3h`) via **Marching Squares** + suavização **Chaikin** e anima partículas de chuva proporcionais à área em tela alinhadas ao vetor real de avanço do vento (`wind_direction_10m + 180°`). Expira automaticamente após `6h` sem sincronização. | **CC BY 4.0** — [Open-Meteo.com](https://open-meteo.com/). |
| **Monitoramento Orbital de Incêndios Florestais (`FRP MW` e Plumas de Fumaça)** | 1. **NASA FIRMS** (`https://firms.modaps.eosdis.nasa.gov/api/area/csv/<KEY>/VIIRS_SNPP_NRT/...` — sensor **VIIRS 375m**)<br>2. **INPE BDQueimadas** (`https://dataserver-coids.inpe.br/queimadas/queimadas/focos/csv/diario/Brasil/focos_diario_br_YYYYMMDD.csv` — sensores **NASA MODIS + NASA/NOAA VIIRS 375m + GOES-19**) | Coletado por `supabase/functions/sincronizar-clima-picos/index.ts` $\rightarrow$ salvo em `public.estado_clima_picos` (`bolhas_incendio`) $\rightarrow$ renderizado por `pintor_incendio_globo.dart` | Tenta primariamente a API **NASA FIRMS (`VIIRS 375m`)** quando `NASA_FIRMS_MAP_KEY` está definida; caso ausente, alterna automaticamente para o Dataserver aberto do **INPE BDQueimadas** (sensores **NASA MODIS/VIIRS**). Descarta falsos positivos de baixa confiança (`confidence = l`), chaminés siderúrgicas/industriais (`id_area_industrial > 0`) e pixels sob precipitação ativa (`Open-Meteo` / `bolhas_chuva`), agrupa clusters reais (`\ge 3` focos ou `FRP \ge 20 MW`) em malha fina (`~2,2 km`) + **Marching Squares / Chaikin** e renderiza colunas volumétricas de fumaça a sotavento, chamas pulsantes e fagulhas ascendentes sem sobreposição com chuva. | **Domínio Público / Dados Abertos** — **NASA LANCE / FIRMS** e **INPE Programa Queimadas**. |

> [!NOTE]
> **Por que Open-Meteo em vez de NASA POWER para chuva?** A API satelital `NASA POWER` (`PRECTOTCORR`) apresenta latência de calibração de `2 a 3 dias` e grade espacial de `~55 km`, o que omitiria chuvas ocorridas na véspera ou na madrugada da escalada. Por isso, a **NASA (SRTM 30m)** é usada para a topografia estática de alta resolução e o **Open-Meteo** para precipitação e vento em tempo real.

---

## 4. Infraestrutura Própria e APIs do Ecossistema Aresta

Todos os contratos REST, SQL e binários abaixo são formalmente especificados no submódulo [`frontend/lib/aresta_api`](../../frontend/lib/aresta_api/README.md) (`proto/`, `sql/` e `openapi/`).

| Serviço / Domínio | Tecnologia Hospedeira | Contrato / Módulo Consumidor | Finalidade no Ecossistema |
|---|---|---|---|
| **`https://serving.arestaclimb.com/v4`**<br>*(fallback legado: `aresta-climb.github.io/aresta_serving`)* | **Cloudflare CDN / R2** | `proto/indice.proto`, `proto/croqui.proto` $\rightarrow$ `constantes_rede.dart`, `sync_service.dart`, `sync_isolate.dart`, `servico_croqui_online.dart` | Distribuição estática de `indice.binarypb`, snapshots completos `catalogo.db.gz`, pacotes `<picoId>/compilado.binarypb` e imagens WebP de setores/capas, com suporte a `ETag` (`HTTP 304`), consulta online sob demanda (`?v=<sha256>`) e validação criptográfica `SHA-256` em `Isolate`. |
| **`https://catalogo.arestaclimb.com`** | **Cloudflare Workers + Cloudflare D1** (`aresta-catalogo`) | `openapi/catalogo.yaml`, `sql/catalogo_d1.sql` $\rightarrow$ `repositorio_catalogo.dart`, `sync_rede.dart` | Sincronização incremental (`GET /v1/catalogo/deltas?versao_local=...&versao_destino=...`) que condensa mutações de croquis, vias, setores e malha de estradas em payloads JSON de `~1,5 KB` (`apply_delta`) ou orienta `full_download` quando a defasagem excede a janela de deltas. |
| **`https://aresta.cc`** e **`https://arestaclimb.com/croquis`** | **Cloudflare Workers + Cloudflare Pages + D1** | `openapi/app_links.yaml` $\rightarrow$ `servico_compartilhamento.dart`, `analisador_rotas_deep_link.dart`, `servico_navegacao_deep_link.dart` | Encurtador canônico de 32 caracteres para **placas físicas de aço inox AISI 316L com QR Code V3 Nível H** (`/q/<uid>`, `/qm/<uid>`), compartilhamento no app (`/s/<uid>`, `/sm/<uid>`), vitrine web SSR indexável (`/croquis/<uid>/<slug>`) e hospedagem dos manifestos nativos `/.well-known/assetlinks.json` (Android App Links) e `/.well-known/apple-app-site-association` (iOS Universal Links). |
| **`https://previa.arestaclimb.com`** | **Cloudflare Workers + Durable Objects** (`WebSocket`) | `openapi/previa.yaml`, `proto/croqui_experimental.proto` $\rightarrow$ `editor_croqui.dart` | Retransmissor global de sessões de **Live Reload / Modo Experimental** pareadas por QR Code ou código de 8 caracteres (`K9X2-P83A`), conectando o **Aresta Editor Desktop** ao celular via LAN local ou túnel `wss://`. |
| **`https://feedback.arestaclimb.com`** | **Cloudflare Workers** (Proxy CDN sobre Supabase Storage) | `openapi/feedback.yaml` | Proxy público com cache imutável de 1 ano (`max-age=31536000, immutable`) para exibir capturas de tela (`/anexos/*`) nas Issues abertas no GitHub e redirecionar mantenedores autenticados aos diagnósticos restritos (`/diagnostico/{id}`). |
| **`https://alertas.arestaclimb.com`** | **Cloudflare Workers + Cloudflare KV** (`FILA_RETENTATIVAS_ALERTAS`) | Documentado em [`docs/guia_configuracao_observabilidade_e_alertas.md`](../guia_configuracao_observabilidade_e_alertas.md) | Roteador operacional autenticado via `HMAC-SHA256` para webhooks do Sentry e da organização GitHub `aresta-climb`, despachando notificações para `ntfy`, Discord, WAHA e Resend. |
| **`https://fixalog.app`** | **Cloudflare Workers + R2 (`fixalog-laudos`) + D1** | `openapi/fixalog.yaml`, `sql/fixalog_d1.sql` (no submódulo `aresta_api`) | API irmã do ecossistema para laudos periciais assinados criptograficamente (`ECDSA secp256r1` + atestado OIDC) de equipamentos e ancoragens em contêineres `.epub`. |

---

## 5. Autenticação, Integridade de Dispositivo e Armazenamento em Nuvem

### 5.1. Supabase (`https://yzkhiaoqtxvvcyyuwmqg.supabase.co` e função dedicada de feedback)
O aplicativo comunica-se com o **Supabase** por HTTP puro encapsulado em `ClienteHttpAresta` (sem depender de SDK monolítico acoplado à camada de UI), utilizando chaves públicas configuráveis via `RemoteConfigService` ou `--dart-define`:

| Subsistema Supabase | Tabelas / Rotas / Buckets | Módulos no Repositório | Responsabilidade e Segurança |
|---|---|---|---|
| **Supabase Auth (GoTrue)** | `/auth/v1/otp`, `/auth/v1/verify`, `/auth/v1/token?grant_type=id_token`, `/auth/v1/token?grant_type=pkce`, `/auth/v1/user` | `frontend/lib/services/autenticacao/` (`cliente_supabase_autenticacao.dart`, `autenticador_nativo.dart`, `servico_autenticacao.dart`) | Autenticação 100% **sem senha**:<br>• **Google Sign-In**: `CredentialManager` nativo no Android (com fallback OAuth PKCE `S256` em Custom Tabs) e `ASWebAuthenticationSession` no iOS.<br>• **Sign in with Apple**: `ASAuthorizationAppleIDProvider` nativo no iOS.<br>• **Código OTP de 6 dígitos por e-mail**: disparado via SMTP/Resend (`login.arestaclimb.com`). |
| **PostgreSQL + Row Level Security (RLS)** | • `public.perfis`<br>• `public.cadenas`<br>• `public.fila_interacoes`<br>• `public.estado_clima_picos`<br>• `public.snapshots_altimetria_picos` | Schemas em [`docs/arquitetura/sql/`](../arquitetura/sql/README.md); clientes em `sincronizador_perfil_supabase.dart`, `cliente_cadenas_supabase.dart`, `cliente_fila_interacoes_supabase.dart` e `servico_clima_altimetria.dart` | • `perfis`: vincula `auth.uid()` ao `autor_id_publico` (NanoID 14c), `autor_nome_publico` e `avatar_url`.<br>• `cadenas`: backup privado da caderneta esportiva isolado por RLS (`auth.uid() = user_id`).<br>• `fila_interacoes`: buffer horário de votos de grau, comentários de beta (com foto de perfil) e alertas de segurança estilo Waze (`FAUNA`, `ROCHA_AGARRA_INSTAVEL`, `PROTECAO_PRECARIA`, `EXPOSICAO_E4_MAIS`), drenado pelo *Aresta Bot* para YAML aberto sob ODbL em `aresta_db`.<br>• `estado_clima_picos` e `snapshots_altimetria_picos`: leitura pública `SELECT` em 2 slots (`atual` / `copia_seguranca`), escrita exclusiva `service_role`. |
| **Supabase Storage** | • Bucket `avatars`<br>• Bucket `feedback_anexos` | `sincronizador_perfil_supabase.dart`, `seletor_foto_perfil.dart`, `feedback_network_service.dart` | • `avatars/<userId>/avatar.webp`: foto de perfil recortada em quadrado `256×256`, corrigida por orientação EXIF e comprimida em WebP.<br>• `feedback_anexos`: capturas de tela anotadas e snapshots `.binarypb` anexados a relatos de bug. |
| **Supabase Edge Functions (Deno)** | • `POST /functions/v1/sincronizar-clima-picos`<br>• `POST /functions/v1/app-feedback`<br>• `POST /functions/v1/git-proxy` & `create-pr`<br>• `POST /functions/v1/excluir-conta` (RPC/Auth) | `supabase/functions/sincronizar-clima-picos/index.ts`, `feedback_network_service.dart`, `openapi/colaboracao.yaml`, `openapi/feedback.yaml` | • `sincronizar-clima-picos`: consolida Open-Meteo + NASA SRTM 30m a cada 3h via `pg_cron`.<br>• `app-feedback`: valida **Firebase App Check**, grava diagnóstico restrito e abre Issue pública no GitHub.<br>• `git-proxy` / `create-pr`: permite que colaboradores enviem croquis pelo Editor Desktop sem precisar de conta ou chave SSH no GitHub. |

### 5.2. PowerSync (`powersync_sync_rules.yaml`)
- Regras declarativas de replicação em [`docs/arquitetura/sql/powersync_sync_rules.yaml`](../arquitetura/sql/powersync_sync_rules.yaml) (`bucket_usuario`) sobre a publicação lógica `powersync` do PostgreSQL para sincronização offline-first das tabelas `perfis` e `cadenas`.

### 5.3. Atestação de Integridade de Hardware (Firebase App Check)
- **Android**: **Google Play Integrity API** (com `AndroidDebugProvider` restrito a builds locais de desenvolvimento).
- **iOS**: **Apple App Attest / DeviceCheck** (com `AppleDebugProvider` em desenvolvimento).
- Isolado em `frontend/lib/services/firebase/validador_app.dart` e exigido no cabeçalho `X-Firebase-AppCheck` pelos endpoints públicos sensíveis (como envio de feedbacks e registro de chaves).

---

## 6. Observabilidade, Telemetria e Roteamento Operacional de Alertas

Todo acesso a SDKs de telemetria e logs no cliente Flutter é arquiteturalmente confinado à pasta `frontend/lib/services/firebase/` (garantido pelos testes `firebase_isolation_test.dart` e `isolamento_logs_arquitetura_test.dart`).

| Plataforma / Serviço | Pacote / Integração | Papel no Projeto |
|---|---|---|
| **Sentry (Plano Open Source Patrocinado)** | `sentry_flutter` (`^10.2.0`) + `sentry_dart_plugin` (`^3.4.0`), org `aresta-climb`, projeto `aresta-app` | Captura de exceções não-fatais, crashes fatais, *breadcrumbs* de navegação/sincronização com fila offline, upload automático de símbolos Dart/nativos e *source maps* no CI (`SENTRY_AUTH_TOKEN`), *PII Data Scrubbing* sem retenção de IP e abertura/sincronização bidirecional automática de **GitHub Issues** em erros inéditos (*First Seen*). |
| **Firebase Crashlytics** | `firebase_crashlytics` (`^6.0.1`) | Monitoramento complementar de estabilidade nativa/Dart em Android e iOS, com upload automatizado de `dSYMs` (iOS) e `.symbols` / `mapping.txt` R8 (Android) nos workflows de release. |
| **Google Analytics for Firebase (GA4)** | `firebase_analytics` (`^13.0.1`) | Métricas anônimas de uso e navegação (eventos e parâmetros em português em `telemetria.dart`), desativadas automaticamente em `kDebugMode`. |
| **Firebase Performance Monitoring** | `firebase_performance` (`^0.12.1`) | Medição de *traces* críticas (`cold_start_home`, `cold_start_deep_link`, `sync_index_fase1`, `sync_index_fase2`, `abrir_croqui`, `abrir_mapa_interativo`) e fluidez de quadros (`fluidez_sessao_tela`) segmentadas por faixa de RAM do aparelho (`ClassificadorDispositivo`). |
| **Firebase Remote Config** | `firebase_remote_config` (`^7.0.1`) | Configuração remota com cache de 12h e valores locais padrão imediatos para `supabase_url`, `supabase_anon_key`, `feedback_edge_function_url` e `serving_base_url`. |
| **Umami Analytics (Web)** | Autohospedado em **Vercel** (`https://analytics.arestaclimb.com`) + PostgreSQL Supabase | Telemetria web anônima e sem cookies (`< 2 KB`, aderente à LGPD/GDPR sem banner de cookies) utilizada no portal institucional `arestaclimb.com` e na vitrine web `/croquis`. |
| **`ntfy` (`https://ntfy.sh`)** | Push HTTP via `aresta-alertas-worker` | Pager móvel imediato para a equipe de engenharia (prioridade máxima `5` para emergências e `3` para bugs/feedbacks, com botões diretos para Sentry, GitHub e Discord). |
| **Discord (Webhooks & Comunidade)** | Webhooks via `aresta-alertas-worker` + convite público em `constantes_rede.dart` | Mural técnico somente-leitura (`#🚨-emergencias` e `#🛠️-bugs-e-feedbacks`) para auditoria de incidentes e servidor aberto da comunidade de desenvolvedores. |
| **WAHA (`devlikeapro/waha:noweb`) + GCP `e2-micro` + Cloudflare Tunnel** | Docker Compose + `cloudflare/cloudflared` | Gateway WhatsApp autohospedado sem portas públicas expostas, mantido provisionado em *standby* na camada gratuita (*Always Free*) do Google Cloud Compute Engine. |
| **Resend (`https://resend.com`)** | Domínio autenticado `login.arestaclimb.com` | Disparo transacional dos e-mails de código OTP do Supabase Auth e canal automático de contingência (`alerta@login.arestaclimb.com` $\rightarrow$ `contato@arestaclimb.com`) caso os canais primários de alerta sofram indisponibilidade. |

---

## 7. Repositórios Acoplados e Submódulos Git

Este repositório integra dois **submódulos Git** declarados em [`.gitmodules`](../../.gitmodules) e opera em conjunto com outros dois repositórios da organização [`github.com/aresta-climb`](https://github.com/aresta-climb):

