## Why

Atualmente, quando o usuário volta para a página anterior através do aplicativo (por exemplo, de uma página de Setor para a de Pico), a posição de rolagem (scroll) e os estados internos da tela são completamente perdidos. Isso acontece porque o nosso `TreeNavigationController` customizado renderiza um único widget ativo na função de build do `main.dart`, que substitui por inteiro o `Scaffold` a cada navegação, forçando a interface a destruir e recriar as telas do zero. Utilizar uma abordagem de `Navigator` declarativo (Flutter Router 2.0) sobre a nossa estrutura atual de árvore vai preservar esses estados ativos, melhorando drasticamente a experiência do usuário (UX) e a eficiência do processamento (poupando bateria).

## What Changes

- Envolver o roteamento principal do aplicativo (dentro de `AppRouter` / `PageListenableBuilder` no `main.dart`) com um `Navigator` declarativo.
- Traduzir a cadeia de ancestralidade do `TreeNavigationController.currentNode` em uma lista de objetos `Page` nativos do Flutter (como `MaterialPage`).
- Remover a lógica de substituição de um único widget no `main.dart` por este `Navigator(pages: ...)`.
- Garantir que o botão físico de "voltar" (ex: Android) e as transições nativas de plataforma continuem a acionar o `TreeNavigationController.goBack()` corretamente.

## Capabilities

### New Capabilities
Nenhuma.

### Modified Capabilities
- `navigation`: Transição de uma arquitetura de renderização de tela única para uma pilha declarativa de `Navigator`, preservando a mesma lógica e estado exato da nossa árvore estrutural.

## Impact

- Arquivo `lib/main.dart` (especificamente o widget `AppRouter` e a função `_buildCurrentNode`).
- Melhoria significativa na performance de navegação e preservação contínua de estados (scrolls, abas).
- Impacto nulo no resto do código, visto que o `TreeNavigationController` (nossa fonte da verdade) continua intacto.
