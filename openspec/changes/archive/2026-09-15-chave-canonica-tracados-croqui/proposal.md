# Proposta: Chave Canônica Única para Traçados de Croqui e Higiene de Memória

## Why

Atualmente, `ConstrutorCaminhoTrajeto` mantém caches estáticos em memória indexados exclusivamente por `ponto.id`. Como os IDs de traçados vetoriais (`linha_1`, `linha_2`, etc.) são sequenciais e se repetem entre mapas diferentes de um mesmo setor ou pico, ocorre **envenenamento cruzado de cache**: o primeiro mapa carregado na sessão define a geometria de todos os mapas seguintes que compartilham esses IDs. 

Isso gera renderizações inconsistentes, traçados flutuando no céu ou galhos de árvores e linhas desconectadas dos marcadores circulares da rocha ao navegar pelo carrossel ou entre vias de setores distintos.

## What Changes

- **Chave Canônica Composta Obrigatória**: `AreaHelper.getAreaInfo`, `MarkerPainter` e `ConstrutorCaminhoTrajeto` passam a exigir e utilizar uma chave canônica composta no formato `"${mapa.caminhoImagemMapa}#${ponto.id}"`.
- **Eliminação de Fallbacks Ambigüos**: Não haverá fallback silencioso para `ponto.id`. A chave canônica é estritamente obrigatória em tempo de compilação, e todos os testes unitários legados serão atualizados para preenchê-la explicitamente.
- **Isolamento de Cache de Viewport**: O cache de viewport (`_cacheCaminhosViewport`) no `MarkerPainter` indexa o traçado utilizando a chave composta do ponto acrescida das dimensões da tela (`${chaveCanonica}_${constraints.maxWidth.toInt()}x${constraints.maxHeight.toInt()}`), prevenindo colisões entre páginas vizinhas no carrossel de fotos.
- **Higiene de Memória e Ciclo de Vida**: Invocação determinística de `ConstrutorCaminhoTrajeto.limparCache()` em eventos de descarte macro: ao sair da visualização do Pico (retorno para Home / Browse), na conclusão de download/atualização de croqui (`updateDatasetAfterDownload`) e em eventos de Live Reload / recarga de conjunto de dados.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capability necessária -->

### Modified Capabilities
- `tracados-vetoriais-app`: Atualização dos requisitos de cache de caminhos SVG e de viewport para exigir chave canônica composta no formato `${mapa.caminhoImagemMapa}#${ponto.id}` sem fallback silencioso para `ponto.id`, além da adição de requisitos de ciclo de vida e higiene de memória para descarte do cache em eventos macro.

## Impact

- **Código afetado**:
  - `frontend/lib/pages/mapa_interativo.dart` (`AreaHelper.getAreaInfo`, `MarkerPainter`, `_buildMarkers`, `_zoomToPoints`)
  - `frontend/lib/utils/construtor_caminho_trajeto.dart`
  - Pontos de integração do ciclo de vida: `frontend/lib/services/dataset_repository.dart`, `frontend/lib/navigation/navigation_functions.dart`
- **Testes**:
  - Atualização dos testes unitários em `frontend/test/pages/mapa_interativo_test.dart` para fornecer a chave canônica em todas as chamadas a `AreaHelper.getAreaInfo`.
  - Novos testes em `frontend/test/utils/construtor_caminho_trajeto_test.dart` e `frontend/test/pages/mapas_carrossel_test.dart` comprovando a imunidade contra colisões entre mapas com IDs iguais e a higienização de memória.
- **Compatibilidade**: Nenhuma alteração nos formatos Protobuf ou YAML no banco de dados; a mudança é estritamente no cliente móvel.
