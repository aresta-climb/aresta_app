## 1. Internacionalização e Calculadora de Acesso Inicial (TDD)

- [x] 1.1 Substituir `ChaveTexto.modEstimativaSemTransito` pelas chaves estruturadas do Mini Bottom Sheet (`viagemSheetTitulo`, `viagemSheetTempoMedioRotulo`, `viagemSheetDistanciaEstradaRotulo`, `viagemSheetNotaExplicativa`, `viagemSheetFecharBtn`) em `lib/idioma/modelo_idioma_app.dart` e nos 5 dicionários (`pt`, `en`, `es`, `de`, `nl`), validando os testes em `test/idioma/`.
- [x] 1.2 Atualizar `test/utils/calculadora_distancia_estrada_test.dart` (Red) e implementar em `lib/utils/calculadora_distancia_estrada.dart` (Green) o corte limpo de `formatarTooltip()` e a calibração de `calcularTempoAcessoMinutos` (`24 km/h` até `3 km` e `40 km/h` acima de `3 km`) com 100% de cobertura.

## 2. ViewModels e Mini Bottom Sheet Explicativo (TDD)

- [x] 2.1 Atualizar os testes `test/view/view_models/card_croqui_view_model_test.dart`, `pico_proximo_view_model_test.dart` e `explorar_view_model_test.dart` (Red) e substituir `tooltipDistancia` por `distanciaRotaKm` em `CardCroquiViewModel`, `PicoProximoViewModel` e `BrowseViewModel` (Green) com 100% de cobertura.
- [x] 2.2 Escrever `test/widgets/folha_estimativa_viagem_pico_test.dart` e atualizar `test/widgets/card_pico_test.dart` (Red), seguidos da implementação de `lib/widgets/folha_estimativa_viagem_pico.dart` e do badge clicável com ícone `ⓘ` em `lib/widgets/card_pico.dart` (Green), garantindo 100% de cobertura comportamental e `flutter analyze` limpo.
