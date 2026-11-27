# Testes Exploratórios e Regressão (`test/caos/`)

Este diretório contém o **Robô Caótico**: um executor determinístico de interações aleatórias guiadas por `seed` sobre a árvore de widgets do aplicativo, acompanhado de redução de passos (`ddmin`) e receitas de regressão em JSON.

## Arquivos

- `receita_crash_robo.dart` e `receita_crash_robo_test.dart`: Estrutura de passos (`PassoRobo`), seletores (`SeletorAlvoRobo`) e serialização JSON (`ReceitaCrashRobo`).
- `encolhedor_caminho_crash.dart` e `encolhedor_caminho_crash_test.dart`: Implementação de *Delta Debugging* (`ddmin`) para reduzir uma sequência de falha ao menor conjunto de passos que reproduz o mesmo erro.
- `fabrica_dataset_caos.dart` e `fabrica_dataset_caos_test.dart`: Geração dos datasets `normal` e `toxico` com UIDs NanoID 14c válidos, picos vazios, textos longos com emojis/Markdown, setores com 60 vias, cadenas órfãs e interações comunitárias (alertas Waze, votos e betas), além da montagem de `AmbienteAppCaos` com isolamento por semente, alternância Android/iOS, simulação de cancelamento OAuth e desconexão offline.
- `motor_robo_caotico.dart` e `motor_robo_caotico_test.dart`: Localiza widgets interativos na tela (incluindo `BotaoVoltarComRetornoInicio`, `BolhaEmojiAlertaVia` e `GestureDetector` identificados por `ValueKey`), executa toques, rolagens e digitação (incluindo entradas válidas e inválidas de Magic Code OTP), alterna entre `pump` parcial e `pumpAndSettle`, captura exceções, `FlutterError` (como overflow) e chamadas a `AppLogger.logError`/`logCrash`, reduz o caminho com `ddmin` e envia `receita_robo_caotico` ao Sentry.
- `robo_caotico_exploratorio_test.dart`: Campanha controlada por `--dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS` (padrão `0`, ignorada no `flutter test` padrão).
- `../../integration_test/robo_caotico_dispositivo_test.dart`: Execução visual em emulador, aparelho físico ou desktop (`defaultValue: 60` segundos).
- `regressao_caminhos_test.dart` e `caminhos_regressao/*.json`: Reexecuta todas as receitas JSON gravadas para evitar regressões.

## Integração com Sentry

`REPORTAR_SENTRY_CAOS` é `true` por padrão nas campanhas exploratórias usando `kSentryDsn`. Para rodar localmente sem envio ao Sentry, passe `--dart-define=REPORTAR_SENTRY_CAOS=false`.

## Execução (a partir de `frontend/`)

```powershell
# Campanha no terminal por 60 segundos
flutter test test/caos/robo_caotico_exploratorio_test.dart --dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS=60

# Campanha em emulador ou dispositivo conectado
flutter test integration_test/robo_caotico_dispositivo_test.dart --dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS=60

# Apenas receitas de regressão salvas
flutter test test/caos/regressao_caminhos_test.dart

# Uma receita específica
flutter test test/caos/regressao_caminhos_test.dart --plain-name "regressao_exemplo_navegacao_seed_42.json"

# Testes unitários do módulo + regressões
flutter test test/caos/
```
