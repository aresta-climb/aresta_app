## 1. Backend (Nova Edge Function `app-feedback` em `../aresta_backend/supabase`)

- [x] 1.1 Implementar testes automatizados da Edge Function para cenários de token válido, token ausente/inválido (403), rate limit por IP (429) e retentativa em 429 do Discord.
- [x] 1.2 Criar a nova Edge Function `app-feedback` em `../aresta_backend/supabase/functions/app-feedback/index.ts` com validação criptográfica do JWT `X-Firebase-AppCheck` contra as chaves públicas (JWKS) do Google/Firebase, mantendo a função legada `discord-feedback` inalterada.
- [x] 1.3 Implementar limitador de taxa (Rate Limiting) por endereço IP de origem permitindo no máximo 5 requisições por minuto com cabeçalho `Retry-After`.
- [x] 1.4 Implementar lógica de retentativa automática com espera proporcional quando o webhook do Discord responder com `HTTP 429`.

## 2. Dependências e Inicialização no Frontend (TDD)

- [x] 2.1 Adicionar a dependência `firebase_app_check` no `frontend/pubspec.yaml` e executar `flutter pub get`.
- [x] 2.2 Escrever testes unitários e de inicialização para a ativação do Firebase App Check no `frontend/test/`.
- [x] 2.3 Implementar a inicialização do `FirebaseAppCheck` no `frontend/lib/main.dart` utilizando provedores condicionais (`playIntegrity` e `appAttest` em release, `debug` em modo de depuração).
- [x] 2.4 [TDD] Criar testes unitários para `NetworkConstants` em `frontend/test/constants/network_constants_test.dart` cobrindo fallback offline e override dinâmico via Firebase Remote Config (`serving_base_url`).
- [x] 2.5 Atualizar `frontend/lib/constants/network_constants.dart` para resolver a URL base do serving via Remote Config com fallback em `kDefaultBaseUrl`.
- [x] 2.6 Definir a constante padrão `kDefaultFeedbackEdgeFunctionUrl` apontando para a rota `/functions/v1/app-feedback` e registrar os valores padrão (`feedback_edge_function_url` e `serving_base_url`) no `FirebaseRemoteConfig`.

## 3. Refatoração do Serviço de Rede e Orquestrador de Feedback (TDD)

- [x] 3.1 [TDD] Criar o arquivo de teste `frontend/test/services/feedback/feedback_network_service_test.dart` cobrindo envio para `app-feedback` com cabeçalho `X-Firebase-AppCheck`, ausência de chave estática e tratamento de códigos de status HTTP.
- [x] 3.2 Implementar a refatoração do `FeedbackNetworkService` em `frontend/lib/services/feedback/feedback_network_service.dart` para anexar o token do App Check e remover a dependência de `apiKey`.
- [x] 3.3 [TDD] Atualizar os testes em `frontend/test/application_managers/feedback/feedback_orchestrator_test.dart` cobrindo resolução da URL via Remote Config com fallback offline e mock gracioso em modo de depuração (`kDebugMode`).
- [x] 3.4 Implementar a resolução dinâmica de URL e o fallback com log gracioso de depuração no `FeedbackOrchestrator` em `frontend/lib/application_managers/feedback/feedback_orchestrator.dart`.
- [x] 3.5 Adicionar docstrings abrangentes em português (`///`) em todos os métodos, parâmetros e classes alterados ou introduzidos, explicando a intenção e decisões arquiteturais.

## 4. Política de Privacidade e Automação de Release no CI/CD

- [x] 4.1 Atualizar a Política de Privacidade (`POLITICA_DE_PRIVACIDADE_ARESTA_CLIMB.md` no repositório legal / `arestaclimb.com`) incluindo o serviço do Firebase App Check e a cláusula de prevenção a fraudes e atestação.
- [x] 4.2 Atualizar o workflow `.github/workflows/release_new_app_version.yml` para sincronizar automaticamente o submódulo legal (`frontend/legal/repo`) e rodar `update_legal_version.dart` a cada novo release.
- [x] 4.3 Remover parâmetros `--dart-define="FEEDBACK_EDGE_FUNCTION_URL=..."` e `--dart-define="FEEDBACK_EDGE_FUNCTION_API_KEY=..."` dos workflows `.github/workflows/build_android.yml` e `.github/workflows/build_ios.yml`.
- [x] 4.4 Atualizar `frontend/lib/README.md` refletindo a nova arquitetura do App Check, URLs dinâmicas do Remote Config e remoção de segredos estáticos.
- [x] 4.5 Executar `flutter analyze` e `flutter test --coverage` validando 100% de cobertura de testes e zero erros de linter.
