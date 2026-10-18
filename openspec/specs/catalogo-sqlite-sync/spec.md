# catalogo-sqlite-sync Specification

## Purpose

Gerencia o armazenamento relacional local do catálogo de escaladas em SQLite (`catalogo.db`) via `sqflite`, inferindo sua versão a partir da tabela `catalogo_meta` e mantendo-o sincronizado de forma assíncrona e não-bloqueante através de deltas condensados (`catalogo.arestaclimb.com/sync`) ou download integral.

## Requirements

### Requirement: Inferência de Versão Diretamente do `catalogo.db`
O sistema DEVE (MUST) ler e persistir o identificador de versão do catálogo (`versao_catalogo`, hash SHA-256 curto de 16 caracteres hexadecimais) diretamente na tabela `catalogo_meta` (`chave = 'versao_catalogo'`) dentro do próprio arquivo `catalogo.db`, sem depender de arquivos externos ou chaves separadas em `SharedPreferences`.

#### Scenario: Leitura da versão em banco recém-descompactado do preload
- **WHEN** o `RepositorioCatalogo` abre o arquivo `catalogo.db` extraído do preload
- **THEN** o sistema consulta `SELECT valor FROM catalogo_meta WHERE chave = 'versao_catalogo'` e retorna o hash de 16 caracteres correspondente à versão embutida.

#### Scenario: Banco de catálogo ausente ou tabela vazia
- **WHEN** o arquivo `catalogo.db` ainda não existir no disco ou não possuir o registro `versao_catalogo` em `catalogo_meta`
- **THEN** a consulta de versão local retorna uma string vazia (`""`), sinalizando necessidade de sincronização ou download completo.

### Requirement: Sincronização Assíncrona e Não-Bloqueante Pós-Índice
O `SyncService` DEVE (MUST) verificar e disparar a sincronização do `catalogo.db` de forma assíncrona e não-bloqueante logo após obter ou validar o `indice.binarypb` (tanto quando o índice é atualizado via `IndiceUpdated` quanto quando retorna `304 Not Modified` via `IndiceUnchanged`), rodando concorrentemente com a verificação e download de croquis e thumbnails.

#### Scenario: Versão local do catálogo coincide com `indice.versaoCatalogo`
- **WHEN** o `SyncService` verifica o catálogo e a `versao_catalogo` lida de `catalogo_meta` é idêntica a `indice.versaoCatalogo`
- **THEN** nenhuma requisição HTTP para `/sync` é disparada e o catálogo é considerado atualizado.

#### Scenario: Autocorreção do catálogo mesmo quando o índice retorna 304 Not Modified
- **WHEN** a requisição de `indice.binarypb` retorna `304 Not Modified` (`IndiceUnchanged`), mas a `versao_catalogo` do `catalogo.db` local diverge de `indiceLocal.versaoCatalogo` devido a uma falha de rede anterior
- **THEN** o `SyncService` dispara a sincronização do `catalogo.db` para convergir com `indiceLocal.versaoCatalogo`.

### Requirement: Aplicação Transacional de Deltas (`apply_delta`) via Batch SQLite
Quando `versao_local` divergir de `versao_destino`, o sincronizador DEVE (MUST) consultar `GET https://catalogo.arestaclimb.com/sync?versao_local=<local>&versao_destino=<destino>` e, ao receber `acao: "apply_delta"`, aplicar todas as remoções (`deletes`), inserções/atualizações (`upserts`) e a atualização de `catalogo_meta` (`versao_catalogo = versao_atual`) dentro de uma única transação/batch atômico do `sqflite`.

#### Scenario: Aplicação atômica de lote de upserts e deletes
- **WHEN** o endpoint `/sync` retorna `acao: "apply_delta"` contendo croquis e entidades em `deletes` e `upserts`
- **THEN** o `RepositorioCatalogo` executa em uma única transação SQLite os `DELETE` em `catalogo_aresta` e `catalogo_croquis`, seguidos dos `INSERT OR REPLACE` em `catalogo_croquis` e `catalogo_aresta`, e grava `versao_atual` em `catalogo_meta`.

#### Scenario: Preservação de integridade em caso de falha durante o batch
- **WHEN** ocorre um erro inesperado durante a aplicação do batch SQLite
- **THEN** a transação sofre rollback automático, preservando os dados e a `versao_catalogo` anteriores sem corromper o banco local.

### Requirement: Fallback para Download Completo (`full_download`)
Quando o endpoint `/sync` retornar `acao: "full_download"`, quando `versao_local` estiver vazia ou quando a API de deltas falhar, o sistema DEVE (MUST) realizar o download do arquivo completo `$baseUrl/catalogo.db` para um arquivo temporário (`.tmp`), validar sua abertura SQLite e substituir atomicamente o `catalogo.db` local.

#### Scenario: Histórico de versão desconhecido no servidor (`full_download`)
- **WHEN** o endpoint `/sync` responde com `acao: "full_download"`
- **THEN** o sincronizador baixa `$baseUrl/catalogo.db` em arquivo temporário, fecha a conexão ativa do `sqflite`, substitui o arquivo `catalogo.db` atomicamente e reabre a conexão na nova versão.
