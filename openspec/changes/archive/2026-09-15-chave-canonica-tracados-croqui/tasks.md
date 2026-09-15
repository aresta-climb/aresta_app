## 1. Testes Automatizados em Primeiro Lugar (TDD)

- [x] 1.1 Escrever testes unitários em `frontend/test/utils/construtor_caminho_trajeto_test.dart` validando que traçados com chaves compostas distintas (`mapa1#linha_1` vs `mapa2#linha_1`) mantêm isolamento total sem contaminação de cache e que `limparCache()` limpa ambos os caches (`_cacheCaminhos` e `_cacheCaminhosViewport`).
- [x] 1.2 Escrever testes de widget em `frontend/test/pages/mapas_carrossel_test.dart` simulando dois mapas no carrossel que utilizam o mesmo `ponto.id`, garantindo que a navegação entre páginas renderiza os caminhos independentes sem contaminação.

## 2. Implementação da Chave Canônica e Eliminação de Fallbacks

- [x] 2.1 Tornar `chaveCache` um parâmetro nomeado estritamente obrigatório (`required String chaveCache`) em `AreaHelper.getAreaInfo` em `frontend/lib/pages/mapa_interativo.dart`, eliminando qualquer fallback para `ponto.id`.
- [x] 2.2 Atualizar as chamadas a `AreaHelper.getAreaInfo` e à instanciação de `MarkerPainter` em `_MapaInterativoPageState` para passar explicitamente `"${widget.mapa.caminhoImagemMapa}#${ponto.id}"`.
- [x] 2.3 Atualizar o cálculo de `cacheKeyViewport` em `MarkerPainter._paintLinha` para utilizar a `chaveCache` canônica composta combinada com as restrições da tela (`"${chaveCache}_${constraints.maxWidth.toInt()}x${constraints.maxHeight.toInt()}"`).

## 3. Atualização dos Testes Unitários Legados

- [x] 3.1 Atualizar todas as chamadas a `AreaHelper.getAreaInfo` em `frontend/test/pages/mapa_interativo_test.dart` para fornecer a `chaveCache` explicitamente com padrão canônico (ex: `"mapa_teste#id"`), assegurando compilação e 100% de cobertura.

## 4. Higiene de Memória no Ciclo de Vida do Aplicativo

- [x] 4.1 Invocar `ConstrutorCaminhoTrajeto.limparCache()` na navegação de saída da visualização do pico (`AppNav.toBrowse` e `AppNav.home`) em `frontend/lib/navigation/navigation_functions.dart`.
- [x] 4.2 Invocar `ConstrutorCaminhoTrajeto.limparCache()` na conclusão de download/atualização de croqui (`updateDatasetAfterDownload`) e no esvaziamento de dados (`loadEmpty`) em `frontend/lib/services/dataset_repository.dart`.

## 5. Validação e Verificação Final

- [x] 5.1 Executar a suíte completa de testes do frontend com `flutter test` e verificar 100% de aprovação.
- [x] 5.2 Executar `flutter analyze` e confirmar zero alertas de lint e tipagem.
