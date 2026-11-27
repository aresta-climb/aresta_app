# Tasks

## 1. Evolução do Robô Caótico (`frontend/test/caos/` e `ServicoAutenticacaoFake`)

- [x] 1.1 Adicionar suporte opcional a cancelamento único em `ServicoAutenticacaoFake` (`cancelarApenasUmaVez`) com teste comportamental em `servico_autenticacao_fake_test.dart`
- [x] 1.2 Atualizar `FabricaDatasetCaos` com UIDs NanoID Base62 de 14 caracteres válidos (`validarUid`), `interacoesIniciais` (alertas Waze próprios e de terceiros, votos de grau e betas) e injeção real de `cadenasIniciais`, `interacoesIniciais`, isolamento de estado e alternância Android/iOS por `seed` em `AmbienteAppCaos`, verificando com `fabrica_dataset_caos_test.dart`
- [x] 1.3 Evoluir `MotorRoboCaotico` (`motor_robo_caotico.dart`) para aceitar `montarCenarioComSeed` preservado no *shrinking*, incluir entradas de fuzz para Magic Code OTP (`escalador@arestaclimb.com`, `123456`, `000000`) e descobrir alvos `BolhaEmojiAlertaVia` / `GestureDetector` com `ValueKey<String>` e `onTap`, verificando com `motor_robo_caotico_test.dart`
- [x] 1.4 Atualizar `frontend/test/caos/README.md` com os novos fluxos de caos cobertos e validar campanha exploratória local (`DURACAO_CAMPANHA_CAOS_SEGUNDOS=20` e `REPORTAR_SENTRY_CAOS=false`)

## 2. Servidor Loopback `ServidorSmokeCi` e PKCE Real no iOS Simulator

- [x] 2.1 Expandir `ServidorSmokeCi` (`frontend/tool/release_tools/servidor_smoke_ci.dart`) com testes TDD prévios em `servidor_smoke_ci_test.dart` para suportar `/auth/v1/otp`, `/auth/v1/verify`, `/auth/v1/authorize` + `/auth/v1/token?grant_type=pkce` (validando S256), `grant_type=refresh_token`, `/rest/v1/rpc/excluir_minha_conta`, CRUD `/rest/v1/fila_interacoes` com alerta inicial semeado de terceiro e endpoint `/__smoke__/falhar-proxima-escrita-fila` (`503`)
- [x] 2.2 Atualizar `frontend/ios/Runner/AppDelegate.swift` (isolado em `#if targetEnvironment(simulator)`) para que `solicitarIdTokenGoogle` execute `GET /auth/v1/authorize` no loopback quando receber `urlAutorizacaoPkce` e retorne `callbackUrl` real

## 3. Piloto de UI Real e Jornada Pós-Build Completa (`frontend/lib/services/smoke_ci/`)

- [x] 3.1 Criar `PilotoArvoreUiSmoke` (`frontend/lib/services/smoke_ci/piloto_arvore_ui_smoke.dart`) sem `flutter_test` e com teste espelhado `piloto_arvore_ui_smoke_test.dart` validando bombeamento híbrido, busca por `ValueKey<String>`, toque físico por *hit-test* e digitação em `EditableTextState` com `inputFormatters`
- [x] 3.2 Conectar `RepositorioInteracoesViaMemoria` em `main_smoke_ci.dart` apontando para o servidor loopback, garantir que `HubPerfilCadernetaViewModel.comCatalogo` reutilize `ServicoAutenticacaoLocal.instancia` e expandir `ExecutorJornadaSmoke` (`executor_jornada_smoke.dart`) com todas as etapas de autenticação multiplataforma, modais reais, fila offline/online, `CadernetaPage` e exclusão de conta
- [x] 3.3 Expandir `executor_jornada_smoke_test.dart` e `main_smoke_ci_test.dart` validando fluxos completos Android e iOS em viewport Pixel 6 (`412x915dp`, `dpr 3.0`) e atualizar `frontend/lib/services/smoke_ci/README.md`

## 4. Integração e Validação Final

- [x] 4.1 Executar `dart analyze --fatal-infos --fatal-warnings`, suítes unitárias/arquiteturais/smoke e campanha exploratória do Robô Caótico (20s) sem erros

## Workflow follow-up

- Sincronizar delta specs para `openspec/specs/` e arquivar a change em `openspec/changes/archive/`.
- Realizar commit escopado apenas aos arquivos desta entrega e enviar via `git push`.
