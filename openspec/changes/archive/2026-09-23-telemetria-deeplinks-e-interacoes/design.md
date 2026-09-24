# Design Técnico: Telemetria para Deep Links, QR Codes, Índice de Escaladas e Interações de Interface

## Context

O Aresta Climb utiliza o Firebase Analytics via classe singleton [`TelemetryService`](file:///c:/Renato/Devel/aresta-climb/aresta_app/frontend/lib/services/firebase/telemetry_service.dart) para coletar métricas de uso anônimas. O projeto conta atualmente com 10 dimensões personalizadas registradas no GA4 (`acao`, `id_croqui`, `origem`, `nome_setor`, `nome_grupo`, `nome_escalada`, `modo_acesso`, `primeira_visita`, `versao`, `timestamp_atualizacao`).

Veja a motivação detalhada em `proposal.md` e os requisitos funcionais em `specs/qr-deep-linking/spec.md` e `specs/telemetria-interacoes-usuario/spec.md`.

## Goals / Non-Goals

**Goals:**
- Estender [`RotaDeepLink`](file:///c:/Renato/Devel/aresta-climb/aresta_app/frontend/lib/navigation/deep_link_route_parser.dart) para capturar e expor `queryParameters` (incluindo `utm_source`, `utm_medium`, `utm_campaign`, etc.).
- Instrumentar [`DeepLinkNavigatorService`](file:///c:/Renato/Devel/aresta-climb/aresta_app/frontend/lib/navigation/deep_link_navigator_service.dart) para registrar o evento `deep_link_aberto` no `TelemetryService` tanto em execuções com sucesso quanto em falhas de resolução/conectividade.
- Instrumentar o **Índice de Escaladas** ([`IndiceEscaladasPage`](file:///c:/Renato/Devel/aresta-climb/aresta_app/frontend/lib/pages/indice_escaladas_page.dart), [`PainelFiltrosIndice`](file:///c:/Renato/Devel/aresta-climb/aresta_app/frontend/lib/widgets/painel_filtros_indice.dart) e [`CardIndiceEscalada`](file:///c:/Renato/Devel/aresta-climb/aresta_app/frontend/lib/widgets/card_indice_escalada.dart)), padronizando as ações de filtragem (`filtrar_grau`, `filtrar_setor`, `filtrar_conquistador`, `filtrar_classicas`, `limpar_filtros`) com `origem: 'indice_<modalidade>'`.
- Adicionar no GA4 apenas **1 única dimensão genérica complementar**: `detalhe`, que recebe valores livres (faixas de grau, nome de conquistadores, URLs de links externos).
- Instrumentar as telas e widgets chave: modal de Beta Aberto, botões de apoio PIX, Guardião de Saída, Banner Modo Online, botões comunitários/sociais e ordenação de listas.
- Garantir 100% de cobertura de testes unitários e de widget seguindo estritamente TDD e o `AGENTS.md`.

**Non-Goals:**
- Criar novas dimensões específicas para cada tipo de filtro no Firebase Console (reusa-se a dimensão genérica `detalhe`).
- Criar serviço intermediário de redirecionamento HTTP ou encurtamento de URL próprio (o app lida diretamente com os links oficiais `app.arestaclimb.com`).
- Alterar a lógica de parsing ou resolução hierárquica de slugs já estabelecida.

## Decisions

### Decisão 1: Reuso Máximo de Dimensões e Adição da Dimensão Genérica `detalhe`
- **Abordagem**:
  - Reusar `acao`, `origem`, `id_croqui`, `nome_setor`, `nome_escalada`, `modo_acesso` para todas as interações do app.
  - Para valores dinâmicos complementares que não possuem dimensão própria (como limites de grau `'5º a 8ºb'`, nome de conquistador `'André Braga'`, valor booleano `'true'`, ou URL de link externo), enviar o parâmetro `detalhe`.
- **Configuração no Console**: O usuário só precisa criar 1 dimensão personalizada no Firebase Console:
  - Nome: `Detalhe`
  - Parâmetro: `detalhe`
  - Escopo: `Evento`

### Decisão 2: Padronização Semântica das Ações e Origens do Índice
- **Abordagem**:
  - `origem`: Representa a modalidade de escalada em que a interação ocorreu: `indice_esportiva`, `indice_boulder`, `indice_movel`, `indice_multienfiada`, `indice_highline`.
  - `acao`:
    - `filtrar_grau`: Ajuste da faixa de dificuldade (com limites em `detalhe`, ex: `'5º a 8ºb'`).
    - `filtrar_setor`: Seleção/remoção de setor (com nome do setor em `detalhe` e `nome_setor`).
    - `filtrar_conquistador`: Seleção/remoção de conquistador (com nome em `detalhe`).
    - `filtrar_classicas`: Ativação de clássicas (com `'true'` ou `'false'` em `detalhe`).
    - `limpar_filtros`: Redefinição dos filtros da modalidade ativa.
    - `expandir_filtros` / `colapsar_filtros`: Abertura e fechamento do painel retrátil.
    - `trocar_aba`: Alternância de abas de modalidade (com nome da nova modalidade em `detalhe`).
  - Toque no card de escalada: chama `logAcaoEscalada` com `origem: 'indice_<modalidade>'`, garantindo alinhamento perfeito com `lista_setor`, `mapa` e `busca_global`.

### Decisão 3: Armazenamento de Parâmetros de Consulta em `RotaDeepLink`
- **Abordagem**: Adicionar o campo imutável `final Map<String, String> parametros;` em `RotaDeepLink`. O `DeepLinkRouteParser.parse` preencherá esse mapa extraindo `uri.queryParameters`.
- **Rationale**: Simples, direto e desacoplado. Permite que qualquer parâmetro UTM ou de contexto extraído da URL seja acessado pelo serviço de navegação e telemetria sem criar classes DTO intermediárias complexas (Princípio VI: Simplicidade e Anti-Abstração).

### Decisão 4: Despacho do Evento de Deep Link no `DeepLinkNavigatorService`
- **Abordagem**: O disparo do evento `logDeepLinkAberto` ocorre dentro de `DeepLinkNavigatorService.processarLink`, onde o contexto completo do carregamento está disponível:
  - `picoId`, `destino` (`pico`, `grupo`, `setor`, `via`), `origem` (ex: `cold_start` ou `warm_start`).
  - Parâmetros UTM (`utm_source`, `utm_medium`, `utm_campaign`).
  - Status de sucesso (`sucesso: true`) ou motivo de falha (`sucesso: false`, `motivo_erro: 'pico_nao_encontrado'` ou `'sem_conexao'`).

### Decisão 5: Métodos do `TelemetryService`
- **Assinaturas**:
  ```dart
  Future<void> logDeepLinkAberto({
    required String idCroqui,
    required String destino,
    required bool sucesso,
    String? tipoStart,
    String? motivoErro,
    Map<String, String>? parametrosUtm,
  });

  Future<void> logAcaoIndiceEscaladas(
    String idCroqui,
    String acao, {
    required String modalidade,
    String? detalhe,
  });

  Future<void> logAcaoBetaAberto(String acao, {String? canal});

  Future<void> logApoioPix(String idCroqui);

  Future<void> logAcaoGuardiaoSaida(String idCroqui, String acao);

  Future<void> logSalvarOfflineBanner(String idCroqui);

  Future<void> logNavegacaoPicoHub(String idCroqui, String secao);

  Future<void> logAlterarOrdenacao(String contexto, String modo);
  ```

## Risks / Trade-offs

- **[Risco: Caracteres especiais ou URLs malformadas]** → *Mitigação*: `Uri.tryParse` já trata formatos inválidos retornando `null`. `uri.queryParameters` decodifica percent-encoding com segurança.
- **[Risco: Disparo duplo em Cold Start]** → *Mitigação*: O `GerenciadorDeepLinks` trata Cold Start no início da inicialização e Warm Start via stream, garantindo que o link inicial seja processado uma única vez.
- **[Risco: Regressão de testes existentes]** → *Mitigação*: `RotaDeepLink.parametros` terá valor padrão `const {}` no construtor para preservar total retrocompatibilidade com os testes existentes de rotas.
