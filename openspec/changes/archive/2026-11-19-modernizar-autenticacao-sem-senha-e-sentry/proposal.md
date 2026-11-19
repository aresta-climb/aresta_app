# Proposal

## Why

A camada atual de autenticação do `aresta_app` ainda mantém login e cadastro por senha, fluxos OAuth legados que caem em navegador externo (`url_launcher` + `app_links` com timeout de 3 minutos), ausência da capability nativa `com.apple.developer.applesignin` no iOS, SDK depreciado `play-services-auth` no Android, contas sintéticas silenciosas de fallback em produção (`usr_*`) quando `anonKey` está vazia, uso de `LoginViewModel` após `dispose()` (`ARESTA-APP-G`) e rebaixamento indevido de qualquer `HttpException` (inclusive `400`/`401`/`403`/`500`) para aviso offline no `AppLogger`. Modernizar toda a autenticação para zero senhas (Magic Code OTP de 6 dígitos via Resend + fluxos in-app modernos Google/Apple por plataforma), eliminar fallbacks perigosos, corrigir os `try/catch` silenciosos e manter integralmente o recurso protegido atrás da feature flag `ConfiguracaoRecursos.perfilHabilitado` alinha o aplicativo aos princípios do `AGENTS.md` e à infraestrutura compartilhada com `fixalog` e `aresta_db`.

## What Changes

- **BREAKING**: Remover integralmente todo o suporte a autenticação e criação de conta por senha (`entrarComEmailSenha`, `criarContaComEmailSenha`, `autenticarEmailSenha`, `criarConta`, `CartaoFormularioEmailLogin` e campos/estados de senha em `LoginViewModel` e `LoginPage`), garantindo zero armazenamento ou tráfego de senhas no aplicativo.
- Substituir o formulário de e-mail por autenticação sem senha via **Magic Code (OTP de 6 dígitos)** alinhada ao `aresta_db` (`POST /auth/v1/otp` com `create_user: true` via Resend e `POST /auth/v1/verify` com `type: "email"`), incluindo controle de frequência por janela deslizante de até 6 envios em 60 segundos com contagem regressiva e tradução amigável das mensagens de cooldown/expiração do Supabase.
- **BREAKING**: Remover o fluxo OAuth por navegador externo (`url_launcher` + `app_links` + `processarCallbackOAuth`) e migrar os provedores sociais para fluxos modernos 100% in-app específicos por plataforma:
  - **Android**: Exibir apenas **Continuar com o Google** (ocultando o botão da Apple), migrando `MainActivity.kt` e `build.gradle.kts` do `play-services-auth` depreciado para `androidx.credentials.CredentialManager` + `GetGoogleIdOption`.
  - **iOS**: Exibir **Continuar com o Google** e **Continuar com a Apple**, adicionando `com.apple.developer.applesignin` em `Runner.entitlements` e implementando `ASWebAuthenticationSession` in-app com PKCE (`callbackURLScheme: "aresta"`) em `AppDelegate.swift` para o Google.
- **BREAKING**: Remover todos os fallbacks silenciosos de contas locais fictícias (`usr_google_*`, `usr_apple_*`, `usr_email_*`, `usr_conta_*`) em `ServicoAutenticacaoLocal` quando `anonKey` estiver vazia, falhando explicitamente (*Fail-Fast*) e mantendo apenas o botão explícito **Continuar sem conta / Offline** para uso desautenticado.
- Tratar cancelamentos voluntários do usuário nos modais nativos (`cancelado == true` -> `ExcecaoAutenticacaoCancelada`) de forma silenciosa (sem banner de erro na UI e sem envio ao Sentry) e blindar `LoginViewModel` contra `notifyListeners()` após `dispose()` (resolvendo `ARESTA-APP-G`).
- Preservar integralmente a proteção por feature flag (`ConfiguracaoRecursos.perfilHabilitado`, inativa por padrão em produção) em todos os pontos de entrada de Perfil, Login e Caderneta.
- Atualizar `AppLogger.isFalhaConexaoOuTimeout` para inspecionar códigos de status HTTP em exceções tipadas (`ExcecaoComStatusHttp`) e mensagens de `HttpException`, rebaixando para `logAviso` apenas códigos transitórios (`408`, `429`, `502`, `503`, `504`) ou falhas puras de transporte sem código HTTP, e encaminhar falhas reais com `StackTrace` em `LoginViewModel`, `SincronizadorPerfilSupabase`, `mapa_global.dart`, `mapa_marker.dart` e `comunidade_functions.dart`.

## Capabilities

### New Capabilities
- `autenticacao-escalador`: Autenticação opcional sem senha (atrás da feature flag `ConfiguracaoRecursos.perfilHabilitado`) com Magic Code OTP de 6 dígitos por e-mail, login social in-app por plataforma (Google no Android e iOS; Apple apenas no iOS), cancelamento voluntário silencioso, proibição de contas sintéticas de fallback em produção e preservação da caderneta offline.

### Modified Capabilities
- `padronizacao-logging-applogger`: Inspeção obrigatória de códigos de status HTTP em `AppLogger.isFalhaConexaoOuTimeout` antes de rebaixar `HttpException` para aviso offline, e eliminação de blocos `catch` silenciosos nos serviços de autenticação/sincronização de perfil e componentes de mapa/comunidade.

## Impact

- **Autenticação e Perfil (`frontend/lib/services/autenticacao/`, `view_models/login_view_model.dart`, `widgets/autenticacao/componentes_login.dart`, `pages/login.dart`, `navigation/servico_navegacao_deep_link.dart`)**: Remoção de senha e callback OAuth externo, introdução do fluxo OTP de 6 dígitos (`CartaoCodigoEmailLogin`), `ExcecaoAutenticacaoCancelada`, `ServicoAutenticacaoFake` para testes e blindagem pós-`dispose` no `LoginViewModel`.
- **Integrações Nativas (`frontend/android/app/build.gradle.kts`, `MainActivity.kt`, `frontend/ios/Runner/Runner.entitlements`, `AppDelegate.swift`)**: Substituição de `play-services-auth` por `CredentialManager` + `googleid` no Android; adição de entitlement `Sign in with Apple` e `ASWebAuthenticationSession` com PKCE no iOS.
- **Observabilidade (`frontend/lib/services/firebase/app_logger.dart`, `sincronizador_perfil_supabase.dart`, `mapa_global.dart`, `mapa_marker.dart`, `comunidade_functions.dart`)**: Classificação precisa de erros HTTP vs. desconexão transitória e captura com `StackTrace` para Sentry e Crashlytics.
- **Feature Flag (`frontend/lib/services/configuracao_recursos.dart`, `widgets/app_bar_home_aresta.dart`)**: Mantida intacta (`perfilHabilitado == false` por padrão em builds de produção sem chave/flag).
