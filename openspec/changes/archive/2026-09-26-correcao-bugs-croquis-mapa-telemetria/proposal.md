## Why

Após as alterações introduzidas no Pull Request #7, foram identificadas regressões e inconformidades arquiteturais críticas no aplicativo:
1. Em `comunidade.dart` e `sobre_time.dart`, a delegação de abertura de links removeu a visibilidade declarativa de telemetria nas telas e ignorou o retorno booleano de `launchUrl`, silenciando falhas de abertura de aplicativos externos no `AppLogger`.
2. Em `extrator_metadados_croqui.dart`, a leitura de arquivos foi codificada com o nome legado `<pico.id>.binarypb` em vez do canônico `compilado.binarypb` e sem os fallbacks mandatórios para cache volátil (`temp_cache`) e rede (CDN).
3. No Mapa Global (`mapa_global.dart` e `mapa_marker.dart`), marcadores com texto embutido criam áreas transparentes laterais de até 75px, fazendo com que o toque em um pino ative indevidamente o pino vizinho.
4. Em `crag_card.dart`, a resolução de imagem utilizava caminhos fixados ignorando `capaPath` e bypassava o cache volátil via `NetworkImage` sem hash SHA-256.

Esta mudança centraliza a resolução de croquis e mídias no `DatasetRepository` e no `ProvedorImagemAresta`, corrige a hitbox dos marcadores no mapa preservando a visualização de rótulos em zoom local, e restabelece o rigor de telemetria e observabilidade.

## What Changes

- **Telemetria e Observabilidade em Comunidade e Sobre o Time**:
  - Validação explícita do retorno `bool` de `launchUrl` em `abrirLinkExterno` e `abrirLinkSobreTime`, registrando `AppLogger.instance.logError` imediatamente quando o sistema operacional não puder abrir a URL.
  - Restauração e instrumentação declarativa de eventos analíticos no `TelemetryService` para todas as interações de `comunidade.dart` (incluindo o card "Sobre o Time" e modal de Termos de Uso) e `sobre_time.dart`.
- **Resolução Canônica de Croquis no Extrator de Metadados**:
  - Substituição da leitura direta e manual de arquivos em `extrator_metadados_croqui.dart` pela delegação ao `DatasetRepository.getCroqui`, garantindo o caminho canônico `compilado.binarypb` (com *lazy rename* de legados) e a cadeia estrita de 4 etapas (RAM ➔ `/downloads` ➔ `/temp_cache` ➔ CDN).
  - Remoção de buscas recursivas manuais em disco em favor da resolução centralizada no `ProvedorImagemAresta`.
- **Desacoplamento de Hitbox dos Marcadores no Mapa Global**:
  - No zoom local (>= 9.0), separação da representação gráfica em dois marcadores independentes:
    1. **Marcador do Pino (`id`)**: textura compacta de 85x85px contendo estritamente o pino gráfico, âncora exata na ponta da agulha (`Offset(0.5, 0.94)`), `zIndex: 2.0` e `onTap` ativo (hitbox cirúrgica sem asas laterais transparentes).
    2. **Marcador do Rótulo (`${id}_rotulo`)**: textura contendo apenas o balão de texto escuro flutuando logo acima do pino, `zIndex: 1.0`, com `consumeTapEvents: false` para repassar toques transparentemente.
- **Resolução Unificada de Imagens em `CragCard`**:
  - Refatoração do `_CragBackgroundWidget` em `crag_card.dart` para consumir o `ProvedorImagemAresta.resolver` com largura de 300px, repassando `capaPath`, `thumbnailUrl` e `checksumSha256Thumbnail` / `checksum`.
  - Eliminação do bypass para `NetworkImage` não cacheado, assegurando o fallback consistente em 3 estágios (1. `/downloads` ou `/thumbnails` locais ➔ 2. `/temp_cache` volátil ➔ 3. CDN remoto com gravação atômica).

## Capabilities

### Modified Capabilities

- `telemetria-interacoes-usuario`: Exigência de validação de sucesso (`bool`) no acionamento de links externos e rastreamento completo de ações nas páginas Comunidade e Sobre o Time.
- `sincronizacao-cache-croquis`: Garantia de uso do caminho canônico `compilado.binarypb` e centralização da hierarquia estrita de resolução (RAM, permanente, volátil, CDN) e cache de capas no `DatasetRepository` e `ProvedorImagemAresta`.
- `estabilidade-mapa-marcadores`: Desacoplamento da hitbox entre pino clicável e balão de texto visual no Mapa Global para prevenir colisões falsas entre picos adjacentes.

## Impact

- **Código Afetado**:
  - `frontend/lib/pages/comunidade.dart`
  - `frontend/lib/pages/sobre_time.dart`
  - `frontend/lib/view_functions/comunidade_functions.dart`
  - `frontend/lib/view_functions/sobre_time_functions.dart`
  - `frontend/lib/services/dataset/metadados/extrator_metadados_croqui.dart`
  - `frontend/lib/pages/mapa_global.dart`
  - `frontend/lib/view_functions/mapa/mapa_global_functions.dart`
  - `frontend/lib/view_functions/mapa/mapa_marker.dart`
  - `frontend/lib/widgets/crag_card.dart`
- **Testes Afetados**:
  - `frontend/test/pages/comunidade_test.dart`
  - `frontend/test/pages/sobre_time_test.dart`
  - `frontend/test/view_functions/comunidade_functions_test.dart`
  - `frontend/test/view_functions/sobre_time_functions_test.dart`
  - `frontend/test/services/dataset/extrator_metadados_croqui_test.dart`
  - `frontend/test/pages/mapa_global_test.dart`
  - `frontend/test/view_functions/mapa/mapa_global_functions_test.dart`
  - `frontend/test/view_functions/mapa/mapa_marker_test.dart`
  - `frontend/test/widgets/crag_card_test.dart`
- **APIs e Dependências**: Sem novas dependências externas; reutilização integral das abstrações `DatasetRepository` e `ProvedorImagemAresta`.
