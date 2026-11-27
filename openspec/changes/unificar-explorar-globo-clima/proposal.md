## Why

Hoje a descoberta de picos está dividida entre a lista da aba `Explorar` (`BrowsePage`) e uma rota secundária pouco utilizada (`MapaGlobalPage`), acoplada ao SDK externo `google_maps_flutter` (dependente de tiles online e pesada em aparelhos modestos). Além disso, o escalador não consegue filtrar picos do catálogo nacional por faixa de graduação antes de baixar cada croqui, nem saber se choveu recentemente na região de um pico específico.

Unificar a aba `Explorar` sobre um globo e terreno vetorial offline em 4 níveis de detalhe (LODs), aliado a filtros completos de dificuldade/modalidade e a um indicador contextual de chuva e secagem regional (`RainTracker`), resolve a descoberta geográfica e climática em uma única tela rápida e funcional mesmo sem internet.

## What Changes

- **Fusão da Aba `Explorar` e Remoção Limpa de `MapaGlobalPage`**:
  - A aba `Explorar` passa a exibir o mapa interativo em tela cheia com alternância `3D <-> 2D` e uma gaveta inferior deslizante em três estágios (`Mapa`, `Dividir`, `Lista`).
  - Remoção integral de `MapaGlobalPage`, `MapaGlobalViewModel`, `MapaGlobalNode` e `AppNav.toMapaGlobal` (corte limpo conforme Princípio VIII do `AGENTS.md`).
- **Motor Gráfico Vetorial Offline em 4 LODs Contínuos**:
  - `LOD 0` (Globo): esfera 3D giratória com inércia, contornos continentais/brasileiros e agrupamento limpo de picos por estado (`UF`).
  - `LOD 1` (Região): divisas estaduais oficiais (malha IBGE simplificada `< 400 KB`), bolhas regionais de chuva e pinos sem sobreposição de texto.
  - `LOD 2` (Serra e Vale): inclinação progressiva de câmera, relevo regional sombreado e curvas de nível de `250m`.
  - `LOD 3` (Maciço 3D): relevo local simulado deterministicamente pela altitude real do pico, curvas de `80m`, cume com altitude e traçado animado da trilha de aproximação.
- **Interações Sincronizadas e Micro-Animações (`< 4ms`/frame)**:
  - Toque em um pino no mapa abre/ajusta a gaveta (se recolhida), executa auto-scroll suave até o card correspondente e dispara pulso visual no card e onda sonar no pino (realçando a bolha de chuva associada quando o pico estiver úmido).
  - Seleção de pico distante executa câmera em arco parabólico (`Fly-To`).
  - Altura da gaveta acoplada continuamente ao centro óptico do mapa.
- **Busca Robusta, Filtro Rápido de Grau e Modal de Filtros**:
  - Barra superior com busca difusa, seletor rápido de dificuldade (`Grau`) ao lado da busca e botão `Filtros e Ordenação` (alinhado ao `PainelFiltrosIndice`).
  - Filtragem offline de todo o catálogo por faixa de grau de Vias (`1º` a `12a`) e Boulder (`V0` a `V15`) agregando `catalogo_aresta` (`catalogo.db`), além de tags de modalidade (`Esportiva`, `Boulder`, `Móvel / Trad`, `Paredão`, `Highline`), ordenação e distância.
- **Sistema Contextual de Chuva (`RainTracker`), Altimetria NASA 30m e Cópia de Segurança Rotativa**:
  - Agregador agendado no Supabase (`pg_cron` a cada 3h + Edge Function) consultando precipitação dos últimos 5 dias (`Open-Meteo Forecast API`) e altimetria satelital de 30m (`NASA NASADEM / SRTM GL1`) e publicando resumos compactos (`~5 KB`) em `public.estado_clima_picos` e `public.snapshots_altimetria_picos`.
  - **Armazenamento com 1 Cópia de Segurança (`atual` + `copia_seguranca`)**: Tanto nas tabelas do Supabase quanto no gerador de malhas IBGE/NASA e no cache local do aplicativo, cada coleta nova íntegra rotaciona a versão vigente para a única cópia de segurança (descartando dados mais antigos) antes de assumir `atual`, protegendo o sistema contra quedas frequentes dos serviços do IBGE ou da NASA.
  - Curva determinística local de 5 dias: `Muito molhado` (`>= 15mm`, 2 dias) -> `Molhado` (`5–15mm`, 2 dias) -> `Levemente molhado` (`1–5mm`, 1 dia) -> `Seco`.
  - Exibição estritamente contextual: picos secos permanecem neutros sem selos meteorológicos; o indicador azul/musgo, a data da chuva (`Chuva dia DD/MM`) e o tempo estimado de secagem só aparecem nos picos impactados por chuva ativa.

## Capabilities

### New Capabilities
- `exploracao-globo-e-clima`: Descoberta unificada de picos sobre globo/relevo vetorial offline em 4 LODs, gaveta deslizante sincronizada, filtros de grau/modalidade no catálogo e alertas contextuais de chuva e altimetria externa.

### Modified Capabilities
- `estabilidade-mapa-marcadores`: Remoção dos requisitos exclusivos da antiga tela `MapaGlobalPage` em Google Maps, mantendo apenas as garantias aplicáveis aos mapas internos de croquis/setores.

## Impact

- **Backend / Infraestrutura (`docs/arquitetura/sql/` e Supabase)**: Novas tabelas públicas de leitura `public.estado_clima_picos` e `public.altimetria_picos` + especificação da Edge Function agendada de 3h.
- **Assets e Ferramentas (`frontend/assets/`, `frontend/tool/`)**: Script gerador e binário compacto da malha geográfica IBGE/Natural Earth (`< 400 KB`) + semente inicial de altimetria offline.
- **Serviços e Catálogo (`frontend/lib/services/`)**: `RepositorioCatalogo` (resumo de graus por croqui), `ClienteClimaAltimetriaSupabase`, `ArmazenamentoClimaLocal`, `CalculadoraUmidadePico` e Fake determinístico testado (`*_fake.dart` + `*_fake_test.dart`).
- **Apresentação e Navegação (`frontend/lib/pages/`, `widgets/`, `view/`, `navigation/`)**: Reforma de `BrowsePage` / `BrowseViewModel`, criação dos widgets modulares do globo/terreno e gaveta, e remoção limpa de `MapaGlobalPage` / `MapaGlobalNode`.
- **Testes (`frontend/test/`)**: Espelhamento 1:1 com 100% de cobertura comportamental via TDD.
