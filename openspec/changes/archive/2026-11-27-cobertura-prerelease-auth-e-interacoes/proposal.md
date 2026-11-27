# Proposal

## Why

O aplicativo evoluiu com novos fluxos de autenticação sem senha (código OTP de 6 dígitos via e-mail, Google `id_token` no Android, Google OAuth PKCE in-app no iOS e Apple ID nativo no iOS) e um conjunto rico de interações comunitárias offline-first (caderneta de cadenas, consenso de grau, comentários públicos de beta com edição/exclusão e alertas de segurança estilo Waze com confirmação *"Ainda está lá?"* e fila offline *outbox*). Entretanto, tanto a campanha do Robô Caótico quanto o Smoke Test pós-build ainda exercitavam apenas o caminho legado parcial (login Google via `id_token` direto em serviço e salvamento programático de cadena), deixando os novos caminhos sem cobertura real nos testes de pré-lançamento.

## What Changes

- **Evolução do Robô Caótico (`frontend/test/caos/`):**
  - Correção dos UIDs de dataset para o padrão canônico NanoID Base62 de 14 caracteres (`validarUid`) e injeção efetiva de `cadenasIniciais` e `interacoesIniciais` (alertas Waze, votos de grau e betas) nos datasets normal e tóxico.
  - Isolamento determinístico de sessão, caderneta, fila de interações e plataforma alvo (`TargetPlatform.android` vs `TargetPlatform.iOS`) por `seed`, além da simulação de cancelamento voluntário OAuth e falhas de rede na alternância de conectividade.
  - Descoberta de controles customizados com `GestureDetector(onTap)`/bolhas de alerta e inclusão de entradas de fuzz capazes de atravessar as etapas de Magic Code OTP (código válido e inválido).
- **Evolução do Smoke Test Pós-Build (`frontend/lib/services/smoke_ci/`, `frontend/tool/release_tools/`, `frontend/ios/Runner/AppDelegate.swift`):**
  - Expansão do micro-servidor local `ServidorSmokeCi` para emular fielmente `/auth/v1/otp`, `/auth/v1/verify`, `/auth/v1/authorize` (PKCE S256), `/auth/v1/token` (`id_token`, `pkce`, `refresh_token`), `/rest/v1/rpc/excluir_minha_conta` e CRUD completo de `/rest/v1/fila_interacoes` com suporte a injeção determinística de indisponibilidade (`503`).
  - Atualização do `AppDelegate.swift` (isolada em `#if targetEnvironment(simulator)`) para exercitar o fluxo Google OAuth PKCE com retorno de `callbackUrl` real no iOS Simulator.
  - Criação do `PilotoArvoreUiSmoke` (operando sobre `WidgetsBinding`/`GestureBinding` sem dependência de `flutter_test`) para acionar páginas e modais reais na árvore ofuscada (`LoginPage`, `DialogoEditarPerfil`, `ModalRegistroCadena`, edição de comentário, modais de alerta Waze e `CadernetaPage`).

## Capabilities

### New Capabilities

### Modified Capabilities
- `robo-caotico-testes-exploratorios`: Amplia a descoberta de alvos interativos customizados, as entradas de fuzz para Magic Code OTP, a alimentação efetiva de cadenas e interações comunitárias e o isolamento determinístico de estado e plataforma por semente.
- `smoke-test-pos-build`: Expande a jornada pós-build nos binários ofuscados para conduzir modais reais da árvore de widgets e validar autenticação OTP, Google OIDC/PKCE, Apple OIDC, refresh token, exclusão de conta e o ciclo completo de interações comunitárias e fila offline.

## Impact

- **Testes exploratórios (`frontend/test/caos/`):** `fabrica_dataset_caos.dart`, `motor_robo_caotico.dart`, `fabrica_dataset_caos_test.dart`, `motor_robo_caotico_test.dart`, `README.md`.
- **Fake de autenticação (`frontend/test/services/autenticacao/`):** `servico_autenticacao_fake.dart`, `servico_autenticacao_fake_test.dart`.
- **Módulo isolado de smoke pós-build (`frontend/lib/services/smoke_ci/`):** `piloto_arvore_ui_smoke.dart`, `executor_jornada_smoke.dart`, `main_smoke_ci.dart`, `README.md` e testes espelhados em `frontend/test/services/smoke_ci/`.
- **Orquestração e plataforma (`frontend/tool/release_tools/`, `frontend/ios/Runner/`):** `servidor_smoke_ci.dart`, `servidor_smoke_ci_test.dart`, `AppDelegate.swift`.
- **Segurança de produção:** O código de produção em `lib/` fora de `lib/services/smoke_ci/` e a auditoria de pureza binária permanecem isolados e inalterados.
