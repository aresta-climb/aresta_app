## Why

Nos cards de picos com estimativa de tempo, o `Tooltip` atual exige segurar o toque (`longPress`) no celular — um toque simples (`tap`) sobre o badge aciona a abertura do croqui por estar dentro do `GestureDetector` do card, além de não haver indicação visual de que o badge possui informações adicionais. Além disso, o tempo de acesso urbano inicial (`U -> K`) na calculadora do app (`30 km/h` e `50 km/h`) estava ligeiramente otimista frente ao tráfego urbano típico.

## What Changes

- **Badge clicável com ícone `ⓘ` e Mini Bottom Sheet explicativo (`CragCard` + `FolhaEstimativaViagemPico`)**:
  - Substitui o `Tooltip` de `longPress` nos badges com estimativa de tempo por um badge interativo exibindo o ícone `ⓘ` (`Icons.info_outline_rounded`) ao lado do tempo arredondado (`📍 ~1h ⓘ`).
  - Intercepta o toque simples (`onTap`) exclusivamente sobre o badge para **não** abrir o croqui e exibe um Mini Bottom Sheet (`FolhaEstimativaViagemPico`) apresentando o nome do pico, o **Tempo médio (fluxo normal)**, a **Distância por estrada** em quilômetros e uma nota clara informando que o cálculo é feito offline via OpenStreetMap sem trânsito em tempo real.
  - **BREAKING (interno)**: Substitui `tooltipDistancia` por `distanciaRotaKm` em `CardCroquiViewModel` e `PicoProximoViewModel` e remove `EstimativaViagemPico.formatarTooltip()` e `ChaveTexto.modEstimativaSemTransito` (corte limpo conforme Princípio VIII do `AGENTS.md`).
- **Calibração do tempo de conexão inicial `U -> K` (`CalculadoraDistanciaEstrada.calcularTempoAcessoMinutos`)**:
  - Ajusta a velocidade média de acesso urbano inicial para `24 km/h` nos primeiros `3 km` e `40 km/h` no trecho excedente acima de `3 km`.

## Capabilities

### New Capabilities
- Nenhuma nova capability.

### Modified Capabilities
- `descoberta-picos-proximidade`: Substitui o requisito de `Tooltip` por badge clicável com ícone informativo `ⓘ` que abre um Mini Bottom Sheet explicativo sem disparar a abertura do croqui.
- `malha-distancia-estrada-offline`: Ajusta as velocidades do cálculo de tempo de conexão inicial `U -> K` (`24 km/h` até `3 km` e `40 km/h` acima de `3 km`).

## Impact

- **`aresta_app/frontend`**:
  - `lib/utils/calculadora_distancia_estrada.dart` e `test/utils/calculadora_distancia_estrada_test.dart`.
  - `lib/idioma/modelo_idioma_app.dart` e `lib/idioma/dicionario_{pt,en,es,de,nl}.dart` (+ respectivos testes em `test/idioma/`).
  - `lib/view/view_models/card_croqui_view_model.dart`, `lib/view/view_models/pico_proximo_view_model.dart`, `lib/view/view_models/explorar_view_model.dart` (+ respectivos testes).
  - Novo widget modular `lib/widgets/folha_estimativa_viagem_pico.dart` + `test/widgets/folha_estimativa_viagem_pico_test.dart`, e integração em `lib/widgets/card_pico.dart` + `test/widgets/card_pico_test.dart`.
