# Design

## Context

Conforme detalhado em `proposal.md`, os SDKs nativos do Firebase para Android e iOS (`firebase_remote_config` e `firebase_app_check`) comunicam-se com o Flutter via canais de plataforma (Pigeon). Quando o dispositivo está sem conexão à internet (por exemplo, em setores de escalada sem sinal ou antes da rede móvel estabilizar), a tentativa de `fetchAndActivate()` no Remote Config falha na etapa prévia do SDK nativo (`FirebaseInstallations.getToken`) ou na chamada HTTP do cliente nativo. O Pigeon descarta a `cause` Java/Swift original (`UnknownHostException` / `SocketTimeoutException`) e entrega ao Dart uma `FirebaseException(plugin: 'firebase_remote_config', code: 'internal', message: 'Firebase Installations failed to get installation auth token for fetch.')`.

## Goals / Non-Goals

**Goals:**
- Impedir que falhas de conectividade nos SDKs nativos do Firebase (`RemoteConfigService` e `AppCheckService`) gerem falsos positivos de *Non-fatal Exception* no painel do Firebase Crashlytics.
- Preservar o registro de breadcrumbs no Crashlytics via `AppLogger.instance.logAviso` para manter visibilidade de diagnóstico caso um crash real ocorra na mesma sessão.
- Permitir que o `RemoteConfigService` possa tentar sincronizar novamente na mesma sessão caso a primeira tentativa em `initialize()` tenha falhado por falta de rede.

**Non-Goals:**
- Não alterar os intervalos de cache (`minimumFetchInterval: 12 horas`) nem o timeout (`fetchTimeout: 10 segundos`) do Firebase Remote Config.
- Não bloquear a inicialização do aplicativo esperando conectividade de rede.

## Decisions

### 1. Reconhecimento de `FirebaseException` e padrões nativos em `AppLogger.isFalhaConexaoOuTimeout`
- **Decisão**: Receber qualquer `error` em `AppLogger.isFalhaConexaoOuTimeout` e, além das checagens atuais de exceções Dart/HTTP, verificar:
  - Se `error is FirebaseException` (de `package:firebase_core/firebase_core.dart`), avaliar se `error.code` indica falha de rede/indisponibilidade (`unavailable`, `network-request-failed`, `network_error`, `deadline-exceeded`, `throttled`).
  - Na análise textual (`error.toString().toLowerCase()`), incluir as assinaturas de falha de transporte dos SDKs nativos do Firebase:
    - `'firebase installations failed to get installation auth token'`
    - `'error while calling the backend'`
    - `'unable to connect to the server'`
    - `'fetch failed'`
    - `'network-request-failed'` / `'network_error'` / `'network error'`
    - `'service unavailable'` / `'unavailable'`
- **Alternativa considerada**: Tratar apenas dentro de `remote_config.dart`. Descartada porque `AppCheckService.getToken()` e futuros consumidores de serviços Firebase sofrem do mesmo encapsulamento de erro pelo Pigeon quando o aparelho está offline.

### 2. Separação entre configuração local e `fetchAndActivate` no `RemoteConfigService`
- **Decisão**: Em `RemoteConfigService._initializeInternal()`, manter `setDefaults` e `setConfigSettings` protegidos e garantir que, se `fetchAndActivate()` falhar com erro transitório/rede (identificado por `AppLogger.isFalhaConexaoOuTimeout(e)`), o serviço:
  1. Registre `AppLogger.instance.logAviso(...)`;
  2. Redefina `_initFuture = null` para que uma chamada subsequente a `initialize()` (por exemplo, ao recriar/atualizar estado ou reconectar) não fique presa no `Future` concluído da tentativa falha offline.
- **Alternativa considerada**: Manter `_initFuture` cacheado mesmo após erro de rede. Descartada porque impedia qualquer nova tentativa de sincronização das flags remotas durante todo o ciclo de vida restante do app se ele fosse aberto em modo avião.

### 3. Tratamento de falhas de rede em `AppCheckService.getToken`
- **Decisão**: No bloco `catch (e, stackTrace)` de `AppCheckService.getToken()`, verificar `if (AppLogger.isFalhaConexaoOuTimeout(e))` e registrar com `AppLogger.instance.logAviso` em vez de `logError`. Erros genuínos de configuração ou atestação fora do escopo de rede continuam sendo reportados via `logError`.

## Risks / Trade-offs

- **[Risco] Mascarar erro de restrição de API Key do Google Cloud para o Firebase Installations** → **Mitigação**: O erro continua sendo emitido no console em modo debug (`⚠️ [AppLogger AVISO]`) e gravado como breadcrumb (`FirebaseCrashlytics.instance.log`) em produção, permanecendo visível na aba *Logs* de qualquer sessão no Crashlytics sem poluir a fila de *Issues* com falhas de usuários offline na rocha.
