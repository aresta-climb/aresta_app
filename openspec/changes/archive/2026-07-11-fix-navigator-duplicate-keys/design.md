## Context

O `TreeNavigationController` do aplicativo empilha instâncias de `NavNode`. O arquivo `main.dart` constrói o array `Navigator.pages` a partir desses nós e define a propriedade `Key` de cada `MaterialPage` como `ValueKey(node.toString())`. O Flutter exige que essas chaves sejam estritamente únicas em todas as páginas dentro de um mesmo `Navigator`.

Atualmente, o `ViaNode.toString()` inclui apenas o nome da via (`$escaladaNome`). Portanto, se o usuário navegar para uma via a partir de uma busca geral (onde contextos como `$setorNome` são nulos) e, em seguida, navegar para a mesma via a partir de um mapa interativo (onde o `$setorNome` é resolvido e fornecido), o `TreeNavigationController` empilhará um novo `ViaNode`. Isso ocorre porque o método `_isSameNode` retornará `false` (já que os setores diferem). No entanto, como o resultado de `toString()` de ambos permanece idêntico, o Flutter encontra uma chave duplicada no array de páginas, causando o crash `!keyReservation.contains(key)`.

## Goals / Non-Goals

**Goals:**
- Eliminar os crashes de `!keyReservation.contains(key)` que ocorrem durante interações com o mapa e fluxos de navegação em geral.
- Garantir que a representação em string (`toString()`) de qualquer `NavNode` reflita perfeitamente os campos utilizados nas verificações lógicas de igualdade (`_isSameNode`), mantendo a unicidade sempre que os nós forem considerados distintos pela lógica de navegação.
- Adotar Test-Driven Development (TDD) escrevendo os testes unitários para as condições de igualdade de `toString()` antes de realizar a implementação.
- Alcançar 100% de cobertura de testes unitários (coverage) para a lógica modificada de `toString()` no arquivo `navigation_tree.dart`.
- Garantir que todos os métodos `toString()` sobrescritos estejam bem documentados com docstrings abrangentes, explicando como a string é composta e o seu propósito crítico para o `Navigator` do Flutter.

**Non-Goals:**
- Refatorar a arquitetura ou o comportamento do `TreeNavigationController`.
- Alterar a lógica do `_isSameNode`. O objetivo é apenas corrigir o mapeamento de nós únicos para chaves únicas no `Navigator` do Flutter.

## Decisions

**Atualizar o `toString()` dos NavNodes**: Vamos adicionar explicitamente os campos ausentes ao método `toString()` de todas as subclasses de `NavNode`.
- *Justificativa*: Esta é a maneira menos invasiva e mais robusta de garantir que nós que são logicamente distintos também produzam chaves distintas para o `Navigator` do Flutter.
- *Alternativa Considerada*: Alterar o `main.dart` para usar um ID incremental ou um UUID gerado unicamente como a chave de cada página em vez de `node.toString()`. Embora isso também prevenisse chaves duplicadas, usar o `toString()` facilita muito a depuração das pilhas de navegação e preserva a consistência estrutural através das reconstruções dos widgets sem a necessidade de manter estado de UUIDs por instância de nó.

**Adoção de TDD e Alta Cobertura**: Implementaremos as mudanças utilizando TDD.
- *Justificativa*: Escrever os testes primeiro garante que todos os casos extremos (por exemplo, setores nulos, grupos diferentes mas mesmos nomes) sejam cobertos e que o bug seja reproduzido nos testes. Ter 100% de cobertura para esses métodos específicos garante que não haverá regressões no futuro.

## Risks / Trade-offs

- **Risco**: Falhas em testes se os testes unitários existentes fizerem validações estritas em cima das saídas específicas do `toString()` desses nós.
  **Mitigação**: Revisar e atualizar quaisquer testes relevantes que dependam do `node.toString()` para que passem a corresponder ao novo formato. Ao usar TDD, identificaremos e adaptaremos naturalmente qualquer lógica de teste que entre em conflito.
- **Trade-off**: Logs de depuração (debug) ligeiramente mais longos ao imprimir a pilha de navegação, o que é um custo insignificante em troca de um gerenciamento de estado robusto.
