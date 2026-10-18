# Design

## Context

Veja `proposal.md` para a motivação e escopo funcional.

Atualmente no `aresta_app`:
1. Os contratos do banco relacional (`frontend/lib/aresta_api/sql/generated/dart/catalogo_sql.dart`) e da API de sincronização (`frontend/lib/aresta_api/openapi/generated/dart/catalogo.dart`) já estão gerados no submódulo `aresta_api`, e o campo `versaoCatalogo` já está disponível em `Indice` (`indice.pb.dart`).
2. O `SyncService` sincroniza o `indice.binarypb` e verifica atualizações de croquis baixados e thumbnails, mas ainda não gerencia nem sincroniza o `catalogo.db`.
3. A Busca Global (`frontend/lib/widgets/busca_global.dart`) abre arquivos `.binarypb` locais um a um na inicialização do widget, não enxergando escaladas nem setores de croquis ainda não baixados.
4. O `LocalizadorDestinoUid` (`frontend/lib/navigation/localizador_destino_uid.dart`) só consegue resolver UIDs de vias, setores e grupos se o croqui já estiver baixado ou em sessão online ativa, e o `servico_navegacao_deep_link.dart` ainda mantém ~200 linhas de resolução legada por slugs hierárquicos.

## Goals / Non-Goals

**Goals:**
- Gerenciar o `catalogo.db` localmente via `sqflite` (`RepositorioCatalogo`), inferindo a versão local diretamente da tabela `catalogo_meta` (`chave = 'versao_catalogo'`).
- Incluir o `catalogo.db` no preload (`tool/sync_preload.dart` e `ExtratorAssetsPreload`) e sincronizá-lo de forma assíncrona e não-bloqueante no `SyncService` via `GET /sync` (aplicando `batch` transacional para `apply_delta` ou baixando `$baseUrl/catalogo.db` em `full_download`).
- Alimentar a Busca Global (`busca_global.dart`) com uma única query SQLite (`LEFT JOIN` entre `catalogo_aresta` e `catalogo_croquis`), mantendo o algoritmo `Fuzzy` em memória, priorizando croquis salvos offline na ordenação e exibindo a badge **`Offline`**.
- Unificar toda a navegação de Deep Links e Busca Global em torno de UIDs (`LocalizadorDestinoUid` consultando `catalogo.db` para descobrir o `id_slug` e carregar croquis online sob demanda), suportando os prefixos compactos de até 35 caracteres de `aresta.cc` (`/`, `/m/`, `/s/`, `/sm/`, `/ms/`, `/q/`, `/qm/`, `/mq/`), as 8 URLs físicas legadas em tabela estática e a abertura direta no Mapa Interativo (`MapasCarrosselNode`).
- Adicionar botões de compartilhamento nativo (`share_plus`) para Croqui/Pico, Grupo, Setor, Escalada e Mapa Interativo, com telemetria dedicada.

**Non-Goals:**
- Substituir os arquivos Protobuf `compilado.binarypb` de cada croqui pelo SQLite na renderização de mapas ou páginas detalhadas (o `catalogo.db` contém exclusivamente o índice relacional leve de busca e resolução de UIDs).
- Utilizar `Isolate` manual em Dart para o `catalogo.db` (o plugin `sqflite` já executa todas as queries e transações em thread nativa de background do sistema operacional).

## Decisions

### 1. Inferência de Versão Diretamente de `catalogo_meta` e Transação Atômica (`sqflite`)
- **Decisão**: O `RepositorioCatalogo` encapsula a instância do banco SQLite em `$docsPath/downloads/catalogo.db` (ou `$docsPath/experimental/catalogo.db` quando em modo experimental, se aplicável, ou mantendo o catálogo oficial). Para obter a versão local, executa `SELECT valor FROM catalogo_meta WHERE chave = 'versao_catalogo'`. Quando recebe um `RespostaSyncCatalogo` com `acao == 'apply_delta'`, abre `db.transaction((txn) async { final batch = txn.batch(); ... })` e enfileira:
  1. `DELETE FROM catalogo_aresta WHERE uid = ?` para cada item em `deletes.entidades`.
  2. `DELETE FROM catalogo_croquis WHERE croqui_uid = ?` para cada item em `deletes.croquis`.
  3. `INSERT OR REPLACE INTO catalogo_croquis ...` para cada item em `upserts.croquis`.
  4. `INSERT OR REPLACE INTO catalogo_aresta ...` para cada item em `upserts.entidades`.
  5. `INSERT OR REPLACE INTO catalogo_meta (chave, valor) VALUES ('versao_catalogo', ?)` com `versaoAtual`.
  6. `await batch.commit(noResult: true)`.
- **Alternativa considerada**: Salvar `versao_catalogo` em `SharedPreferences` ou arquivo `.etag` separado. Descartada porque criaria risco de dessincronia caso o processo fosse interrompido entre a escrita no SQLite e a gravação no `SharedPreferences`. Mantendo `versao_catalogo` dentro de `catalogo_meta` na mesma transação ACID do SQLite, estado e versão são indivisíveis.
- **Testabilidade (Princípios III, IV e V do `AGENTS.md`)**: Nos testes automatizados (`flutter test`), utilizamos `sqflite_common_ffi` operando sobre bancos SQLite reais em diretórios temporários (`Directory.systemTemp`), sem mocks de banco de dados.

### 2. Sincronização Assíncrona Não-Bloqueante no `SyncService`
- **Decisão**: No `SyncService._executarSyncIndex()`, tanto no ramo `IndiceUpdated` quanto no ramo `IndiceUnchanged` (`304 Not Modified`), disparamos a sincronização do catálogo (`_sincronizarCatalogoSeNecessario(indice.versaoCatalogo, baseUrl)`) de forma concorrente (`Future.wait` / assíncrona não-bloqueante) com `_syncThumbnails` e `_checkForUpdates`.
- **Racional**:
  - Se o `indice.binarypb` retornou `304 Not Modified`, mas na sessão anterior o download do delta do catálogo havia falhado por queda momentânea de rede, checar `versao_local != indice.versaoCatalogo` garante autocorreção imediata.
  - Uma eventual falha na sincronização do `catalogo.db` é registrada via `AppLogger` sem impedir o commit das atualizações de croquis ou do `indice.binarypb` (pois o `catalogo.db` já possui preload local funcional e se autocorrigirá no próximo sync).

### 3. Query Relacional Única no `catalogo.db` + `Fuzzy` com Boost Offline na Busca Global
- **Decisão**: O `RepositorioCatalogo` expõe um método `listarItensParaBuscaGlobal()` que executa:
  1. `SELECT croqui_uid, id_slug, nome, cidade, estado FROM catalogo_croquis ORDER BY nome COLLATE NOCASE ASC`
  2. Uma query com `LEFT JOIN` para todas as entidades pesquisáveis (`grupo`, `setor`, `escalada`):
     ```sql
     SELECT
       e.uid,
       e.tipo,
       e.croqui_uid,
       e.nome,
       e.escalada_grau,
       e.escalada_tipo,
       e.setor_uid,
       e.grupo_uid,
       s.nome AS setor_nome,
       g.nome AS grupo_nome,
       c.id_slug,
       c.nome AS pico_nome,
       c.cidade,
       c.estado
     FROM catalogo_aresta e
     JOIN catalogo_croquis c ON c.croqui_uid = e.croqui_uid
     LEFT JOIN catalogo_aresta s ON s.uid = e.setor_uid
     LEFT JOIN catalogo_aresta g ON g.uid = e.grupo_uid
     WHERE e.tipo IN ('escalada', 'setor', 'grupo')
     ```
- **Ordenação e UI em `busca_global.dart`**:
  - Com ~5.000 registros no acervo nacional, a query SQLite leva < 15ms e a busca aproximada `Fuzzy<GlobalSearchResult>` em memória permanece instantânea.
  - Cada item recebe `isDownloaded = idsPicosBaixados.contains(idSlug)`.
  - Após `fuse.search(queryLower)`, ordenamos os resultados aplicando um fator multiplicador de prioridade no score do `Fuzzy` para itens `isDownloaded == true` (ex: `scoreEfetivo = r.item.isDownloaded ? r.score * 0.5 : r.score`, onde menor score = maior relevância no `package:fuzzy`), garantindo que resultados relevantes já baixados offline apareçam primeiro.
  - No `trailing` de cada item com `isDownloaded == true`, renderizamos uma badge estilizada **`Offline`** (com ícone `Icons.check_circle_outline` e cor `dryMoss`).

### 4. Protocolo Compacto `aresta.cc` (35 chars), Modo Mapa (`/m/`) e Tabela Estática das 8 Placas Legadas
- **Decisão**:
  - `RotaDeepLink` passa a ser representada exclusivamente por:
    - `uid` (`String` não nula — todo deep link válido resolve para um UID)
    - `abrirMapa` (`bool`, padrão `false`)
    - `origemLink` (`String?`: `'qrcode'`, `'compartilhamento'` ou `null`)
    - `parametros` (`Map<String, String>`)
  - No `DeepLinkRouteParser.parse()`:
    1. Para `app.arestaclimb.com` (ou caminhos legados), consulta exclusivamente o mapa constante `mapaPlacasLegadas` contendo as 8 rotas físicas de Pedra Grande de Igarapé. Se coincidir, retorna `RotaDeepLink(uid: uidMapeado, origemLink: 'qrcode', parametros: parametros)`. Qualquer outra rota de slug retorna `null`.
    2. Para `aresta.cc` / `www.aresta.cc`:
       - 1 segmento `/<uid>` com `validarUid(uid)`: retorna `RotaDeepLink(uid: uid, abrirMapa: false, origemLink: _inferirOrigemDeUtm(parametros), parametros: parametros)`.
       - 2 segmentos `/<prefixo>/<uid>` onde `validarUid(uid)` e `prefixo` $\in \{\text{'m'}, \text{'s'}, \text{'sm'}, \text{'ms'}, \text{'q'}, \text{'qm'}, \text{'mq'}\}$:
         - `abrirMapa = prefixo.contains('m')`
         - `origemLink = prefixo.contains('s') ? 'compartilhamento' : (prefixo.contains('q') ? 'qrcode' : _inferirOrigemDeUtm(parametros))`
  - No `LocalizadorDestinoUid.localizar(String uid, {bool abrirMapa = false})`:
    1. Se o croqui que contém `uid` ainda não estiver em `picosBaixados` nem em `croquisEmMemoria`, consulta `repositorioCatalogo.obterIdSlugPorUid(uid)` (que verifica tanto `catalogo_croquis.croqui_uid` quanto `catalogo_aresta.uid JOIN catalogo_croquis`).
    2. Com o `id_slug` encontrado, se o croqui não estiver em memória, carrega-o via `datasetRepo.getCroqui(idSlug)` (se baixado) ou `datasetRepo.servicoCroquiOnline.carregarCroquiRemoto(url, picoId: idSlug)` (se online).
    3. Constrói o nó base (`PicoNode`, `GrupoNode`, `SetorNode` ou `ViaNode`).
    4. Se `abrirMapa == true`, constrói a lista de `CarrosselItemData` a partir dos mapas próprios da entidade (no caso de Pico, Grupo ou Setor com `mapas.isNotEmpty`) ou a partir de `entidade.referencias` do `DatasetResolver` (com `initialSelectedId` focado na referência da via/setor/grupo), retornando `MapasCarrosselNode(..., parent: noBase)`. Se a entidade não possuir nenhum mapa, retorna `noBase` como fallback gracioso.

### 5. Compartilhamento Nativo (`share_plus`) e Arquitetura com o Worker `app-links`
- **Decisão**:
  - Criaremos um serviço modular `ServicoCompartilhamento` (`frontend/lib/services/compartilhamento/servico_compartilhamento.dart`) com injeção de dependência para o executor de share (facilitando testes determinísticos 1:1 sem abrir diálogos nativos do SO nos testes de widget).
  - Formatos de URL gerados:
    - Nas páginas principais (`tela_pico.dart`, `tela_grupo.dart`, `tela_setor.dart`, `tela_via.dart`): `https://aresta.cc/s/<uid>`
    - Na visualização do Mapa Interativo (`mapa_interativo.dart`): `https://aresta.cc/sm/<uid>`
  - No ecossistema (`aresta_api` + `aresta_backend`), o Worker `app-links` servirá o domínio `aresta.cc` (incluindo `/.well-known/assetlinks.json`, `/.well-known/apple-app-site-association`, redirect `GET /` $\rightarrow$ `https://arestaclimb.com` e página HTML SSR consultando o D1 com OpenGraph tags e script do Umami).

## Risks / Trade-offs

- **[Risk] Concorrência de leitura na Busca Global enquanto um batch delta está sendo aplicado no `catalogo.db`** $\rightarrow$ **Mitigation**: O SQLite no `sqflite` serializa transações por conexão nativa de forma transparente; leituras `SELECT` aguardam os poucos milissegundos do `batch.commit()` sem risco de leitura suja. No caso de `full_download`, o download ocorre em `catalogo.db.tmp` e a troca do arquivo fecha e reabre a instância controlada pelo `RepositorioCatalogo`.
- **[Risk] Entidade recém-criada apenas no Modo Editor / Prévia (ainda não publicada no `catalogo.db` oficial)** $\rightarrow$ **Mitigation**: Na Busca Global e no `LocalizadorDestinoUid`, os croquis carregados localmente (`picosBaixados` e `croquisEmMemoria` da sessão/prévia) também são verificados, garantindo que mesmo um croqui inédito em prévia funcione perfeitamente.
