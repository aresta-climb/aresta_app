# qr-deep-linking Specification Delta

## MODIFIED Requirements

### Requirement: Interceptação e Normalização de Deep Links
O sistema DEVE (MUST) interceptar e normalizar URLs recebidas do domínio canônico `aresta.cc` (e as 8 URLs de placas físicas legadas em `app.arestaclimb.com`) tanto na inicialização a frio (*Cold Start*) quanto com o aplicativo já em execução em segundo plano (*Warm Start*), configurando a atividade principal com `android:launchMode="singleTask"` para garantir instância única (roteando intents `ACTION_VIEW` via `onNewIntent` sem instanciar uma segunda atividade com tema de splash branco) e blindando o `MaterialApp` raiz (`didPushRouteInformation` e `onGenerateInitialRoutes`) para que notificações de rota do canal nativo do Flutter nunca disparem `FlutterError` em `_onUnknownRoute`.

#### Scenario: Abertura a frio a partir de um deep link externo
- **WHEN** o usuário toca em um link `https://aresta.cc/s/hv7YWgTBQGyWOX` com o aplicativo totalmente fechado
- **THEN** o aplicativo inicializa a rota raiz `'/'` sem erros no `MaterialApp` e despacha a rota por UID via `GerenciadorDeepLinks` preservando a origem de compartilhamento e eventuais parâmetros UTM.

#### Scenario: Abertura em segundo plano a partir de link externo
- **WHEN** o usuário clica em um link do domínio `aresta.cc` enquanto o aplicativo já está rodando em segundo plano (mesmo que outra atividade auxiliar estivesse no topo da pilha)
- **THEN** o sistema operacional reutiliza a instância existente da `MainActivity` via `onNewIntent` sem exibir splash screen branca, o `MyApp` intercepta eventuais notificações de rota do canal nativo sem acionar `_onUnknownRoute`, e o aplicativo transiciona diretamente para o recurso identificado pelo UID.

### Requirement: Telemetria de Abertura via Deep Link e QR Code
O sistema DEVE (MUST) registrar um evento estruturado de telemetria (`deep_link_aberto`) e uma trace de performance (`cold_start_deep_link` ou `warm_start_deep_link`) sempre que um deep link for interceptado e processado pelo aplicativo, identificando o tipo de inicialização (Cold Start vs Warm Start), o destino alcançado (`pico`, `grupo`, `setor`, `via`), se abriu direto no mapa (`abrir_mapa`), a camada de resolução de dados (`modo_acesso`: `memoria`, `offline`, `temp_cache` ou `cdn_online`), o tempo total até a página estar renderizada e interativa (`duracao_ms`), a origem do link (`qrcode`, `compartilhamento` ou parâmetros UTM) e o resultado do carregamento (`sucesso: true/false`).

#### Scenario: Registro bem-sucedido de abertura de via via QR code físico
- **WHEN** o usuário escaneia um QR code físico (`https://aresta.cc/qm/<uid>` ou `https://aresta.cc/q/<uid>`) na rocha que abre uma via com o aplicativo previamente fechado (Cold Start)
- **THEN** após o primeiro frame da tela de destino ser renderizado, o sistema despacha a trace `cold_start_deep_link` e o evento `deep_link_aberto` contendo `tipo_start: cold_start`, `destino: via`, `sucesso: true`, `modo_acesso`, `duracao_ms`, `origem_link: qrcode` e eventuais parâmetros `utm_source` e `utm_medium`.

#### Scenario: Registro de falha no carregamento de deep link sem internet
- **WHEN** um link externo é acionado para um pico não baixado previamente e o dispositivo está sem conexão com a internet
- **THEN** o sistema despacha evento de telemetria registrando `sucesso: false`, `duracao_ms` e o motivo do erro antes de notificar o usuário na interface.
