# Design

## Context

Veja `proposal.md` para a motivação e escopo funcional.

Atualmente:
- `HomeViewModel` calcula os picos mais próximos chamando `calcularPicosMaisProximos` (`funcoes_home.dart`) com `limite = 6`.
- `NearbyCragsCarousel` (`carrossel_picos_proximos.dart`) obtém a localização do usuário via `Geolocator` (com fallback para `SharedPreferences` nas chaves `last_known_latitude` e `last_known_longitude`) e renderiza um `ListView.builder` com `itemCount: null` quando `picos.length > 1`, aplicando `index % picos.length`.
- `BrowseViewModel` (`explorar_view_model.dart`) gerencia a aba Explorar (`BrowsePage`), mas não possui acesso às coordenadas do usuário, não calcula distâncias e oferece as ordenações `padrao` (ordem bruta do catálogo), `alfabetico` e `escaladas`.
- `CragCard` (`card_pico.dart`) já é compartilhado entre a Home e a aba Explorar e já renderiza nativamente a *badge* de distância quando `CardCroquiViewModel.textoDistancia` não é nulo.

## Goals / Non-Goals

**Goals:**
- Garantir que `HomeViewModel` e `BrowseViewModel` utilizem exatamente a mesma função de cálculo geodésico, desempate e formatação de distância (`m` / `km`).
- Compartilhar a localização do usuário entre a Home e a aba Explorar sem duplicar chamadas concorrentes de GPS.
- Tornar o carrossel da Home finito (até 6 picos) seguido pelo card `"VER MAIS ->"` quando houver mais de 6 picos no catálogo.
- Substituir a ordenação "Padrão" da aba Explorar por "Mais próximos" (com *badges* de distância em todos os modos de ordenação) e realizar o auto-scroll determinístico até o 7º pico ao vir do card `"VER MAIS ->"`.

**Non-Goals:**
- Alterar schemas Protobuf (`indice.proto` ou `croqui.proto`).
- Ocultar ou remover os 6 primeiros picos da listagem da aba Explorar.
- Adicionar rastreamento contínuo de localização em segundo plano.

## Decisions

### 1. Fonte Única para Cálculo e Formatação de Distância
- **Decisão**: Centralizar o cálculo geodésico e a formatação de distância em `funcoes_home.dart` (reutilizado por `HomeViewModel` e `BrowseViewModel`).
  - `calcularPicosMaisProximos` passará a aceitar `int? limite = 6`. Quando `limite == null`, retorna todos os picos com coordenadas ordenados por `distanciaKm` crescente (com desempate alfabético por nome/id para determinismo).
  - Uma função auxiliar pura `formatarDistanciaKm(double distanciaKm)` (`< 1.0` -> `'${(km * 1000).round()} m'`, `>= 1.0` -> `'${km.toStringAsFixed(1)} km'`) será usada tanto por `PicoProximoViewModel.distanciaFormatada` quanto por `BrowseViewModel` ao montar `CardCroquiViewModel`.
- **Alternativas consideradas**: Duplicar o cálculo de `Geolocator.distanceBetween` dentro de `BrowseViewModel`. Rejeitado por violar o requisito explícito de código único de ordenação entre Home e Explorar.

### 2. Compartilhamento Reativo da Localização do Usuário
- **Decisão**: Em `HomeViewModel`, quando `atualizarLocalizacaoUsuario(double lat, double lon)` é chamado, além de atualizar seu estado interno, notifica ouvintes e/ou compartilha as coordenadas com `BrowseViewModel` (através de vínculo em `TreeNavigationWrapperState` ou estado reativo no `DatasetRepository`). Adicionalmente, `BrowseViewModel` expõe `atualizarLocalizacaoUsuario(double lat, double lon)` para ser testável isoladamente e sincronizado imediatamente quando `NearbyCragsCarousel` resolve o GPS ou cache.
- **Racional**: Mantém os ViewModels desacoplados de plugins nativos de plataforma, preservando 100% de testabilidade unitária determinística (Princípios II e V do `AGENTS.md`).

### 3. Carrossel Finito + Card `"VER MAIS ->"`
- **Decisão**:
  - `HomeViewModel` expõe `bool get temMaisPicosParaExplorar` (verdadeiro quando o total de picos disponíveis no catálogo é maior que `NearbyCragsCarousel.kLimitePicosProximos`, que é 6).
  - Em `NearbyCragsCarousel`, o `ListView.builder` passa a ter `itemCount: picos.length + (temMais ? 1 : 0)`.
  - Quando `index == picos.length`, renderiza o widget do card `"VER MAIS ->"` com `width: 340`, `height: 200`, `borderRadius: BorderRadius.circular(24)`, cor `context.colors.caveShadow`, borda `context.colors.graniteEdge` e texto centralizado `'VER MAIS ->'`.
  - Ao tocar no card, invoca o callback `onVerMais` passado para `NearbyCragsCarousel`.

### 4. Ordenação na Aba Explorar (`OrdemOrdenacaoPico`)
- **Decisão**:
  - Na aba Explorar (`BrowseViewModel` e `BrowsePage`), a ordenação padrão inicial passa a representar **"Mais próximos"** (`OrdemOrdenacaoPico.proximidade`, mantendo alias/compatibilidade se necessário).
  - No modal de filtro de `BrowsePage`, os 3 itens exibidos serão:
    1. `'Mais próximos'`
    2. `'Alfabético (A-Z)'`
    3. `'Mais escaladas'`
  - Quando a coordenada do usuário estiver definida (`userLat != null && userLon != null`):
    - Todos os cards em `BrowseViewModel.picosCards` recebem `textoDistancia` calculado via a mesma função da Home (independentemente de a ordem ser Mais próximos, Alfabético ou Mais escaladas).
    - Na ordem "Mais próximos", os picos são ordenados pela função compartilhada `calcularPicosMaisProximos(..., limite: null)`, posicionando eventuais picos sem coordenadas válidas ao final em ordem alfabética.
  - Quando a coordenada do usuário não estiver disponível (permissão negada e sem cache):
    - Na ordem "Mais próximos", aplica fallback determinístico em ordem alfabética (A-Z) sem *badge* de distância.

### 5. Transição e Auto-Scroll para o 7º Pico
- **Decisão**:
  - `BrowseViewModel` terá um método `focarSetimoPicoProximo()` (ou similar) que:
    1. Limpa qualquer termo de busca ativo (`_termoBusca = ''`).
    2. Define a ordenação para Mais próximos.
    3. Incrementa um `ValueNotifier<int> solicitacaoScrollSetimoPico` (ou flag reativa).
  - Quando o usuário toca em `"VER MAIS ->"` na Home:
    1. Aciona o foco no 7º pico no `BrowseViewModel` e alterna para a aba Explorar (`onSwitchTab(1)`).
  - Em `BrowsePage` / `funcoes_explorar.dart`, a lista vertical de picos utiliza um `ScrollController` e associa uma `GlobalKey` (ou cálculo de offset determinístico, já que cada `CragCard` tem `200px` de altura + `16px` de padding inferior = `216px` por card) ao 7º card (índice 6), executando `Scrollable.ensureVisible` / `scrollController.animateTo` após o frame de renderização.

## Risks / Trade-offs

- **[Risco] Catálogo com menos de 7 picos em ambientes de teste ou servidores experimentais** → **Mitigação**: O card `"VER MAIS ->"` só é exibido quando houver mais de 6 picos disponíveis, e a lógica de auto-scroll verifica se a lista possui ao menos 7 itens (`length > 6`) antes de rolar.
- **[Risco] Picos sem coordenadas de latitude/longitude no catálogo** → **Mitigação**: Na ordenação por proximidade, picos com coordenadas válidas vêm primeiro (ordenados por distância) e picos sem coordenadas ficam ao final da lista na aba Explorar, garantindo que nenhum pico desapareça do catálogo.
