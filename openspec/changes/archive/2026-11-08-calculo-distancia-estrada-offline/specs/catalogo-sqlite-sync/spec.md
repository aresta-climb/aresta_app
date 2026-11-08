# catalogo-sqlite-sync Specification

## MODIFIED Requirements

### Requirement: Aplicação Transacional de Deltas (`apply_delta`) via Batch SQLite
Quando `versao_local` divergir de `versao_destino`, o sincronizador DEVE (MUST) consultar `GET https://catalogo.arestaclimb.com/sync?versao_local=<local>&versao_destino=<destino>` e, ao receber `acao: "apply_delta"`, aplicar todas as remoções (`deletes`), inserções/atualizações (`upserts`) — incluindo nós rodoviários (`catalogo_nos_estrada`) e distâncias por croqui (`catalogo_distancias_estrada`) quando presentes — e a atualização de `catalogo_meta` (`versao_catalogo = versao_atual`) dentro de uma única transação/batch atômico do `sqflite`.

#### Scenario: Aplicação atômica de lote de upserts e deletes
- **WHEN** o endpoint `/sync` retorna `acao: "apply_delta"` contendo croquis e entidades em `deletes` e `upserts`
- **THEN** o `RepositorioCatalogo` executa em uma única transação SQLite os `DELETE` em `catalogo_aresta`, `catalogo_croquis` e `catalogo_distancias_estrada`, seguidos dos `INSERT OR REPLACE` em `catalogo_croquis` e `catalogo_aresta`, e grava `versao_atual` em `catalogo_meta`.

#### Scenario: Aplicação atômica de lote de upserts e deletes incluindo malha rodoviária
- **WHEN** o endpoint `/sync` retorna `acao: "apply_delta"` contendo nós de estrada e distâncias de estrada em `upserts`
- **THEN** o `RepositorioCatalogo` executa na mesma transação SQLite os `INSERT OR REPLACE` em `catalogo_nos_estrada` e `catalogo_distancias_estrada` antes de atualizar `versao_catalogo`.

#### Scenario: Preservação de integridade em caso de falha durante o batch
- **WHEN** ocorre um erro inesperado durante a aplicação do batch SQLite
- **THEN** a transação sofre rollback automático, preservando os dados e a `versao_catalogo` anteriores sem corromper o banco local.
