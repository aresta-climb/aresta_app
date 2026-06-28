## Context

O aplicativo atualmente usa um `TreeNavigationController` para representar o estado da navegação de forma hierárquica. No arquivo `main.dart`, um widget `AppRouter` "escuta" este controller e reconstrói o seu corpo inteiro lendo o nó atual (`currentNode`) e retornando um único widget Flutter na ponta (ex: `SetorPage()`). Como o widget principal é substituído integralmente quando o nó muda, o Flutter destrói por completo a árvore de widgets da tela anterior. Isso gera a perda irreparável das posições de rolagem (scroll) e dos estados da interface (como painéis expandidos ou abas selecionadas) toda vez que o usuário navega "para trás" (ex: voltando de uma Via para um Setor).

## Goals / Non-Goals

**Goals:**
- Preservar a posição do scroll e os estados das telas anteriores ao se navegar de volta.
- Manter o `TreeNavigationController` intacto como a nossa Fonte Única de Verdade (Source of Truth) para o estado de navegação, mantendo a integridade estrutural e evitando loops ou confusão de rotas.
- Realizar a transição para um `Navigator` declarativo (padrão Router 2.0 do Flutter) encarregado unicamente da renderização destas páginas.

**Non-Goals:**
- Não removeremos, nem refatoraremos a lógica interna do `TreeNavigationController` ou do `navigation_tree.dart`.
- Não faremos uma migração para ferramentas de rotas terceirizadas (como o `go_router`), pois nossa modelagem em formato de árvore hierárquica atende perfeitamente ao nosso domínio complexo de dados.

## Decisions

**1. Usar um Navigator Declarativo no `AppRouter`**
Em vez de retornar um corpo único dentro de um `Scaffold` baseado no nó atual, vamos processar uma `List<Page>` atravessando a herança a partir do `currentNode` (seguindo de `node.parent` até a raiz). Entregaremos essa lista para o widget `Navigator(pages: ...)`.
*Motivação:* Isso aproveita os mecanismos nativos do Flutter projetados exatamente para manter páginas ocultas vivas em memória (offstage) e para entregar animações transicionais graciosas sem jogar fora a nossa lógica customizada de árvore.

**2. Implementação do `onPopPage`**
Sempre que o `Navigator` interno tentar descartar a página do topo (seja através de um clique na AppBar, um botão físico de voltar no Android, ou via gesto no iOS), interceptaremos o evento e chamaremos obrigatoriamente `treeController.goBack()`.
*Motivação:* O TreeController deve ditar as regras. Se permitíssemos o pop ignorando a árvore, a interface de usuário entraria em descompasso severo com os estados lógicos do aplicativo.

## Risks / Trade-offs

- **Risco: Conflito com Navegadores Aninhados** -> Caso existam `Navigator`s imperativos antigos (por exemplo, modals soltos), eles podem tentar interceptar o botão físico de voltar de forma incorreta.
  *Mitigação:* Usar chamadas para o Root Navigator para diálogos modais e assegurar que o Navigator declarativo lida com o empilhamento exclusivamente estrutural de telas.
- **Efeito Colateral: Aumento do Uso de Memória** -> Manter telas gráficas gigantes e cheias de imagens (como mapas e croquis) vivas pode consumir mais memória RAM.
  *Mitigação:* O Flutter lida excelentemente com lixo fora de tela (offstage memory). Como a profundidade da nossa árvore raramente passa de 4 a 5 níveis de empilhamento (Home -> Pico -> Setor -> Via), a pressão na memória deverá ser imperceptível.

## Testing Strategy (TDD)

Esta funcionalidade OBRIGATORIAMENTE deve ser desenvolvida utilizando Test-Driven Development (TDD) sob uma meta de **100% de test coverage (cobertura unitária)** nas partes lógicas e modificadas:
- A lógica auxiliar extraída (`buildPagesFromNode`) deve ser 100% atestada para todas as permutações e cenários de hierarquia de nós antes de integrarmos na UI.
- Testes de Widgets (`Widget tests`) no `AppRouter` devem validar que o uso do Navigator Declarativo está entregando corretamente as pilhas inteiras de chaves (`ValueKey` unicamente determinística para não quebrar a reconstrução).
- Testes de Widgets deverão obrigatoriamente simular ações de pop sistêmicas (back button do Android) assegurando o engatilhamento perfeito do `TreeNavigationController.goBack()`.
