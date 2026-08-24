## Por que

Atualmente, o envio de feedback dos usuários no aplicativo mobile despacha dados para uma Edge Function do Supabase legada (`discord-feedback`) utilizando uma chave estática de API injetada em tempo de compilação via `--dart-define`. Como binários mobile (.apk/.aab) podem ser inspecionados por engenharia reversa e o tráfego interceptado, a chave de API estática e a URL tornam-se públicas, permitindo que atacantes desenvolvam scripts automatizados para sobrecarregar e enviar spam ao webhook.

Além disso, tanto a URL do endpoint de feedback quanto a URL base do servidor de dados de escalada (`serving.arestaclimb.com`) precisam de flexibilidade para serem alteradas remotamente em casos de emergência (ex: migração de CDN ou manutenção de infraestrutura), mantendo a resiliência offline através de constantes compiladas locais.

Para resolver isso, criaremos uma nova Edge Function segura (`app-feedback`), preservando a função legada (`discord-feedback`) para compatibilidade, com Atestação de Aplicativo via Firebase App Check, limitador de taxa por IP, suporte a Firebase Remote Config para URLs dinâmicas e automação de atualização de termos legais a cada release.

## O que muda

- **Novo Endpoint no Backend (`app-feedback`)**: Criação da nova Edge Function `app-feedback` no Supabase (`../aresta_backend/supabase/functions/app-feedback`) com validação de JWT do Firebase App Check, desacoplando o nome da rota do destino final (Discord) e mantendo a rota legada `discord-feedback` ativa para versões anteriores do app.
- **Integração do Firebase App Check**: Configuração do `firebase_app_check` no frontend Flutter utilizando Play Integrity (Release no Android), DeviceCheck/App Attest (Release no iOS) e Provedor de Debug durante o desenvolvimento.
- **Aposentadoria de Chave Estática de API e Eliminação de .env**: Remoção de `FEEDBACK_EDGE_FUNCTION_API_KEY`, limpeza de segredos passados via `--dart-define` nos workflows do GitHub Actions CI/CD e definição direta da URL padrão do `app-feedback` como constante no frontend.
- **Resolução Dinâmica de URLs via Firebase Remote Config**: Suporte para substituição dinâmica da URL do `app-feedback` e da URL base do servidor de dados (`serving_base_url`) via Firebase Remote Config, mantendo constantes locais compiladas como fallback seguro para operação offline.
- **Experiência de Desenvolvimento Local e Código Aberto (DX)**: Suporte para desenvolvedores da comunidade executarem o aplicativo sem atrito; caso o token de depuração não esteja cadastrado no console do Firebase, o envio de feedback realiza um mock gracioso exibindo os dados no console de depuração sem quebrar a execução.
- **Limitação de Taxa no Servidor (Rate Limiting)**: Aplicação de limite de 5 envios por minuto por endereço IP na Edge Function `app-feedback`.
- **Resiliência do Webhook de Destino**: Implementação de tratamento automático de respostas `HTTP 429` (Rate Limit) do Discord na Edge Function, respeitando o cabeçalho `Retry-After`.
- **Automação de Termos Legais no Release**: Atualização do workflow `release_new_app_version.yml` para sincronizar o submódulo legal (`frontend/legal/repo` / `arestaclimb.com`) e recalcular a versão dos termos automaticamente a cada release.
- **Conformidade Estrita com PRINCIPIOS.md**: Desenvolvimento 100% orientado a testes (TDD), 100% de cobertura de testes, código e documentação em português brasileiro com docstrings explicativas.

## Capacidades

### Novas Capacidades
- `discord-feedback-security`: Cobre a atestação de integridade do aplicativo (Firebase App Check), prevenção de abusos anônimos, rate limiting por IP, entrega resiliente de feedback através do novo endpoint `app-feedback` e resolução dinâmica de URLs via Firebase Remote Config com resiliência offline.

### Capacidades Modificadas
<!-- Nenhuma capacidade existente teve seus requisitos funcionais alterados -->

## Impacto

- **Frontend (`frontend/`)**:
  - `pubspec.yaml`: Inclusão da dependência `firebase_app_check`.
  - `lib/constants/network_constants.dart`: Suporte a `serving_base_url` dinâmica via Firebase Remote Config com fallback em `kDefaultBaseUrl`.
  - `lib/services/feedback/feedback_network_service.dart`: Envio do cabeçalho `X-Firebase-AppCheck` para o novo endpoint `app-feedback` e remoção de `x-api-key`.
  - `lib/application_managers/feedback/feedback_orchestrator.dart`: Resolução da URL via Remote Config com constante padrão apontando para `app-feedback` e mock gracioso em desenvolvimento.
  - `lib/main.dart`: Inicialização e ativação centralizada do Firebase App Check e defaults do Remote Config.
  - `test/`: Criação de testes unitários e de integração ausentes (`feedback_network_service_test.dart`, `network_constants_test.dart`) garantindo 100% de cobertura e seguindo TDD.
- **Workflows de CI/CD (`.github/workflows/`)**:
  - `build_android.yml` e `build_ios.yml`: Remoção das flags `--dart-define` associadas às chaves de feedback.
  - `release_new_app_version.yml`: Integração da sincronização automática dos termos legais.
- **Backend Supabase (`../aresta_backend/supabase/`)**:
  - Criação da nova Edge Function `functions/app-feedback/` com validação de JWT do App Check, rate limiting por IP (5 req/min) e retentativa em 429 do Discord, mantendo a função legada `discord-feedback` inalterada.
