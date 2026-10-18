# Spec Delta

## ADDED Requirements

### Requirement: Isolamento e Sincronização Direta do `catalogo.db` no Modo Experimental
Quando o aplicativo estiver operando no Modo Experimental (`EditorDeCroqui.isExperimentalMode.value == true`), o `RepositorioCatalogo` DEVE (MUST) utilizar o arquivo isolado `<docs>/editor/experimental/catalogo.db` e o `SyncService` DEVE (MUST) sincronizá-lo baixando diretamente `$baseUrl/catalogo.db?v=<versaoCatalogo>` do servidor do Editor Desktop (LAN ou Cloudflare Relay) sempre que o arquivo experimental local não existir ou sua `versao_catalogo` divergir de `indice.versaoCatalogo`, sem consultar o endpoint de deltas de produção (`catalogo.arestaclimb.com/sync`) e sem extrair o `catalogo.db` do preload oficial.

#### Scenario: Download inicial do catálogo experimental ao conectar ao Editor Desktop
- **WHEN** o aplicativo ativa o Modo Experimental e sincroniza um `indice.binarypb` contendo `versaoCatalogo` não vazia
- **THEN** o `SyncService` baixa `$baseUrl/catalogo.db?v=<versaoCatalogo>` e grava atomicamente em `<docs>/editor/experimental/catalogo.db` sem tocar em `<docs>/catalogo.db`.

#### Scenario: Atualização do catálogo experimental via Live Reload
- **WHEN** o autor salva alterações de catálogo (ex: cria ou renomeia via/setor/grupo) no Editor Desktop e o aplicativo recebe o evento de Live Reload
- **THEN** o `SyncService` detecta a nova `versaoCatalogo` no `indice.binarypb` experimental, baixa o novo `catalogo.db` do Editor Desktop, substitui `<docs>/editor/experimental/catalogo.db` e incrementa `RepositorioCatalogo.versaoNotificador`.

### Requirement: Serialização de Acesso SQLite e Fechamento Seguro Antes de Limpeza Experimental
O `RepositorioCatalogo` DEVE (MUST) serializar as operações de abertura, leitura, escrita, substituição de arquivo (`substituirBancoCompleto`) e fechamento (`fechar`), removendo arquivos auxiliares do SQLite (`-wal`, `-shm`, `-journal`) durante a substituição, e o sistema DEVE (MUST) fechar e aguardar (`await`) o encerramento da conexão SQLite antes de excluir o diretório `<docs>/editor/experimental/` em `nukeExperimentalData()` ou alternar entre os modos Oficial e Experimental.

#### Scenario: Exclusão segura do diretório experimental sem bloqueio de arquivo SQLite
- **WHEN** `nukeExperimentalData()` é invocado enquanto o `RepositorioCatalogo` possui conexão aberta com `<docs>/editor/experimental/catalogo.db`
- **THEN** a conexão SQLite é fechada e aguardada antes da exclusão recursiva do diretório `<docs>/editor/experimental/`, sem lançar `FileSystemException` e restaurando o caminho para `<docs>/catalogo.db`.

#### Scenario: Substituição atômica de banco sem colisão com leituras concorrentes
- **WHEN** `substituirBancoCompleto` é executado concorrentemente com chamadas de leitura (`listarCroquis`, `listarEntidadesDetalhadas` ou `obterIdSlugPorUid`)
- **THEN** o `RepositorioCatalogo` serializa o fechamento, a limpeza de resíduos `-wal`/`-shm`/`-journal` e a renomeação do `.tmp` antes de permitir que novas leituras abram a conexão SQLite.
