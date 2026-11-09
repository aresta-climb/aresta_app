# Testes Caóticos Exploratórios e Regressão (`test/caos/`)

Esta pasta contém o **Robô Caótico** do Aresta Climb: um motor de testes exploratórios determinísticos (*Monkey / Fuzzing Testing*) que navega autonomamente pelo aplicativo completo exercitando interações de UI, transições assíncronas incompletas e datasets de estresse.

## Arquitetura dos Arquivos

- `receita_crash_robo.dart` e `receita_crash_robo_test.dart`: Modelos de ações (`PassoRobo`), seletores semânticos resilientes (`SeletorAlvoRobo`) e serialização JSON do pacote de reprodução (`ReceitaCrashRobo`).
- `encolhedor_caminho_crash.dart` e `encolhedor_caminho_crash_test.dart`: Algoritmo *Delta Debugging* (`ddmin`) por busca binária que reduz sequências longas de passos aleatórios até a sequência mínima (`passos_minimos`) capaz de reproduzir a mesma assinatura de falha.
- `fabrica_dataset_caos.dart` e `fabrica_dataset_caos_test.dart`: Geração determinística dos perfis `TipoDatasetCaos.normal` e `TipoDatasetCaos.toxico` (picos vazios, strings de 300+ caracteres com emojis/Markdown limite, setores de alto volume com 60 vias e cadenas órfãs) e montagem da árvore real do aplicativo (`AmbienteAppCaos`).
- `motor_robo_caotico.dart` e `motor_robo_caotico_test.dart`: Orquestrador sobre `WidgetTester` que descobre widgets visíveis, sorteia ações guiadas por `seed`, alterna entre `pump(50..350ms)` e `pumpAndSettle()`, intercepta crashes não tratados, `FlutterError` (incluindo `RenderFlex overflow`) e erros tratados registrados em `AppLogger.logError`/`logCrash`, realiza o shrinking automático (`ddmin`) e anexa o contexto `receita_robo_caotico` no Sentry.
- `robo_caotico_exploratorio_test.dart`: Suíte exploratória parametrizada por `--dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS` (padrão `0`, fazendo skip automático no `flutter test` do dia a dia; quando executada, já mantém o Sentry ativo por padrão via `REPORTAR_SENTRY_CAOS=true` e `kSentryDsn`).
- `../../integration_test/robo_caotico_dispositivo_test.dart`: Suíte para assistir o Robô Caótico agindo ao vivo na tela em emulador, celular físico ou desktop (`defaultValue: 60` segundos e `REPORTAR_SENTRY_CAOS=true` por padrão).
- `regressao_caminhos_test.dart` e `caminhos_regressao/*.json`: Suíte permanente de regressão que carrega todas as receitas `.json` salvas e as reexecuta em `< 1s` para impedir que falhas corrigidas voltem a ocorrer.

## Observabilidade e Sentry em Tempo Real

- O `SENTRY_DSN` já está configurado no aplicativo (`kSentryDsn` em `lib/main.dart`) e `REPORTAR_SENTRY_CAOS` é **`true` por padrão** tanto em `robo_caotico_exploratorio_test.dart` quanto em `integration_test/robo_caotico_dispositivo_test.dart`.
- Durante a campanha, o Sentry permanece liberado em tempo real (agrupando ocorrências repetidas na mesma Issue pela deduplicação nativa do Sentry) e, ao término do shrinking (`ddmin`), recebe também o evento com a `receita_robo_caotico` anexada.
- Caso deseje rodar localmente sem enviar eventos ao Sentry, passe `--dart-define=REPORTAR_SENTRY_CAOS=false`.

## Como Executar (a partir da pasta `frontend/`)

```powershell
# 1. Executar uma campanha exploratória no terminal (ex: 30 ou 60 segundos, já reportando ao Sentry por padrão)
flutter test test/caos/robo_caotico_exploratorio_test.dart --dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS=60

# 2. Ver o Robô Caótico agindo ao vivo na tela (emulador ou celular conectado, padrão 60s)
flutter test integration_test/robo_caotico_dispositivo_test.dart --dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS=60

# 3. Executar apenas as receitas permanentes de regressão (< 1s)
flutter test test/caos/regressao_caminhos_test.dart

# 4. Executar uma única receita específica pelo nome do arquivo JSON
flutter test test/caos/regressao_caminhos_test.dart --plain-name "regressao_exemplo_navegacao_seed_42.json"

# 5. Executar os testes unitários do módulo de caos + receitas permanentes de regressão
flutter test test/caos/
```
