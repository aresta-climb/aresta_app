## 1. Configuração de Dependências e Sincronização de Modelos

- [x] 1.1 Adicionar dependência `path_drawing: ^1.0.1` em `frontend/pubspec.yaml` e executar `flutter pub get`
- [x] 1.2 Atualizar os arquivos Dart gerados do Protobuf (`lib/aresta_api/proto/generated/croqui.pb.dart`) com o suporte a `LinhaTrajeto`, `DadosCompiladosLinha`, `MarcadorCompilado` e campos `linha` e `cor`

## 2. Barreira Arquitetural e Módulo de Trajetos (TDD)

- [x] 2.1 [RED] Escrever teste de barreira arquitetural em `frontend/test/architecture/path_drawing_isolation_test.dart` verificando que apenas `lib/utils/construtor_caminho_trajeto.dart` pode importar `package:path_drawing/`
- [x] 2.2 [RED] Escrever suíte de testes unitários em `frontend/test/utils/construtor_caminho_trajeto_test.dart` cobrindo conversão de SVG para `Path`, estilos (sólido, tracejado, pontilhado), cache de instâncias em memória e tratamento defensivo de erros
- [x] 2.3 [GREEN] Implementar a classe `ConstrutorCaminhoTrajeto` em `frontend/lib/utils/construtor_caminho_trajeto.dart` atendendo aos testes unitários e respeitando o isolamento arquitetural

## 3. Geometria de Linhas e Parser de Áreas (TDD)

- [x] 3.1 [RED] Escrever testes unitários em `frontend/test/pages/mapa_interativo_test.dart` para `AreaHelper.getAreaInfo` com `ponto.linha`, verificando limites (bounds AABB) e geometria correspondente
- [x] 3.2 [GREEN] Implementar o tratamento de `Mapa_PontoDeInteresse_TipoArea.linha` no `AreaHelper.getAreaInfo` em `frontend/lib/pages/mapa_interativo.dart`

## 4. Testes de Widget e Interatividade de Toque (Widget-First & TDD)

- [x] 4.1 [RED] Escrever testes de widget em `frontend/test/pages/mapa_interativo_test.dart` simulando toques do usuário em curvas abertas: toque dentro da tolerância de 16dp seleciona a via; toque fora da tolerância dentro da caixa delimitadora não seleciona e propaga toque para o mapa
- [x] 4.2 [RED] Escrever testes unitários para o método `MarkerPainter.hitTest` avaliando o algoritmo de distância euclidiana a segmentos da curva
- [x] 4.3 [GREEN] Implementar no `MarkerPainter.hitTest` a detecção ergonômica de proximidade por segmentos de reta aproximados para traçados de linha aberta

## 5. Renderização em Camadas, Destaque e Pulso Visual (Widget-First & TDD)

- [x] 5.1 [RED] Escrever testes de widget e pintura para traçados vetoriais cobrindo halo de seleção, casing de contraste, cor personalizada (`ponto.cor`), marcadores e pulso de advertência (`highlightIntensity`)
- [x] 5.2 [RED] Escrever testes de widget verificando que linhas não selecionadas ganham halo luminoso pulsante quando o usuário toca no vazio (`highlightIntensity > 0`)
- [x] 5.3 [GREEN] Implementar a pintura em camadas (halo de blur, casing, traço principal e marcadores compilados) no `MarkerPainter.paint`
- [x] 5.4 [GREEN] Integrar o suporte à cor hexadecimal customizada (`ponto.cor`) na pintura do traçado e bordas

## 6. Enquadramento de Câmera e Auto-Zoom Adaptativo (Widget-First & TDD)

- [x] 6.1 [RED] Escrever testes de widget em `frontend/test/pages/mapa_interativo_test.dart` validando que a seleção de uma via com traçado vetorial aplica o enquadramento por caixa delimitadora cobrindo toda a rota da base ao topo (mesmo com um único elemento de linha)
- [x] 6.2 [GREEN] Atualizar a lógica de `_zoomToPoints` em `frontend/lib/pages/mapa_interativo.dart` para aplicar zoom por Bounding Box quando houver elemento do tipo linha

## 7. Documentação, Cobertura Integral e Validação Final

- [x] 7.1 Adicionar docstrings em blocos `///` em todos os métodos, classes e widgets novos ou alterados, explicitando intenções e rationale arquitetural
- [x] 7.2 Atualizar o arquivo de documentação arquitetural `frontend/lib/README.md` descrevendo o subsistema de traçados vetoriais e sua barreira de isolamento
- [x] 7.3 Executar a suíte completa de testes com `flutter test --coverage` garantindo 100% de cobertura nos arquivos modificados/criados e zero regressões em croquis legados
