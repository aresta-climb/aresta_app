## Why

Com a adição do suporte a desenho vetorial de vias no editor de mapas do Aresta DB, os croquis passam a contar com geometrias de linhas curvas suaves exportadas em formato SVG Path (`caminho_svg`), acompanhadas de cores customizadas (`cor`), estilos de traço (tracejado, sólido) e marcadores tipados (base, cruxes, paradas). O aplicativo móvel (`aresta_app`) atualmente apenas reconhece marcadores de área fechada legados (círculo, quadrado, retângulo, polígono), sendo incapaz de renderizar as linhas de vias sobre as fotos dos setores, de detectar toques ao longo de traçados curvos finos, ou de enquadrar e destacar adequadamente a via selecionada.

Esta mudança introduz o suporte completo à renderização acelerada por GPU de traçados vetoriais SVG, detecção precisa de toques com tolerância para dedos em qualquer ponto da linha, auto-zoom adaptativo cobrindo toda a extensão da via, e sistema de *highlight* duplo (halo de destaque contínuo na via ativa e pulso de advertência ao clicar fora), mantendo a biblioteca externa (`path_drawing`) estritamente isolada e verificada por testes arquiteturais.

## What Changes

- **Integração do Protobuf Atualizado:**
  - Atualização dos arquivos gerados do Protobuf (`croqui.pb.dart`) com a nova mensagem `LinhaTrajeto` (`DadosCompiladosLinha`, `MarcadorCompilado`, etc.) e os campos `linha`, `cor` e `texto_visivel` em `Mapa_PontoDeInteresse`.
- **Módulo Isolado de Construção de Trajetos (`TrajetoPathHelper`):**
  - Criação de um helper de domínio puro e autônomo para conversão de strings SVG em `ui.Path` do Flutter e geração de traçados tracejados/pontilhados com base no estilo (`TRACEJADO`, `SOLIDO`, `PONTILHADO`, `CAMINHADA`).
  - Isolamento estrito do pacote `path_drawing`, impedindo que qualquer componente de UI dependa diretamente de bibliotecas de terceiros.
  - Teste automatizado de arquitetura para validar que nenhuma view importe `path_drawing`.
- **Renderização em Camadas com Highlight Dinâmico (`MarkerPainter`):**
  - Camada de halo/glow de destaque contínuo ao redor do SVG da linha selecionada (`strokeWidth` expandido com `MaskFilter.blur`).
  - Contorno de contraste (casing) para legibilidade em fotos com rocha clara ou escura.
  - Suporte ao pulso de advertência (`highlightIntensity > 0`) piscando todas as linhas clicáveis quando o usuário toca em área livre do mapa.
  - Renderização dos marcadores compilados (círculo de base com rótulo/número, "X" para proteções fixas, "XX" para paradas, crux).
  - Suporte à cor hexadecimal (`ponto.cor`) em qualquer ponto de interesse.
- **Interatividade e Hit-Testing Preciso de Curvas:**
  - Cálculo de proximidade euclidiana no `hitTest` com tolerância ergonômica para toque com o dedo (~16dp) ao longo de todo o comprimento da curva.
  - Comportamento de clique fora preservado: toques fora da tolerância da linha passam pelo `HitTestBehavior.deferToChild` e acionam o pulso do mapa.
- **Enquadramento e Auto-Zoom da Linha Completa:**
  - Adaptação do `AreaHelper` e do cálculo de zoom em `_zoomToPoints` para que vias com traçado vetorial utilizem o enquadramento por caixa delimitadora (Bounding Box) abrangendo toda a extensão da via (da base ao topo), mesmo quando compostas por um único item de linha ou por trechos compartilhados.

## Capabilities

### New Capabilities
- `tracados-vetoriais-app`: Módulo de renderização vetorial de trajetos de escalada em SVG, estilos de traço, cores customizáveis, marcadores de nós, halo de highlight e isolamento arquitetural com testes.

### Modified Capabilities
- `interactive-map`: Adição do suporte a `Mapa_PontoDeInteresse_TipoArea.linha`, hit-testing ao longo de curvas abertas e enquadramento automático de vias vetoriais no zoom da câmera.

## Impact

- **Dependências (`pubspec.yaml`):** Adição de `path_drawing: ^1.0.1` e validação com Dart 3.
- **Protobuf (`lib/aresta_api/proto/generated/`):** Atualização dos arquivos compilados Dart do Protobuf (`croqui.pb.dart`).
- **Páginas e Pintores (`lib/pages/mapa_interativo.dart`):** Atualização de `AreaHelper`, `_buildMarkers`, `_zoomToPoints` e `MarkerPainter`.
- **Novo Utilitário (`lib/utils/trajeto_path_helper.dart`):** Utilitário de conversão de caminhos e isolamento de dependência.
- **Testes (`test/`):** Novos testes unitários para `TrajetoPathHelper`, testes de widget para seleção e zoom de linhas, e teste de barreira arquitetural de importações.
