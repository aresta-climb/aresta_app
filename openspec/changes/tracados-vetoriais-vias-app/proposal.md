## Why

Com a adição do suporte a desenho vetorial de vias no editor de mapas do Aresta DB, os croquis passam a contar com geometrias de linhas curvas suaves exportadas em formato SVG Path (`caminho_svg`), acompanhadas de cores customizadas (`cor`), estilos de traço (tracejado, sólido) e marcadores tipados (base, cruxes, paradas). O aplicativo móvel (`aresta_app`) atualmente apenas reconhece marcadores de área fechada legados (círculo, quadrado, retângulo, polígono), sendo incapaz de renderizar as linhas de vias sobre as fotos dos setores, de detectar toques ao longo de traçados curvos finos, ou de enquadrar e destacar adequadamente a via selecionada.

Esta proposta estabelece a arquitetura para renderização acelerada por GPU de traçados vetoriais SVG, detecção ergonômica de toques com tolerância para dedos (~16dp) ao longo de toda a curva, auto-zoom adaptativo cobrindo a extensão completa da via (da base ao topo), e sistema de destaque duplo (halo difuso persistente ao redor do SVG da via selecionada e pulso elástico de advertência ao tocar fora).

Toda a concepção desta mudança adere estritamente aos sete princípios inegociáveis de `PRINCIPIOS.md` do `aresta_app`: nomenclatura e documentação 100% em português brasileiro, modularidade orientada a recursos (*Feature-First*), exigência de 100% de cobertura de testes, ciclo rigoroso de TDD (Test-Driven Development), priorização de testes de widget para validar a experiência do usuário ponta a ponta, simplicidade anti-abstração e documentação contínua abrangente.

## What Changes

- **Integração do Protobuf Atualizado:**
  - Atualização dos arquivos gerados do Protobuf (`croqui.pb.dart`) com a mensagem `LinhaTrajeto` (`DadosCompiladosLinha`, `MarcadorCompilado`, etc.) e os campos `linha`, `cor` e `texto_visivel` em `Mapa_PontoDeInteresse`.
- **Módulo Isolado de Construção de Trajetos (`ConstrutorCaminhoTrajeto`):**
  - Criação da classe utilitária independente `ConstrutorCaminhoTrajeto` em `lib/utils/construtor_caminho_trajeto.dart`, encapsulando o parsing de SVG e a geração de tracejados.
  - Isolamento estrito da biblioteca externa `path_drawing`, prevenindo acoplamento de bibliotecas de terceiros com a UI.
  - Teste automatizado de barreira arquitetural (`test/architecture/path_drawing_isolation_test.dart`) garantindo que nenhum outro arquivo do repositório importe `package:path_drawing/`.
- **Renderização em Camadas com Destaque Visual (`MarkerPainter`):**
  - Renderização de halo difuso (*glow*) de destaque ao redor do traçado SVG da via ativa com `MaskFilter.blur` e largura expandida.
  - Contorno de contraste (*casing*) escuro/claro para preservar legibilidade sobre qualquer tipo de rocha (granito escuro, calcário cinza ou quartzo claro).
  - Pulso elástico de aviso luminoso nas linhas não selecionadas quando o usuário toca em área livre do croqui (`highlightIntensity > 0`).
  - Suporte à cor hexadecimal (`ponto.cor`) em qualquer elemento visual do mapa.
  - Renderização dos marcadores compilados de início/base com número, chapeletas ("X"), paradas ("XX") e cruxes.
- **Interatividade e Detecção Ergonômica de Toques (Hit-Testing):**
  - Cálculo de menor distância euclidiana da coordenada de toque até os segmentos da curva amostrada, com tolerância ergonômica de 16dp.
  - Preservação da propagação de toques distantes via `HitTestBehavior.deferToChild` para acionar a desseleção ou o pulso de destaque no fundo da tela.
- **Enquadramento e Auto-Zoom da Linha Completa:**
  - Atualização do `AreaHelper.getAreaInfo` para suportar `linha` a partir da `caixa_delimitadora` pré-calculada ou do `Path.getBounds()`.
  - Atualização de `_zoomToPoints` para enquadrar vias de traçado vetorial por caixa delimitadora (*Bounding Box*), assegurando visualização da rota integral (base ao topo) mesmo quando associada a um único ponto de interesse.

## Capabilities

### New Capabilities
- `tracados-vetoriais-app`: Módulo de interpretação vetorial de caminhos SVG, estilização de traço, desenho acelerado por GPU com halo de highlight, marcadores semânticos e isolamento arquitetural rigoroso com testes.

### Modified Capabilities
- `interactive-map`: Adição do suporte a `Mapa_PontoDeInteresse_TipoArea.linha`, hit-testing ao longo de curvas abertas e enquadramento automático de vias vetoriais no zoom da câmera.

## Impact

- **Dependências (`frontend/pubspec.yaml`):** Adição de `path_drawing: ^1.0.1`.
- **Protobuf (`frontend/lib/aresta_api/proto/generated/`):** Atualização de `croqui.pb.dart` e arquivos auxiliares.
- **Novo Módulo Utilitário (`frontend/lib/utils/construtor_caminho_trajeto.dart`):** Encapsulamento de caminhos vetoriais com cache de memória.
- **Páginas e Pintores (`frontend/lib/pages/mapa_interativo.dart`):** Suporte a `linha` no `AreaHelper`, `_buildMarkers`, `_zoomToPoints` e `MarkerPainter`.
- **Testes de Arquitetura (`frontend/test/architecture/path_drawing_isolation_test.dart`):** Barreira contra vazamento de importações de terceiros.
- **Testes de Widget e Unidade (`frontend/test/`):** Cobertura de 100% para novos módulos e rotinas modificadas, com TDD estrito.
- **Documentação:** Atualização de `frontend/lib/README.md` documentando o novo subsistema de traçados.
