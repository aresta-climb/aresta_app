## Why

No Mapa Global, todos os marcadores de picos de escalada são renderizados atualmente em tamanho fixo (120px) com balões de texto com até 800px de largura e ativados em qualquer zoom acima de 4.0. Em níveis de zoom regionais e estaduais (ex: Minas Gerais, zoom ~7-8), onde diversos picos ficam geograficamente próximos, os balões de texto e pinos se sobrepõem massivamente, tornando os nomes ilegíveis e cobrindo grandes extensões do mapa. É necessário que os marcadores redimensionem de acordo com o zoom e exibam os rótulos de texto de maneira inteligente e não poluída apenas quando houver aproximação suficiente.

## What Changes

- **Faixas de Zoom (Zoom Tiers)**: Introdução de três faixas de exibição para os marcadores no Mapa Global:
  - *Macro (zoom < 7.0)*: Marcadores pequenos (40px) sem balão de texto.
  - *Regional (7.0 <= zoom < 11.0)*: Marcadores médios (65px) sem balão de texto.
  - *Local (zoom >= 11.0)*: Marcadores completos (85px) com balão de texto contendo o nome do pico.
- **Rótulos de Texto Compactos**: Redefinição do gerador de marcadores com texto (`createCustomMarkerBitmapWithText`), reduzindo o tamanho de fonte, aplicando largura máxima reduzida (~220px) com reticências (`...`) para evitar extravasamento em nomes longos.
- **Transição Eficiente de Zoom**: O listener de câmera no `MapaGlobalPage` (`onCameraMove`) passa a reagir à transição entre as faixas de zoom sem reconstruir bitmaps continuamente durante o gesto, garantindo alta performance de 60fps.
- **Pré-cache e Carregamento Otimizado**: Carregamento dos ícones nas escalas necessárias em lote ou sob demanda para evitar travamentos de GPU ou recriações repetitivas.

## Capabilities

### New Capabilities
None.

### Modified Capabilities
- `estabilidade-mapa-marcadores`: Requisitos de redimensionamento adaptativo de marcadores em faixas de zoom e visibilidade progressiva de rótulos de texto no Mapa Global.

## Impact

- **Código Afetado**:
  - `frontend/lib/pages/mapa_global.dart`
  - `frontend/lib/view_functions/mapa/mapa_global_functions.dart`
  - `frontend/lib/view_functions/mapa/mapa_marker.dart`
  - Testes em `frontend/test/pages/mapa_global_test.dart`, `frontend/test/view_functions/mapa/mapa_global_functions_test.dart` e `frontend/test/view_functions/mapa/mapa_marker_test.dart`.
- **APIs e Dependências**: Nenhuma dependência externa nova é adicionada; utiliza a API existente de `google_maps_flutter` e `Canvas` do Flutter.
