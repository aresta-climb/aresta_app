## Context

Em `CragCard` (`frontend/lib/widgets/card_pico.dart`), o card inteiro é envolvido por um `GestureDetector(onTap: ...)`. Quando o badge de proximidade envolvia o texto em um `Tooltip` padrão do Flutter, apenas o gesto de segurar (`longPress`) exibia a mensagem, enquanto o toque natural do usuário (`tap`) propagava para o `CragCard` e abria a tela do pico. Além disso, não havia sinal visual (`ⓘ`) indicando que o badge continha detalhes da rota.

## Goals / Non-Goals

**Goals:**
- Tornar explícito e clicável o badge de tempo estimado (`📍 ~1h ⓘ`), consumindo o `onTap` na área do badge para impedir abertura acidental do croqui.
- Apresentar um Mini Bottom Sheet (`FolhaEstimativaViagemPico`) legível e alinhado à identidade visual escura do Aresta com: tempo médio em fluxo normal, distância por estrada em km e nota sobre cálculo offline via OpenStreetMap sem trânsito em tempo real.
- Realizar corte limpo (Princípio VIII do `AGENTS.md`) substituindo `tooltipDistancia` por `distanciaRotaKm` nos ViewModels e ajustando `calcularTempoAcessoMinutos` para `24 km/h` (até `3 km`) e `40 km/h` (acima de `3 km`).

**Non-Goals:**
- Exibir traçado vetorial da rota no mapa ou consultar trânsito online.

## Decisions

### 1. Componente Modular `FolhaEstimativaViagemPico` (`lib/widgets/folha_estimativa_viagem_pico.dart`)
- Criado como biblioteca/widget independente (Princípio II do `AGENTS.md`) com método estático `FolhaEstimativaViagemPico.exibir(BuildContext context, {required String tituloPico, required String tempoMedio, required String distanciaEstradaKm})` que invoca `showModalBottomSheet`.
- Layout compacto com puxador superior, cabeçalho com ícone `Icons.directions_car_filled_rounded`, blocos de destaque para **Tempo médio (fluxo normal)** e **Distância por estrada**, texto explicativo localizado nos 5 idiomas e botão de confirmação para fechar.

### 2. Interceptação de Toque no `CragCard`
- Quando `dados.distanciaRotaKm != null && dados.distanciaRotaKm!.isNotEmpty`, `CragCard` renderiza `Icons.info_outline_rounded` à direita do texto da badge e envolve o badge em `GestureDetector(key: Key('badge_estimativa_viagem_$id'), behavior: HitTestBehavior.opaque, onTap: ...)`. Na arena de gestos do Flutter, o `GestureDetector` interno vence o `onTap`, impedindo que o `GestureDetector` externo do `CragCard` dispare `onOpen` ou `onDownload`.

## Risks / Trade-offs

- **[Trade-off] Área de toque do badge em cards compactos** → **Mitigação**: `HitTestBehavior.opaque` garante que toda a pílula do badge (`padding` horizontal `10` e vertical `6`) seja sensível ao toque, enquanto o restante do card continua abrindo o croqui normalmente.
