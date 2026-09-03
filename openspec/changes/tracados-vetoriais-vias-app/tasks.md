## 1. Configuração e Sincronização de Modelos

- [ ] 1.1 Adicionar dependência `path_drawing: ^1.0.1` em `frontend/pubspec.yaml` e executar `flutter pub get`
- [ ] 1.2 Atualizar os arquivos Dart gerados do Protobuf (`lib/aresta_api/proto/generated/croqui.pb.dart`) com o suporte a `LinhaTrajeto`, `DadosCompiladosLinha`, `MarcadorCompilado` e campos `linha` e `cor`

## 2. Isolamento de Dependência e Construção de Caminhos (TDD)

- [ ] 2.1 Criar teste de barreira arquitetural em `frontend/test/architecture/dependencias_externas_test.dart` garantindo que nenhum arquivo fora de `lib/utils/trajeto_path_helper.dart` importe `package:path_drawing/`
- [ ] 2.2 Criar suíte de testes unitários em `frontend/test/utils/trajeto_path_helper_test.dart` para parsing de SVG, estilos tracejado/sólido e tratamento defensivo de erros
- [ ] 2.3 Implementar `frontend/lib/utils/trajeto_path_helper.dart` com métodos para obter `Path` nativo, aplicar tracejados e fazer cache em memória

## 3. Geometria de Linhas e Parsing de Áreas

- [ ] 3.1 Adicionar testes unitários em `frontend/test/pages/mapa_interativo_test.dart` para `AreaHelper.getAreaInfo` com `ponto.linha`, verificando bounds e polígono envolvente
- [ ] 3.2 Implementar o suporte a `Mapa_PontoDeInteresse_TipoArea.linha` no `AreaHelper.getAreaInfo` em `frontend/lib/pages/mapa_interativo.dart`

## 4. Detecção Ergonômica de Toques (Hit-Testing)

- [ ] 4.1 Escrever testes unitários para `MarkerPainter.hitTest` avaliando toques próximos à curva (distância <= 16dp -> true) e toques distantes (distância > 16dp -> false)
- [ ] 4.2 Implementar no `MarkerPainter.hitTest` o cálculo de distância euclidiana a segmentos de reta da curva aproximada para caminhos abertos de linha

## 5. Renderização em Camadas, Destaque e Pulso

- [ ] 5.1 Escrever testes de widget e pintura para traçados vetoriais cobrindo halo de seleção, casing de contraste, cor personalizada (`ponto.cor`), marcadores e pulso de advertência (`highlightIntensity`)
- [ ] 5.2 Implementar a renderização em camadas no `MarkerPainter.paint` para linhas (halo blur, casing, traço principal e marcadores compilados)
- [ ] 5.3 Integrar o suporte à cor hexadecimal personalizada (`ponto.cor`) no pintor e widgets do mapa

## 6. Enquadramento de Câmera e Auto-Zoom Adaptativo

- [ ] 6.1 Criar testes de widget para `_zoomToPoints` validando enquadramento por caixa delimitadora para vias compostas por linhas vetoriais (incluso via com único ponto de linha)
- [ ] 6.2 Atualizar o método `_zoomToPoints` em `frontend/lib/pages/mapa_interativo.dart` para aplicar zoom por Bounding Box quando a rota possuir elemento de linha

## 7. Verificação Final e Documentação

- [ ] 7.1 Executar a suíte completa de testes com `flutter test` garantindo 100% de aprovação e sem regressões em croquis legados
- [ ] 7.2 Documentar métodos, widgets e classes com docstrings em português e atualizar os arquivos `README.md` pertinentes
