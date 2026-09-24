## 1. Testes Automatizados em Primeiro Lugar (TDD)

- [x] 1.1 Criar teste de widget em `frontend/test/pages/mapas_carrossel_test.dart` simulando a abertura do carrossel para uma escalada secundária que compartilha o POI com uma primeira via, verificando que o card exibido inicial é o da segunda via e confirmando que o teste falha antes da alteração (Red).
- [x] 1.2 Criar teste de widget em `frontend/test/pages/mapa_interativo_test.dart` validando que ao receber novas propriedades via `didUpdateWidget` na mesma imagem (mesmo caminho), o mapa atualiza `_selectedId`, `_focusedItemIndex` e agenda o auto-zoom para a nova via sem re-executar a resolução do provedor de imagem.
- [x] 1.3 Criar teste de widget em `frontend/test/pages/mapa_interativo_test.dart` validando que ao receber rebuild via `didUpdateWidget` sem alteração na seleção (`selectionChanged == false`), nenhuma translação ou zoom de câmera é acionado, preservando a navegação do usuário.


## 2. Implementação e Propagação de Contexto

- [x] 2.1 Repassar `escaladaContextNome: item.escaladaContextNome` na instanciação de `MapaInterativoPage` dentro de `MapasCarrosselPage._defaultMapBuilder` em `frontend/lib/pages/mapas_carrossel.dart` e validar a passagem do teste 1.1 (Green).
- [x] 2.2 Implementar a detecção de `selectionChanged` e sincronização reativa de seleção e câmera no `didUpdateWidget` em `frontend/lib/pages/mapa_interativo.dart`, garantindo a aprovação dos testes 1.2 e 1.3 (Green).
- [x] 2.3 Ajustar `_updateFeedbackNode` em `frontend/lib/pages/mapa_interativo.dart` para utilizar `refs[_focusedItemIndex]` em vez de fixar em `refs.first`, garantindo que o nó de feedback reflita a via em exibição.

## 3. Validação Final e Cobertura

- [x] 3.1 Executar toda a suíte de testes do frontend (`flutter test`) e certificar 100% de aprovação sem quebras ou regressões.
- [x] 3.2 Garantir que todas as docstrings (`///`) e comentários nos arquivos modificados estejam em português brasileiro claro e descritivo.

