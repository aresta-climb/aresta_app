## Why

A API (`aresta_api`) foi atualizada para a versão de dados 4, padronizando a nomenclatura das geometrias dos Pontos de Interesse (POI) no mapa e introduzindo a nova geometria de quadrado. O aplicativo frontend precisa ser migrado para suportar a nova versão de dados, do contrário os pontos de interesse no mapa falharão ao carregar.

## What Changes

- **BREAKING**: Atualização do parser de geometrias de POIs (`AreaHelper.getAreaInfo`) no frontend para aceitar a nova nomenclatura.
- Suporte à nova geometria `quadrado` (centro x,y e lado) na visualização interativa do mapa.
- Incremento da constante `kDataVersion` para `4` permitindo ao app baixar dados compatíveis com a nova versão.

## Capabilities

### New Capabilities

### Modified Capabilities
- `interactive-map`: Atualização das propriedades da área e renderização de bounding areas.

## Impact

- **Código**: `frontend/lib/constants/network_constants.dart` e `frontend/lib/pages/mapa_interativo.dart`.
- **Dependências**: A versão atualizada da `aresta_api` já deve estar puxada no submódulo.
- **Sistemas**: O funcionamento visual dos mapas interativos.
