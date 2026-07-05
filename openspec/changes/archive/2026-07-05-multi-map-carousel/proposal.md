## Why

Atualmente, quando uma via, setor ou grupo aparece em múltiplos mapas, a UI exibe vários botões distintos (ex: "Ver no mapa 1", "Ver no mapa 2"). Isso polui visualmente a interface. O objetivo é unificar esses botões e oferecer uma navegação consolidada tipo carrossel para que o usuário alterne fluidamente entre os mapas de uma mesma referência.
Além disso, a implementação deve garantir altíssima qualidade de código, sendo desenvolvida através da prática de TDD.

## What Changes

- Criação de uma nova experiência de navegação em carrossel (`MapasCarrosselPage`) que exibe todos os mapas onde uma via ou setor aparece.
- Remoção da repetição de botões "Ver no mapa" na tela de detalhes da Via. No lugar, haverá um único botão "Ver nos mapas (N)".
- Adição de controle superior transparente estilo paginação explícita (`< 01 de 03 >`) para troca de mapas, evitando conflitos de gesture.
- Desenvolvimento estritamente guiado por testes (TDD), com a meta inegociável de 100% de cobertura de testes unitários e de widget nas lógicas novas.

## Capabilities

### New Capabilities
- `multi-map-navigation`: Habilidade de navegar entre múltiplos mapas pré-carregados para uma mesma referência mantendo o foco nela, construída com total cobertura de testes.

### Modified Capabilities
- N/A

## Impact

- `lib/pages/mapas_carrossel.dart` (Novo)
- `lib/navigation/navigation_tree.dart` (Novo nó de navegação)
- `lib/navigation/navigation_functions.dart` (Nova função de navegação)
- `lib/pages/mapa_interativo.dart` (Nova lógica de renderizar botão extra de múltiplos mapas para vias sub-selecionadas)
- `lib/view_functions/via_functions.dart` (Limpeza da lógica de múltiplos chips)
- Todos os arquivos de teste correspondentes no diretório `test/`
