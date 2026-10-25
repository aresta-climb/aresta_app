# Proposal

## Why

Atualmente, o carrossel de "Mais Próximos de Você" na página inicial (`HomePage` / `NearbyCragsCarousel`) seleciona apenas os 6 picos mais próximos e os exibe em um loop circular infinito (`index % picos.length`), repetindo os mesmos 6 picos indefinidamente enquanto oculta o restante do catálogo. Além disso, a aba Explorar (`BrowsePage` / `BrowseViewModel`) utiliza uma ordenação "Padrão" baseada na ordem arbitrária do catálogo e não exibe a distância até os picos, dificultando a descoberta contínua de locais de escalada próximos ao usuário.

## What Changes

- **Fim do loop repetitivo no Carrossel da Home**: Remover a rolagem circular infinita (`index % picos.length`) em `NearbyCragsCarousel`, exibindo os top 6 picos mais próximos de forma linear.
- **Card minimalista `"VER MAIS ->"` no final do Carrossel**: Adicionar ao final dos 6 picos do carrossel (quando houver mais picos disponíveis no catálogo) um card com as mesmas dimensões dos cards de pico (`340x200`, `borderRadius: 24`) contendo o texto centralizado `"VER MAIS ->"`.
- **Fonte única de verdade para cálculo e ordenação por distância**: Unificar a lógica de cálculo geodésico, formatação de distância (`m` / `km`) e ordenação por proximidade para ser compartilhada entre `HomeViewModel` e `BrowseViewModel`, garantindo que os 6 primeiros picos da aba Explorar na ordem "Mais próximos" sejam estritamente idênticos aos 6 picos da Home.
- **Exibição de distância e nova ordenação na aba Explorar**:
  - Atualizar os critérios de ordenação da aba Explorar para: **Mais próximos** (padrão), **Alfabético (A-Z)** e **Mais escaladas**.
  - Exibir a *badge* de distância (`[📍 X km]` / `[📍 X m]`) nos cards (`CragCard`) da aba Explorar sempre que a localização do usuário estiver disponível.
- **Transição do `"VER MAIS ->"` com Auto-Scroll para o 7º pico**: Ao tocar no card `"VER MAIS ->"` na Home, alternar para a aba Explorar com a ordenação **Mais próximos** ativa e rolar automaticamente a lista vertical até a posição do **7º pico** (índice 6), mantendo os 6 primeiros acessíveis caso o usuário role para cima.

## Capabilities

### New Capabilities
- `descoberta-picos-proximidade`: Descoberta de picos por proximidade geográfica no carrossel da Home (top 6 + card `"VER MAIS ->"`) e no catálogo da aba Explorar (ordenação unificada por distância, exibição de *badge* de quilometragem e rolagem automática até o 7º pico).

### Modified Capabilities

## Impact

- **Widgets e Páginas**:
  - `frontend/lib/widgets/carrossel_picos_proximos.dart`: Remoção do loop circular infinito, renderização do card `"VER MAIS ->"` ao final dos 6 primeiros picos e acionamento do callback de navegação para Explorar.
  - `frontend/lib/pages/home.dart` e `frontend/lib/view/function_library/funcoes_home.dart`: Propagação da ação de transição para a aba Explorar no carrossel e função compartilhada de ordenação por distância.
  - `frontend/lib/pages/explorar.dart` e `frontend/lib/view/function_library/funcoes_explorar.dart`: Atualização do modal de ordenação (`Mais próximos`, `Alfabético (A-Z)`, `Mais escaladas`) e suporte a `ScrollController` para auto-scroll até o 7º pico.
  - `frontend/lib/navigation/wrapper_navegacao_arvore.dart`: Sincronização da localização do usuário entre `HomeViewModel` e `BrowseViewModel` e coordenação do comando de abrir Explorar no 7º pico.
- **ViewModels**:
  - `frontend/lib/view/view_models/home_view_model.dart` e `frontend/lib/view/view_models/explorar_view_model.dart`: Compartilhamento da coordenada do usuário, ordenação unificada por distância e mapeamento de `textoDistancia` para `CardCroquiViewModel`.
- **Testes**:
  - Atualização e adição de testes de widget e unitários espelhados 1:1 com 100% de cobertura comportamental.
