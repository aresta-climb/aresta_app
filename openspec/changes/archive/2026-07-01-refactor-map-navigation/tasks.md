## 1. Domain Models (TDD)
- [x] 1.1 Criar suite de testes unitários para `ReferenceKey` e `IndexedMap`, especificando os cenários de igualdade (`==`) e `hashCode`.
- [x] 1.2 Implementar `ReferenceKey` e `IndexedMap` (ex: em `lib/utils/reference_key.dart` ou `dataset_resolver.dart`) garantindo que os testes passem com 100% de coverage.

## 2. Core Indexing Logic (TDD)
- [x] 2.1 Criar suite de testes unitários para `CroquiMapIndex`. Os testes devem usar instâncias simuladas (mockadas) de `Pico`, `Grupo` e `Setor` contendo mapas.
- [x] 2.2 Implementar a varredura (scan) top-down da árvore do `Pico` dentro da inicialização do `CroquiMapIndex` e fazer os testes de indexação passarem (100% coverage).
- [x] 2.3 Escrever teste unitário para o método `getMapasForReference`, assegurando que mapas são encontrados e mapeados corretamente em O(1).
- [x] 2.4 Implementar `getMapasForReference` e fazer o teste passar (100% coverage).

## 3. Navigation Signature Updates (TDD)
- [x] 3.1 Escrever teste unitário para a classe `ViaNode` assegurando a passagem e retenção de `grupoNome`.
- [x] 3.2 Modificar `ViaNode` (`lib/navigation/navigation_tree.dart`) adicionando suporte à string `grupoNome` (como opcional ou obrigatória) para garantir que navegação não perca o contexto.
- [x] 3.3 Escrever teste unitário para métodos do `AppNav` ou `ViaPage` que lidam com argumentos verificando se `grupoNome` está sendo preservado.
- [x] 3.4 Modificar o construtor/argumentos de `ViaPage` e o método `AppNav.toVia(...)` para aceitar `grupoNome`, fazendo os testes passarem.

## 4. UI Refactoring (Widget Tests)
- [x] 4.1 Escrever Widget Test para o clique da rota ("Mais info") dentro do `mapa_interativo.dart`, garantindo via mock de `AppNav` que ele repassa `resolved.setor` e `resolved.grupo`.
- [x] 4.2 Refatorar `_buildEscaladaCard` em `mapa_interativo.dart` e garantir que o teste passe.
- [x] 4.3 Escrever Widget Test para as badges na `ViaPage`, simulando injeção do `CroquiMapIndex` e garantindo que o botão "Ver no mapa" é criado até para mapas globais (Pico) ou de Grupo.
- [x] 4.4 Refatorar `_buildTopBadges` em `via_functions.dart` consumindo o `CroquiMapIndex` e injetá-lo pelo `main.dart`. Fazer os testes de UI passarem com 100% de cobertura de badge generation.
- [x] 4.5 Escrever Widget Test assegurando que clicar na badge de mapa chama `AppNav.toMapaInterativo` com `setorContext` e `grupoContext` corretos contidos no `IndexedMap`.
- [x] 4.6 Fazer o teste de clique da badge passar.

## 5. Cobertura e Validação Final
- [x] 5.1 Rodar testes de cobertura local (ex: `flutter test --coverage`) e auditar se os arquivos modificados apresentam 100% de coverage nas lógicas de indexação e navegação.
- [x] 5.2 Validação End-to-End: Clicar em "Mais info" numa rota pelo mapa geral e garantir que a página da via abre corretamente sem falhas.
- [x] 5.3 Validação End-to-End: Checar "Ver no mapa" aparecendo na página de Via para todos os níveis (Pico, Grupo, Setor) e confirmando que abre o mapa com o contexto exato.
