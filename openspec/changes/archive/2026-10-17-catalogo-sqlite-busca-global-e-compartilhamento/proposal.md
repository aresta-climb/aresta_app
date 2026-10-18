# Proposal

## Why

Atualmente, a Busca Global do aplicativo só consegue pesquisar setores, grupos e escaladas de croquis que o usuário já baixou manualmente ou abriu na sessão online, deixando o restante do acervo nacional invisível para buscas por vias ou setores. Além disso, a resolução de Deep Links por UID (`aresta.cc/<uid>`) falha quando o croqui hospedeiro ainda não está baixado no aparelho (pois o app desconhece a qual `id_slug` aquele UID pertence), o código de deep links ainda carrega uma resolução legada complexa por slugs hierárquicos, e os usuários não possuem botões nativos para compartilhar croquis, grupos, setores ou escaladas com links curtos otimizados para QR Codes físicos (Version 3-H de até 35 caracteres) e abertura direta na página ou no mapa interativo.

## What Changes

- **Catálogo SQLite Local (`catalogo.db`) com Preload e Sincronização Incremental (`sqflite`)**:
  - Inclusão do `catalogo.db` no script de empacotamento `tool/sync_preload.dart` e no `ExtratorAssetsPreload`, fazendo o aplicativo nascer 100% pesquisável offline já na primeira abertura sem internet.
  - Criação do repositório `RepositorioCatalogo` utilizando `sqflite` (`sqflite_common_ffi` em testes desktop) consumindo os contratos gerados em `aresta_api` (`catalogo_sql.dart` e `openapi/generated/dart/catalogo.dart`).
  - Inferência da versão local diretamente da tabela `catalogo_meta` (`chave = 'versao_catalogo'`) do próprio `catalogo.db`, sem arquivos de estado paralelos.
  - Sincronização assíncrona e não-bloqueante no `SyncService`: após atualizar ou validar o `indice.binarypb` (inclusive em `304 Not Modified`), compara a `versao_catalogo` local com `indice.versaoCatalogo` e, se divergirem, consulta `https://catalogo.arestaclimb.com/sync`, aplicando `deletes`, `upserts` e a nova `versao_catalogo` em um único `batch` transacional SQLite (ou realizando `full_download` de `$baseUrl/catalogo.db` como fallback).
- **Busca Global Completa via `catalogo.db` com `Fuzzy`, Prioridade Offline e Badge**:
  - Refatoração de `busca_global.dart` para carregar instantaneamente todas as entidades (`escalada`, `setor`, `grupo`) e croquis (`catalogo_croquis`) a partir do `catalogo.db` via `LEFT JOIN`, eliminando a leitura sequencial de múltiplos arquivos Protobuf do disco.
  - Manutenção da busca aproximada (`package:fuzzy`) em memória sobre o conjunto completo do catálogo (~5.000 registros), ordenando os resultados para priorizar entidades pertencentes a croquis já baixados offline (`isDownloaded == true`) e exibindo uma badge visual explícita **`Offline`** nos itens salvos no dispositivo.
- **Resolução Universal de UIDs, Prefixos Semânticos `aresta.cc` (35 chars) e Aposentadoria de Slugs Legados**:
  - **BREAKING (Interno)**: Remoção da lógica legada de resolução dinâmica de deep links por slugs hierárquicos (`_processarRotaHierarquica`), substituindo-a por um mapeamento estático imutável exclusivo para as 8 URLs de placas físicas reais já instaladas em `app.arestaclimb.com/br_mg_igarape_pedra_grande/...` para seus respectivos UIDs.
  - Suporte completo no `DeepLinkRouteParser`, `LocalizadorDestinoUid` e `DeepLinkNavigatorService` aos prefixos compactos de `https://aresta.cc` projetados para caber em QR Codes Version 3-H ($\le 35$ caracteres):
    - `https://aresta.cc/<uid>` (padrão, abre página principal)
    - `https://aresta.cc/m/<uid>` (abre direto no Mapa Interativo da entidade, com fallback para a página principal se não houver mapa)
    - `https://aresta.cc/s/<uid>` (origem `'compartilhamento'`, abre página principal)
    - `https://aresta.cc/sm/<uid>` e `https://aresta.cc/ms/<uid>` (origem `'compartilhamento'`, abre direto no Mapa Interativo)
    - `https://aresta.cc/q/<uid>` (origem `'qrcode'`, abre página principal)
    - `https://aresta.cc/qm/<uid>` e `https://aresta.cc/mq/<uid>` (origem `'qrcode'`, abre direto no Mapa Interativo)
  - Preservação do suporte complementar a `?utm_source=` e `?utm_medium=` na telemetria de abertura (`deep_link_aberto`).
  - Integração do `LocalizadorDestinoUid` com o `RepositorioCatalogo` (`catalogo.db`) para descobrir em $O(1)$ a qual `id_slug` pertence qualquer `uid` de via, setor, grupo ou croqui e carregá-lo sob demanda (offline ou via sessão online) antes de navegar.
- **Botões de Compartilhamento Nativo (`share_plus`) para Croquis, Grupos, Setores e Escaladas**:
  - Adição de botões de compartilhamento nas telas de Pico/Croqui (`tela_pico.dart`), Grupo (`tela_grupo.dart`), Setor (`tela_setor.dart`), Escalada (`tela_via.dart`) e no Mapa Interativo, acionando o menu nativo do sistema operacional com texto descritivo amigável + link curto `https://aresta.cc/s/<uid>` (ou `https://aresta.cc/sm/<uid>` quando compartilhado a partir do mapa) e registrando telemetria da ação.

## Capabilities

### New Capabilities
- `catalogo-sqlite-sync`: Gerenciamento local do banco `catalogo.db` via `sqflite`, leitura de versão em `catalogo_meta` e sincronização incremental não-bloqueante via `/sync` (Delta Squash) ou download completo.
- `busca-global-catalogo`: Busca global unificada alimentada pelo `catalogo.db` com pesquisa aproximada (`Fuzzy`), priorização de croquis salvos offline na ordenação, badge visual `Offline` e navegação direta por UID.
- `compartilhamento-entidades`: Compartilhamento nativo de croquis, grupos, setores, escaladas e mapas gerando links canônicos `https://aresta.cc/s/<uid>` e `https://aresta.cc/sm/<uid>` com telemetria.

### Modified Capabilities
- `qr-deep-linking`: Suporte aos prefixos compactos de `aresta.cc` (`/m/`, `/s/`, `/sm/`, `/ms/`, `/q/`, `/qm/`, `/mq/`), abertura direta no Mapa Interativo, resolução de UIDs não baixados via `catalogo.db`, tabela fixa das 8 placas físicas legadas e remoção da resolução dinâmica por slugs.
- `offline-first-initialization`: Empacotamento e extração do `catalogo.db` junto aos assets de preload (`tool/sync_preload.dart` e `ExtratorAssetsPreload`).

## Impact

- **Dependências (`frontend/pubspec.yaml`)**: Adição de `sqflite`, `sqflite_common_ffi` (em `dev_dependencies` para execução determinística de testes em memória/arquivos temporários sem mocks) e `share_plus`.
- **Serviços e Dados**: `SyncService`, `SyncNetwork`, `SyncStorage`, `DatasetRepository`, `ExtratorAssetsPreload`, `tool/sync_preload.dart`, e novo módulo `frontend/lib/services/catalogo/` (`RepositorioCatalogo`, `SincronizadorCatalogo`).
- **Navegação e Deep Links**: `DeepLinkRouteParser`, `LocalizadorDestinoUid`, `DeepLinkNavigatorService` e `TelemetryService`.
- **Interface (UI)**: `busca_global.dart`, `tela_pico.dart`, `tela_grupo.dart`, `tela_setor.dart`, `tela_via.dart` e `mapa_interativo.dart`.
- **Backend / Contratos Relacionados**: Integra-se nativamente com `catalogo.arestaclimb.com/sync` já publicado e prepara o contrato de URLs para o Worker `app-links` (`aresta.cc`) documentado em `aresta_api`.
