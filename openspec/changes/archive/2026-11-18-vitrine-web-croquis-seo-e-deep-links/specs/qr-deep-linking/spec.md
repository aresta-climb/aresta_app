# Spec Delta

## MODIFIED Requirements

### Requirement: Interceptação e Normalização de Deep Links
O sistema DEVE (MUST) interceptar e normalizar URLs recebidas dos domínios `aresta.cc`, `arestaclimb.com/croquis/<uid>[/<slug>]` (incluindo `www.arestaclimb.com`) e as 8 URLs de placas físicas legadas em `app.arestaclimb.com` tanto na inicialização a frio (*Cold Start*) quanto com o aplicativo já em execução em segundo plano (*Warm Start*), configurando a atividade principal com `android:launchMode="singleTask"` para garantir instância única (roteando intents `ACTION_VIEW` via `onNewIntent` sem instanciar uma segunda atividade com tema de splash branco) e blindando o `MaterialApp` raiz (`didPushRouteInformation` e `onGenerateInitialRoutes`) para que notificações de rota do canal nativo do Flutter nunca disparem `FlutterError` em `_onUnknownRoute`.

#### Scenario: Abertura a frio a partir de um deep link externo
- **WHEN** o usuário toca em um link `https://aresta.cc/s/hv7YWgTBQGyWOX` ou `https://arestaclimb.com/croquis/hv7YWgTBQGyWOX/mg-igarape-pedra-grande?utm_source=google` com o aplicativo totalmente fechado
- **THEN** o aplicativo inicializa a rota raiz `'/'` sem erros no `MaterialApp` e despacha a rota por UID via `GerenciadorDeepLinks` preservando a origem e eventuais parâmetros UTM.

#### Scenario: Abertura em segundo plano a partir de link externo
- **WHEN** o usuário clica em um link válido de `aresta.cc` ou `arestaclimb.com/croquis/<uid>/...` enquanto o aplicativo já está rodando em segundo plano (mesmo que outra atividade auxiliar estivesse no topo da pilha)
- **THEN** o sistema operacional reutiliza a instância existente da `MainActivity` via `onNewIntent` sem exibir splash screen branca, o `MyApp` intercepta eventuais notificações de rota do canal nativo sem acionar `_onUnknownRoute`, e o aplicativo transiciona diretamente para o recurso identificado pelo UID.

## ADDED Requirements

### Requirement: Suporte às Rotas Canônicas da Vitrine Web (`arestaclimb.com/croquis/<uid>[/<slug>]`) e CGI Args
O `DeepLinkRouteParser` e os manifestos de plataforma (`AndroidManifest.xml` com `android:pathPrefix="/croquis/"` e `Runner.entitlements` com `applinks:arestaclimb.com`) DEVEM (MUST) reconhecer URLs `https://arestaclimb.com/croquis/<uid>` e `https://arestaclimb.com/croquis/<uid>/<slug>` (bem como o esquema customizado `aresta://arestaclimb.com/croquis/<uid>[/<slug>]`), extraindo o `<uid>` de 14 caracteres logo após `/croquis/`, ativando `abrirMapa: true` quando `mapa=1` ou `mapa=true` estiver nos parâmetros de consulta, inferindo `origemLink` a partir de `utm_source`/`utm_medium` quando aplicável e preservando integralmente todos os query parameters (CGI args). Rotas institucionais fora de `/croquis/<uid>` (como `/`, `/croquis`, `/editor` ou `/termos-de-uso`) DEVEM retornar `null` no parser.

#### Scenario: Abertura de resultado do Google ou link da vitrine com slug e CGI args
- **WHEN** o aplicativo recebe `https://arestaclimb.com/croquis/x8siJek3FiG3aB/mg-pedra-rachada-feijao-com-linguica?mapa=1&utm_source=compartilhamento&utm_medium=social&campanha=inverno`
- **THEN** o `DeepLinkRouteParser` retorna `RotaDeepLink` com `uid: "x8siJek3FiG3aB"`, `abrirMapa: true`, `origemLink: "compartilhamento"` e todos os quatro parâmetros preservados em `parametros`.

#### Scenario: Rejeição da página índice `/croquis` ou rotas institucionais de `arestaclimb.com`
- **WHEN** o `DeepLinkRouteParser` avalia `https://arestaclimb.com/croquis`, `https://arestaclimb.com/croquis/busca.json` ou `https://arestaclimb.com/editor`
- **THEN** o parser retorna `null` por não conter um UID válido de 14 caracteres Base62 no segundo segmento do caminho.
