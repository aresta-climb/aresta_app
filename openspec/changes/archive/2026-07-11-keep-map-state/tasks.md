## 1. TDD: Testes Primeiro

- [x] 1.1 Criar/atualizar um teste de widget para `MapaInterativoPage` dentro de um `PageView` em `frontend/test/pages/mapa_interativo_test.dart`
- [x] 1.2 Escrever um cenário de teste que deslize para fora do mapa e volte, afirmando que o estado é preservado (este teste deve falhar inicialmente)

## 2. Implementação

- [x] 2.1 Adicionar `AutomaticKeepAliveClientMixin` ao `_MapaInterativoPageState` em `frontend/lib/pages/mapa_interativo.dart`
- [x] 2.2 Sobrescrever `wantKeepAlive` para retornar `true` em `_MapaInterativoPageState`
- [x] 2.3 Chamar `super.build(context)` dentro do método `build` de `_MapaInterativoPageState`

## 3. Documentação

- [x] 3.1 Adicionar docstrings abrangentes à classe `MapaInterativoPage` explicando seu propósito
- [x] 3.2 Adicionar docstrings ao `_MapaInterativoPageState` documentando explicitamente o uso de `AutomaticKeepAliveClientMixin` para preservar o estado dentro de `MapasCarrosselPage`

## 4. Verificação

- [x] 4.1 Rodar os testes de widget e garantir 100% de cobertura para a nova lógica de keep-alive (o teste do passo 1.2 deve passar agora)
- [x] 4.2 Rodar o aplicativo manualmente e verificar se alternar entre mapas no carrossel preserva o estado de zoom e movimentação, e se a animação não é repetida
