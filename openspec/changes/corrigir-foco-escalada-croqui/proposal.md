## Why

Ao clicar em "VER NO CROQUI INTERATIVO" a partir de uma página de escalada (via ou boulder), se a rota em questão não for a primeira escalada associada ao Ponto de Interesse (POI) no mapa (por exemplo, sendo a 2ª ou 3ª via conectada àquele marcador), o aplicativo exibe a via errada — abrindo sempre a primeira via do marcador no card inferior e apontando o auto-zoom para ela. 

Isso ocorre porque o componente intermediário `MapasCarrosselPage` não repassa a propriedade `escaladaContextNome` para o `MapaInterativoPage`, fazendo com que este perca o contexto da via de origem e recaia no índice padrão zero. Além disso, quando o usuário transita entre diferentes vias que compartilham a mesma imagem de fundo, o estado do mapa deve atualizar os POIs e o foco da rota de forma reativa via `didUpdateWidget`, preservando a imagem já decodificada na memória e o estado do `InteractiveViewer` sem causar recarregamentos ou oscilações visuais (flicker).

## What Changes

- **Propagação de Contexto no Carrossel**: Passagem explícita de `escaladaContextNome: item.escaladaContextNome` no construtor padrão de `MapaInterativoPage` dentro de `MapasCarrosselPage._defaultMapBuilder`.
- **Sincronização Reativa no Mapa Interativo**: Implementação de tratamento no `didUpdateWidget` de `_MapaInterativoPageState` para detectar mudanças em `initialSelectedId` ou `escaladaContextNome` e atualizar a seleção de POI, o índice de aba focada (`_focusedItemIndex`) e a câmera (`_zoomToPoints`) sem recarregar ou invalidar a imagem de fundo se a mídia for idêntica.
- **Preservação de Posição de Câmera**: Garantia de que a translação e zoom de câmera em `didUpdateWidget` ocorram estritamente se houver mudança real na seleção (`selectionChanged == true`), mantendo pan e zoom manuais intactos em reconstruções cosméticas.
- **Telemetria e Identificação do Nó**: Correção em `_updateFeedbackNode` no `MapaInterativoPage` para referenciar `refs[_focusedItemIndex]` em vez de fixar em `refs.first`.
- **Cobertura de Testes Automatizados**: Adição de testes de widget no `MapasCarrosselPage` e no `MapaInterativoPage` cobrindo o foco correto de escaladas secundárias/terciárias em POIs compartilhados e a reatividade via `didUpdateWidget`.

## Capabilities

### Modified Capabilities
- `multi-map-navigation`: Garantir que o carrossel de mapas repasse `escaladaContextNome` ao `MapaInterativoPage` e que atualizações na rota selecionada sincronizem a seleção de POI e o foco da câmera reativamente sem recarregar o estado da imagem.

## Impact

- **Código Afetado**:
  - `frontend/lib/pages/mapas_carrossel.dart` (`_defaultMapBuilder`)
  - `frontend/lib/pages/mapa_interativo.dart` (`didUpdateWidget`, `_updateFeedbackNode`)
  - `frontend/test/pages/mapas_carrossel_test.dart`
  - `frontend/test/pages/mapa_interativo_test.dart`
- **APIs e Dependências**: Nenhuma alteração de modelo Protobuf ou dependência externa. Mudança puramente interna na camada de apresentação e navegação Flutter.
