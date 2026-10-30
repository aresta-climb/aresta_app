# Design

## Context

Veja `proposal.md` para a motivação completa. Atualmente:
1. `RepositorioCatalogo.obterIdSlugPorUid(String uid)` faz uma query SQLite em `catalogo_croquis` e `catalogo_aresta`, mas retorna apenas `String?` (`id_slug`), descartando os metadados da linha (`nome`, `tipo`, `escalada_grau`, `setor_nome`, `grupo_nome`, `pico_nome`, `cidade`, `estado`).
2. `LocalizadorDestinoUid.localizar(String uid)` descobre o `idSlug`, invoca `datasetRepo.getCroqui(idSlug)` (que verifica memória RAM → `/downloads` → `/temp_cache` → rede remota CDN) e, se `getCroqui` retorna `null` por falta de conexão, retorna simplesmente `null`.
3. Com isso, `DeepLinkNavigatorService` não consegue diferenciar um UID realmente inexistente de um UID válido cujo croqui apenas não pôde ser baixado por falta de internet, e `GlobalSearch._abrirDestinoPorUid` ignora silenciosamente o toque quando `localizar(uid)` retorna `null`.

## Goals / Non-Goals

**Goals:**
- Recuperar em $O(1)$ do `catalogo.db` (e, como fallback para picos, do `indice.binarypb` em memória) os metadados completos da entidade associada a um `uid` (`ItemCatalogoBusca`).
- Preservar integralmente a hierarquia de 4 etapas de `DatasetRepository.getCroqui` (Memória → `/downloads` → `/temp_cache` → Rede CDN), de modo que qualquer croqui presente em `/temp_cache` abra normalmente mesmo offline.
- Distinguir claramente no resultado do `LocalizadorDestinoUid` entre:
  1. Destino carregado e pronto para navegação (`DestinoUidLocalizado`);
  2. Entidade conhecida no catálogo local cujo croqui não pôde ser aberto por falta de conexão (`ItemCatalogoBusca` preenchido);
  3. UID não encontrado no acervo.
- Exibir um modal *bottom sheet* coeso (`ModalCroquiSemConexao`) com os dados da entidade e do croqui e botão **"Tentar novamente"** (que tenta carregar *in-place* e, em caso de sucesso, fecha o modal e navega diretamente para o destino) tanto em Deep Links (*Cold Start* e *Warm Start*) quanto na Busca Global.

**Non-Goals:**
- Adicionar um segundo botão de download completo do pacote de mídias dentro do `ModalCroquiSemConexao` (pois ao reconectar e tocar em **"Tentar novamente"**, o `.binarypb` leve abre a página da entidade imediatamente, onde o `BannerModoOnline` e o `ModalConfirmacaoSaida` já oferecem o download completo do croqui).
- Alterar o schema do banco SQLite `catalogo.db`.

## Decisions

### 1. Consulta `obterItemPorUid(String uid)` no `RepositorioCatalogo`
- **Decisão**: Adicionar `Future<ItemCatalogoBusca?> obterItemPorUid(String uid)` em `RepositorioCatalogo`.
- **Funcionamento**:
  - Primeiro verifica se o `uid` corresponde a uma entidade em `catalogo_aresta` (`escalada`, `setor`, `grupo` ou `botao`) com `JOIN catalogo_croquis` e `LEFT JOIN` para `setor_nome` e `grupo_nome` (mesma projeção de `ItemCatalogoBusca.deMapa`).
  - Caso não encontre em `catalogo_aresta`, verifica se o `uid` corresponde diretamente a um croqui em `catalogo_croquis` (`WHERE croqui_uid = ? OR id_slug = ? LIMIT 1`), retornando um `ItemCatalogoBusca` com `tipo: 'pico'`, `nome: c.nome`, `picoNome: c.nome`, `idSlug: c.idSlug`, `cidade: c.cidade`, `estado: c.estado`.
- **Racional**: Reaproveita o modelo imutável `ItemCatalogoBusca` já existente em `repositorio_catalogo.dart` sem duplicar classes de transferência de dados.

### 2. Resultado de Diagnóstico no `LocalizadorDestinoUid`
- **Decisão**: Criar a classe `ResultadoBuscaDestinoUid` em `localizador_destino_uid.dart` contendo:
  - `final DestinoUidLocalizado? destino;`
  - `final ItemCatalogoBusca? itemSemConexao;`
  - `bool get encontrado => destino != null;`
  - `bool get bloqueadoSemConexao => destino == null && itemSemConexao != null;`
- O método `Future<ResultadoBuscaDestinoUid> localizarComDiagnostico(String uid, {bool abrirMapa = false})` executa a busca e:
  - Se o croqui está em `/downloads`, em memória, em `/temp_cache` ou baixa da CDN → retorna `ResultadoBuscaDestinoUid(destino: ...)`.
  - Se `idSlug != null`, mas `datasetRepo.getCroqui(idSlug)` retorna `null` → monta o `ItemCatalogoBusca` via `repositorioCatalogo.obterItemPorUid(uid)` (ou fallback a partir dos metadados do índice em memória para aquele `idSlug`) e retorna `ResultadoBuscaDestinoUid(itemSemConexao: item)`.
  - Se `idSlug == null` mesmo após tentativa de sync → retorna `const ResultadoBuscaDestinoUid()`.
- O método existente `Future<DestinoUidLocalizado?> localizar(String uid, {bool abrirMapa = false})` passa a delegar para `(await localizarComDiagnostico(uid, abrirMapa: abrirMapa)).destino`, mantendo 100% de retrocompatibilidade.

### 3. Componente `ModalCroquiSemConexao` (`lib/widgets/bottom_sheets/modal_croqui_sem_conexao.dart`)
- **Decisão**: Criar um `StatefulWidget` modular `ModalCroquiSemConexao` com método estático `ModalCroquiSemConexao.mostrar(...)`.
- **Interface e Comportamento**:
  - Recebe `ItemCatalogoBusca item` e `Future<bool> Function() aoTentarNovamente`.
  - Formata a identificação amigável da entidade:
    - Para `'escalada'`: exibe o nome da via (e graduação, se houver) e subtítulo com o setor/grupo e o croqui (`"Croqui ${item.picoNome}"` + cidade/UF).
    - Para `'setor'` ou `'grupo'`: exibe o nome do setor/grupo e subtítulo com o croqui (`"Croqui ${item.picoNome}"` + cidade/UF).
    - Para `'pico'`: exibe o nome do croqui/pico e sua localização (cidade/UF).
  - Informa de forma clara que o conteúdo faz parte do croqui `${item.picoNome}`, que ainda não está salvo offline no aparelho, e orienta a tentar novamente quando houver conexão com a internet.
  - Quando o usuário toca em **"Tentar novamente"**:
    - Entra em estado `_tentandoConectar = true` (desabilita o botão e exibe `CircularProgressIndicator` compacto ao lado do rótulo `"Tentando abrir..."`).
    - Invoca `await aoTentarNovamente()`.
    - Se retornar `true` (conexão restabelecida e navegação realizada): fecha o `BottomSheet` (`Navigator.of(context).pop(true)`).
    - Se retornar `false` (ainda sem conexão): restaura `_tentandoConectar = false` e exibe um aviso inline discreto dentro do próprio modal (`"Ainda sem conexão com a internet. Verifique sua rede e tente novamente."`), sem fechar o modal.

### 4. Integração no *Cold Start*, *Warm Start* e Busca Global
- **Em `DeepLinkNavigatorService`**:
  - Adiciona callback opcional `void Function(ItemCatalogoBusca item, Future<bool> Function() tentarNovamente)? onCroquiSemConexao`.
  - Quando `localizarComDiagnostico` retorna `bloqueadoSemConexao`:
    - Registra `AppLogger.instance.logAviso('[DeepLinks] Croqui "${item.idSlug}" indisponível offline ao abrir UID "$uid" (${item.nome}).')`.
    - Registra telemetria em `ServicoPerformance.instancia.registrarAberturaDeepLink` com `idCroqui: item.idSlug`, `destino: _normalizarTipoDestino(item.tipo)`, `sucesso: false`, `motivoErro: 'croqui_offline_sem_conexao'`.
    - Se `onCroquiSemConexao != null`, invoca o callback; caso contrário, se `context != null && context.mounted`, chama `ModalCroquiSemConexao.mostrar(...)`.
  - Quando o UID realmente não é encontrado (`!encontrado && !bloqueadoSemConexao`):
    - Registra `AppLogger.instance.logAviso('[DeepLinks] UID "$uid" não encontrado no acervo local nem remoto.')`.
    - Mantém a telemetria `uid_nao_encontrado_no_acervo` e o `SnackBar` de código não encontrado.
- **No *Cold Start* (`inicializacao_app.dart` → `main.dart` → `TreeNavigationWrapper`)**:
  - `ResultadoResolucaoColdStart` passa a transportar opcionalmente `ItemCatalogoBusca? itemSemConexaoInicial` (além de `linkInicialProcessado` e `mensagemAvisoInicial`).
  - No `initState` de `TreeNavigationWrapper`, se `widget.itemSemConexaoInicial != null`, agenda em `addPostFrameCallback` a abertura do `ModalCroquiSemConexao.mostrar`, cujo `aoTentarNovamente` chama `deepLinkNavigator.processarLink(widget.linkInicialProcessado!, context: context, tipoStart: 'warm_start')` silenciosamente caso falhe novamente (para não empilhar outro modal sobre o modal aberto).
- **Na Busca Global (`busca_global.dart`)**:
  - Em `_abrirDestinoPorUid`, usa `localizador.localizarComDiagnostico(uid)`.
  - Se retornar `destino != null`, fecha a busca e navega normalmente.
  - Se retornar `itemSemConexao != null`, exibe `ModalCroquiSemConexao.mostrar` passando um `aoTentarNovamente` que reexecuta `localizador.localizar(uid)` e, ao obter o `destino`, fecha a busca e navega diretamente para `destino.noNavegacao`.

## Risks / Trade-offs

- **[Risco] Reabertura duplicada do modal ao clicar em "Tentar novamente" dentro do próprio modal** → **Mitigação**: Quando o botão `"Tentar novamente"` do `ModalCroquiSemConexao` é acionado, a nova tentativa invoca a resolução com uma flag `exibirModalEmCasoDeFalha: false` (ou chama diretamente `localizador.localizar(uid)`), garantindo que se a rede ainda estiver indisponível o modal atual apenas exiba o feedback inline sem abrir um segundo `BottomSheet` por cima.
