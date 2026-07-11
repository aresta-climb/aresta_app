## 1. Preparação para Testes (TDD)

- [ ] 1.1 Criar `frontend/test/pages/mapa_interativo_test.dart` (ou arquivo de teste unitário similar para `MarkerPainter` e `AreaHelper`).
- [ ] 1.2 Escrever testes unitários para `AreaHelper.getAreaInfo` cobrindo tipos `circular`, `box` (rotacionado) e `areaLivre` para garantir que a geração de polígonos e limites esteja correta.
- [ ] 1.3 Escrever testes unitários para `MarkerPainter.hitTest` afirmando que pontos dentro do polígono rotacionado retornam `true` e pontos nos cantos do AABB (fora do polígono) retornam `false`.
- [ ] 1.4 Escrever testes unitários para a inflação de hit-test, garantindo que pontos levemente fora de um polígono fino ainda sejam detectados como toques válidos.

## 2. Implementação & Documentação

- [ ] 2.1 Implementar a inflação de caminho no `MarkerPainter.hitTest` para fazer os testes passarem.
- [ ] 2.2 Adicionar docstrings em Dart (`///`) abrangentes ao `MarkerPainter`, `AreaHelper` e seus métodos críticos explicando as transformações de coordenadas.
- [ ] 2.3 Executar os testes para garantir 100% de cobertura nessas classes/métodos específicos.

## 3. Integração de Widgets

- [ ] 3.1 Em `c:\Renato\Devel\aresta-climb\aresta_app\frontend\lib\pages\mapa_interativo.dart`, localizar o `GestureDetector` dentro do método `_buildMarkers`.
- [ ] 3.2 Remover `behavior: HitTestBehavior.opaque,` (ou alterar para `deferToChild`) para habilitar o hit test preciso.
- [ ] 3.3 Verificar visualmente/manualmente que tocar nos marcadores 15/16 agora funciona mesmo que eles se sobreponham à caixa delimitadora do Sentinela.
