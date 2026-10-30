# Testes Caóticos Exploratórios e Regressão (`test/caos/`)

Esta pasta contém o **Robô Caótico** do Aresta Climb: um motor de testes exploratórios determinísticos (*Monkey / Fuzzing Testing*) que navega autonomamente pelo aplicativo exercitando interações de UI, transições assíncronas incompletas e datasets de estresse.

## Arquitetura dos Arquivos

- `receita_crash_robo.dart` e `receita_crash_robo_test.dart`: Modelos de ações (`PassoRobo`), seletores semânticos resilientes (`SeletorAlvoRobo`) e serialização JSON do pacote de reprodução (`ReceitaCrashRobo`).
- `encolhedor_caminho_crash.dart` e `encolhedor_caminho_crash_test.dart`: Algoritmo *Delta Debugging* (`ddmin`) por busca binária que reduz sequências longas de passos aleatórios até a sequência mínima (`passos_minimos`) capaz de reproduzir a mesma assinatura de falha.
- `fabrica_dataset_caos.dart` e `fabrica_dataset_caos_test.dart`: Geração determinística dos perfis `TipoDatasetCaos.normal` e `TipoDatasetCaos.toxico` (picos vazios, strings de 300+ caracteres com emojis/Markdown limite, setores de alto volume com 60 vias e cadenas órfãs) e montagem da árvore real do aplicativo (`AmbienteAppCaos`).
- `motor_robo_caotico.dart` e `motor_robo_caotico_test.dart`: Orquestrador sobre `WidgetTester` que descobre widgets visíveis, sorteia ações guiadas por `seed`, alterna entre `pump(50..350ms)` e `pumpAndSettle()`, realiza o shrinking automático ao encontrar falhas e anexa o contexto `receita_robo_caotico` no `AppLogger.logCrash` (Sentry).
- `robo_caotico_exploratorio_test.dart`: Suíte exploratória parametrizada por `--dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS` (padrão `0`, fazendo skip automático no `flutter test` do dia a dia; `300` segundos com semente variável no workflow de release).
- `regressao_caminhos_test.dart` e `caminhos_regressao/*.json`: Suíte permanente de regressão que carrega todas as receitas `.json` salvas e as reexecuta em `< 1s` para impedir que crashes corrigidos voltem a ocorrer.

## Como Executar

```bash
# Executar os testes unitários do módulo de caos + receitas permanentes de regressão (skip automático da campanha aleatória)
flutter test test/caos/

# Executar apenas as receitas permanentes de regressão
flutter test test/caos/regressao_caminhos_test.dart

# Executar uma campanha exploratória sob demanda (ex: 15 ou 60 segundos com semente variável)
flutter test test/caos/robo_caotico_exploratorio_test.dart --dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS=15
```
