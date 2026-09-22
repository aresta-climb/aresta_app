# Design Técnico: Telemetria para Deep Links, QR Codes e Interações de Interface

## Context

O Aresta Climb utiliza o Firebase Analytics via classe singleton [`TelemetryService`](file:///c:/Renato/Devel/aresta-climb/aresta_app/frontend/lib/services/firebase/telemetry_service.dart) para coletar métricas anonimizadas de uso. A inicialização de links profundos é gerenciada pelo pacote `app_links` em [`GerenciadorDeepLinks`](file:///c:/Renato/Devel/aresta-climb/aresta_app/frontend/lib/navigation/gerenciador_deep_links.dart), que recebe eventos nativos do SO (*Cold Start* e *Warm Start*) e delega a resolução para [`DeepLinkNavigatorService`](file:///c:/Renato/Devel/aresta-climb/aresta_app/frontend/lib/navigation/deep_link_navigator_service.dart).

Veja a motivação detalhada em `proposal.md` e os requisitos funcionais em `specs/qr-deep-linking/spec.md` e `specs/telemetria-interacoes-usuario/spec.md`.

## Goals / Non-Goals

**Goals:**
- Estender [`RotaDeepLink`](file:///c:/Renato/Devel/aresta-climb/aresta_app/frontend/lib/navigation/deep_link_route_parser.dart) para capturar e expor `queryParameters` (incluindo `utm_source`, `utm_medium`, `utm_campaign`, etc.).
- Instrumentar [`DeepLinkNavigatorService`](file:///c:/Renato/Devel/aresta-climb/aresta_app/frontend/lib/navigation/deep_link_navigator_service.dart) para registrar o evento `deep_link_aberto` no `TelemetryService` tanto em execuções com sucesso quanto em falhas de resolução/conectividade.
- Criar métodos semânticos no [`TelemetryService`](file:///c:/Renato/Devel/aresta-climb/aresta_app/frontend/lib/services/firebase/telemetry_service.dart) para as interações de UI que estão desprovidas de métricas.
- Instrumentar as telas e widgets chave: modal de Beta Aberto, botões de apoio PIX, Guardião de Saída, Banner Modo Online, botões comunitários/sociais e ordenação de listas.
- Garantir 100% de cobertura de testes unitários e de widget seguindo estritamente TDD e o `AGENTS.md`.

**Non-Goals:**
- Criar serviço intermediário de redirecionamento HTTP ou encurtamento de URL próprio (o app lida diretamente com os links oficiais `app.arestaclimb.com`).
- Alterar a lógica de parsing ou resolução hierárquica de slugs já estabelecida.
- Adicionar telemetria a micro-interações de renderização que não representam intenção do usuário (ex: animação de scroll interno).

## Decisions

### Decisão 1: Armazenamento de Parâmetros de Consulta em `RotaDeepLink`
- **Abordagem**: Adicionar o campo imutável `final Map<String, String> parametros;` em `RotaDeepLink`. O `DeepLinkRouteParser.parse` preencherá esse mapa extraindo `uri.queryParameters`.
- **Rationale**: Simples, direto e desacoplado. Permite que qualquer parâmetro UTM ou de contexto extraído da URL seja acessado pelo serviço de navegação e telemetria sem criar classes DTO intermediárias complexas (Princípio VI: Simplicidade e Anti-Abstração).
- **Alternativas consideradas**: Criar uma classe dedicada `UtmParameters`. Rejeitada por adicionar abstração prematura para um mapa simples de strings.

### Decisão 2: Despacho do Evento de Deep Link no `DeepLinkNavigatorService`
- **Abordagem**: O disparo do evento `logDeepLinkAberto` ocorre dentro de `DeepLinkNavigatorService.processarLink`, onde o contexto completo do carregamento está disponível:
  - `picoId`, `destino` (`pico`, `grupo`, `setor`, `via`), `origem` (ex: `cold_start` ou `warm_start`).
  - Parâmetros UTM (`utm_source`, `utm_medium`, `utm_campaign`).
  - Status de sucesso (`sucesso: true`) ou motivo de falha (`sucesso: false`, `motivo_erro: 'pico_nao_encontrado'` ou `'sem_conexao'`).
- **Rationale**: É o único local da arquitetura que sabe se o croqui pôde ser carregado (offline no cache ou sob demanda online) ou se houve falha de rede/ausência do pico.

### Decisão 3: Métodos Semânticos no `TelemetryService`
- **Abordagem**: Adicionar métodos explícitos na classe `TelemetryService`:
  - `logDeepLinkAberto(...)`
  - `logAcaoBetaAberto(String acao, {String? canal})` (ações: `abrir_modal`, `clique_canal`)
  - `logApoioPix(String idCroqui)`
  - `logAcaoGuardiaoSaida(String idCroqui, String acao)` (ações: `exibir_modal`, `salvar_offline`, `sair_sem_salvar`)
  - `logSalvarOfflineBanner(String idCroqui)`
  - `logNavegacaoPicoHub(String idCroqui, String secao)` (seções: `setores`, `explorar_local`, `regras`, `comunidade`, `creditos`)
  - `logAlterarOrdenacao(String contexto, String modo)`
- **Rationale**: Preserva o padrão do projeto com nomes em português brasileiro, parâmetros tipados e autocomplete limpo, facilitando asserções nos mocks de teste.

## Risks / Trade-offs

- **[Risco: Caracteres especiais ou URLs malformadas]** → *Mitigação*: `Uri.tryParse` já trata formatos inválidos retornando `null`. `uri.queryParameters` decodifica percent-encoding com segurança.
- **[Risco: Disparo duplo em Cold Start]** → *Mitigação*: O `GerenciadorDeepLinks` trata Cold Start no início da inicialização e Warm Start via stream, garantindo que o link inicial seja processado uma única vez.
- **[Risco: Regressão de testes existentes]** → *Mitigação*: `RotaDeepLink.parametros` terá valor padrão `const {}` no construtor para preservar total retrocompatibilidade com os testes existentes de rotas.
