## Contexto

O aplicativo Aresta Climb dispõe de um recurso de envio de feedback pelos usuários, capturando descrição textual, metadados estruturados do dispositivo e captura de tela opcional. Esses dados são transmitidos para uma Edge Function no Supabase, que os processa e publica no canal da equipe.

Atualmente, o endpoint legado (`discord-feedback`) depende de uma chave secreta estática (`FEEDBACK_EDGE_FUNCTION_API_KEY`) injetada via `--dart-define`. Para modernizar e blindar a arquitetura sem quebrar versões antigas do aplicativo em produção, criaremos uma nova Edge Function no Supabase nomeada semanticamente como **`app-feedback`** (desacoplando o nome da rota do destino final).

Adicionalmente, expandiremos o uso do **Firebase Remote Config** para cobrir tanto o endpoint de feedback quanto a URL base do servidor oficial de dados (`serving.arestaclimb.com`), possibilitando migrações ou manutenções de infraestrutura emergenciais sem necessidade de compilar novos binários para as lojas.

## Objetivos e Não-Objetivos

**Objetivos:**
- Criar a nova Edge Function `app-feedback` em `../aresta_backend/supabase/functions/app-feedback` com autenticação criptográfica via Firebase App Check (Google Play Integrity / Apple App Attest).
- Preservar a Edge Function legada `discord-feedback` intacta para garantir retrocompatibilidade com versões antigas instaladas nos celulares dos usuários.
- Eliminar chaves de API estáticas e dependências de arquivos `.env` ou `--dart-define` no frontend e nos workflows de CI/CD.
- Aplicar limitação de taxa baseada em endereço IP (5 requisições por minuto por IP) na Edge Function `app-feedback`.
- Permitir a reconfiguração dinâmica da URL do endpoint de feedback (`feedback_edge_function_url`) e da URL do servidor de serving (`serving_base_url`) via Firebase Remote Config, preservando constantes locais compiladas (`kDefaultFeedbackEdgeFunctionUrl` e `kDefaultBaseUrl`) para resiliência offline.
- Prover uma experiência de desenvolvimento simples (DX) para código aberto com logs graciosos no console para quem não tiver UUID cadastrado no Firebase Console.
- Garantir zero perda de feedbacks com tratamento de retentativa para o webhook do Discord e integração com a fila local persistente existente no aplicativo.
- Automatizar a sincronização da Política de Privacidade e cálculo da versão dos termos no workflow de release unificado (`release_new_app_version.yml`).
- Seguir estritamente as diretrizes de [PRINCIPIOS.md](file:///c:/Renato/Devel/aresta-climb/aresta_app/PRINCIPIOS.md) (Tudo em Português, TDD, 100% de cobertura de testes, Simplicidade e Documentação contínua).

**Não-Objetivos:**
- Desativar ou deletar a rota legada `discord-feedback` enquanto houver usuários em versões antigas.
- Exigir login ou autenticação OAuth dos usuários finais para envio de feedback.
- Implementar desafios complexos de Proof-of-Work (PoW/Hashcash) no cliente.

## Decisões Técnicas

### 1. Nomenclatura Semântica: `app-feedback` (Novo Endpoint)
- **Decisão**: Criar a nova Edge Function sob a rota `/functions/v1/app-feedback` em vez de sobrescrever `discord-feedback`.
- **Justificativa**: 
  1. *Desacoplamento*: O destino do feedback (Discord, Slack, banco de dados ou e-mail) é um detalhe interno de infraestrutura do backend. O cliente mobile só precisa saber que está enviando um `app-feedback`.
  2. *Retrocompatibilidade*: Versões legadas do app que ainda usam a chave estática continuarão funcionando normalmente na rota `discord-feedback` antiga.

### 2. Firebase App Check para Atestação de Integridade
- **Decisão**: Utilizar o pacote `firebase_app_check` no frontend Flutter e validar o token JWT nas chaves públicas do Google (JWKS) na Edge Function `app-feedback`.
- **Justificativa**: O projeto já possui o ecossistema Firebase inicializado (`firebase_core`, `firebase_remote_config`, `google-services.json`). O App Check encapsula as APIs de Play Integrity (Android) e App Attest (iOS) em uma interface unificada, com gerenciamento automático de renovação de tokens e suporte nativo a tokens de depuração.

### 3. URLs Dinâmicas com Resiliência Offline: Constante Padrão + Firebase Remote Config
- **Decisão**:
  - `feedback_edge_function_url`: constante padrão `kDefaultFeedbackEdgeFunctionUrl` no código, substituível via chave de Remote Config.
  - `serving_base_url`: constante padrão `kDefaultBaseUrl` (`https://serving.arestaclimb.com`) no [`NetworkConstants`](file:///c:/Renato/Devel/aresta-climb/aresta_app/frontend/lib/constants/network_constants.dart), substituível via chave de Remote Config.
- **Justificativa**: Respeita estritamente o princípio *Offline-First*. O app sempre funcionará perfeitamente offline ou em cold start antes de qualquer conexão à rede, mas concede à equipe o poder de desviar o tráfego para um servidor/CDN espelho instantaneamente em caso de incidentes.

### 4. Rate Limiting por IP no Servidor (5 requisições / minuto)
- **Decisão**: Implementar controle de taxa deslizante na Edge Function Deno limitando a 5 requisições por janela de 60 segundos por IP de origem.
- **Justificativa**: Resguarda a infraestrutura e a cota do Discord Webhook contra usuários abusivos, respondendo com o padrão `HTTP 429 Too Many Requests` e cabeçalho `Retry-After`.

### 5. Experiência de Desenvolvimento para Código Aberto (Open Source)
- **Decisão**: 
  - Em modo de depuração (`kDebugMode`), se o token do App Check falhar ou não estiver registrado, o orquestrador não lança exceção impeditiva: ele emite um log estruturado no console (`[DEBUG MOCK] Feedback recebido: ...`) e finaliza a tarefa local com sucesso.
  - Para os mantenedores que precisarem testar contra o servidor real em staging, basta cadastrar o UUID exibido no console do Firebase uma única vez.
- **Justificativa**: Permite que qualquer pessoa da comunidade clone o repositório e rode `flutter run` imediatamente, sem necessidade de chaves privadas ou permissões no Firebase.

### 6. Resiliência do Webhook de Destino
- **Decisão**: Caso o webhook do Discord responda com `HTTP 429`, a Edge Function lê o `Retry-After`, aguarda o tempo estipulado (limitado a 3 segundos) e repete a requisição uma vez. Se a indisponibilidade persistir, responde `HTTP 503` para que o `Workmanager` e o `FeedbackLocalRepository` do Flutter reativem a tarefa na fila com backoff exponencial.

## Diagrama da Arquitetura

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           FRONTEND (FLUTTER APP)                            │
│                                                                             │
│  1. Verificação de Ambiente:                                                │
│     - Release: Solicita token via Hardware (Play Integrity / App Attest)    │
│     - Debug com UUID cadastrado: Solicita token via Debug Provider          │
│     - Debug sem UUID: Exibe log no console (Mock gracioso de desenvolvimento)│
│                                                                             │
│  2. Resolução de URLs (Firebase Remote Config com fallback offline):        │
│     - Feedback: `feedback_edge_function_url` -> default: `/app-feedback`    │
│     - Serving: `serving_base_url` -> default: `https://serving.arestaclimb` │
│                                                                             │
│  3. Requisição Multipart POST com cabeçalho `X-Firebase-AppCheck: <JWT>`   │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                 HTTPS POST
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                   SUPABASE EDGE FUNCTION (DENO / TYPESCRIPT)                │
│                   `../aresta_backend/supabase/functions/app-feedback`        │
│                                                                             │
│  Passo 1: Validar JWT do App Check contra JWKS do Google (403 se inválido)  │
│  Passo 2: Validar Rate Limit por IP (5 req / 60s) (429 se estourar)         │
│  Passo 3: Despachar para Webhook do Discord (com retry em 429)              │
│  Passo 4: Retornar 200 OK (ou 503 se Discord falhar -> app retenta na fila) │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Riscos e Mitigações

- **[Risco] Dispositivos Android sem Google Play Services (ex: ROMs customizadas)**:
  - *Mitigação*: Atestação de Play Integrity requer Play Services. Em dispositivos não compatíveis, a chamada de atestação retornará erro controlado, e o aplicativo informará o usuário de forma amigável.
- **[Risco] Retrocompatibilidade de versões antigas**:
  - *Mitigação*: A Edge Function legada `discord-feedback` permanece intacta no Supabase, atendendo clientes antigos até sua descontinuação natural.

## Plano de Migração

1. **Backend**: Criar a nova Edge Function `app-feedback` em `../aresta_backend/supabase/functions/app-feedback` com validação de JWT, rate limiting e retentativa de webhook, mantendo `discord-feedback` legada.
2. **Frontend**: Adicionar `firebase_app_check`, configurar ativação no `main.dart`, configurar chaves de Remote Config para `feedback_edge_function_url` e `serving_base_url`, refatorar `FeedbackNetworkService` e `FeedbackOrchestrator` apontando para a nova rota seguindo TDD.
3. **CI/CD**: Atualizar `release_new_app_version.yml` e limpar argumentos `--dart-define` dos arquivos de build.
4. **Documentação e Termos**: Atualizar Política de Privacidade e `frontend/lib/README.md`.
