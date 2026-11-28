# Supabase Edge Functions (`supabase/`)

Este diretório contém as **Supabase Edge Functions** (runtime Deno / TypeScript) mantidas diretamente junto ao repositório do aplicativo móvel.

> Para o inventário completo de todas as APIs, tabelas Supabase, políticas RLS, fontes científicas (NASA SRTM, IBGE, Open-Meteo, OpenStreetMap) e serviços em nuvem do projeto, consulte **[`docs/recursos/README.md`](../docs/recursos/README.md)**.

---

## Funções Disponíveis

### `functions/sincronizar-clima-picos/`
Coletor modular servidor-a-servidor acionado periodicamente a cada **3 horas** (`0 */3 * * *` via `pg_cron` + `pg_net`, conforme [`docs/arquitetura/sql/supabase_clima_e_altimetria_picos.sql`](../docs/arquitetura/sql/supabase_clima_e_altimetria_picos.sql)):

| Módulo | Responsabilidade |
|---|---|
| `index.ts` | Ponto de entrada `Deno.serve`: autentica o disparo (`service_role` ou `CRON_SECRET`) e orquestra as etapas transacionais. |
| `tipos_clima.ts` | Constantes físicas/endpoints e contratos tipados de altimetria, tempestades e incêndios. |
| `decodificador_indice_protobuf.ts` | Leitor zero-dependência de `indice.binarypb` (`Varint` + `ZigZag`). |
| `altimetria_srtm.ts` | Extração incremental de base, cume e malha DEM `13×13` (`30m`) a partir de *tiles* PNG `Terrarium z=12` (`NASA SRTM`). |
| `geometria_contornos.ts` | Agrupamento sinótico ampliado (`margem 5,2°`), isolinhas via **Marching Squares**, suavização **Chaikin**, reamostragem e *point-in-polygon*. |
| `radar_chuva_rainviewer.ts` | Mosaico composto global de radares meteorológicos + satélite infravermelho em tempo real (`RainViewer z=6`, `~2,2 km/px`) decodificado nativamente via `DecompressionStream("deflate")`. |
| `tempestades_open_meteo.ts` | Precipitação horária observada de 5 dias no fuso civil local (`timezone=auto`, sem previsão futura) e fusão radar + vento mesoescala (`Open-Meteo` sobre malha `~15 km`) preservando bolsões locais de chuva e extraindo isoietas internas aninhadas (`1,8 mm/h` e `5,5 mm/h`). |
| `incendios_satelite.ts` | Coleta orbital de focos termais (`NASA FIRMS VIIRS 375m` $\rightarrow$ `INPE BDQueimadas`), filtragem contra áreas industriais e chuva ativa, e extração de perímetros e núcleos termais aninhados (`20 MW` e `48 MW`). |
| `malha_viaria_osm.ts` | Extração incremental via Overpass API exclusivamente das rodovias federais principais (`BR-xxx`) na região de escalada sempre que o hash do catálogo de picos mudar. |
| `cliente_supabase_slots.ts` | Leitura de snapshots existentes e invocação das RPCs PostgREST que rotacionam `atual` $\rightarrow$ `copia_seguranca` nas tabelas de clima, altimetria e malha viária. |

#### Variáveis de Ambiente Exigidas
| Variável | Obrigatória | Descrição |
|---|---|---|
| `SUPABASE_URL` | Sim | URL base do projeto Supabase (injetada automaticamente pelo runtime do Supabase). |
| `SUPABASE_SERVICE_ROLE_KEY` | Sim | Chave `service_role` autorizada a invocar as RPCs de rotação e autenticar o disparo. |
| `CRON_SECRET` | Não | Segredo alternativo opcional aceito no cabeçalho `Authorization: Bearer <token>`. |
| `ARESTA_SERVING_INDICE_URL` | Não | Sobrescreve a URL padrão de `indice.binarypb` (`https://serving.arestaclimb.com/v4/indice.binarypb`). |
| `NASA_FIRMS_MAP_KEY` | Não | Chave opcional da API NASA FIRMS (`VIIRS_SNPP_NRT`); quando ausente, a função utiliza automaticamente o feed aberto INPE BDQueimadas (sensores NASA MODIS/VIIRS). |

#### Deploy Manual (Requer `supabase login` ou `SUPABASE_ACCESS_TOKEN`)
```bash
npx supabase functions deploy sincronizar-clima-picos --project-ref yzkhiaoqtxvvcyyuwmqg
```
