## MODIFIED Requirements

### Requirement: Aplicação Transacional de Deltas (`apply_delta`) via Batch SQLite
Quando `versao_local` divergir de `versao_destino`, o sincronizador DEVE (MUST) consultar `GET https://catalogo.arestaclimb.com/sync?versao_local=<local>&versao_destino=<destino>` — onde o Worker condensa `croquis`, `entidades`, `nos_estrada` e `distancias_estrada` (`upserts` e `deletes`) — e, ao receber `acao: "apply_delta"`, aplicar todas as remoções (`deletes`), inserções/atualizações (`upserts`, incluindo `duracao_minutos`) e a atualização de `catalogo_meta` (`versao_catalogo = versao_atual`) dentro de uma única transação/batch atômico do `sqflite`.

#### Scenario: Aplicação atômica de lote de upserts e deletes
- **WHEN** o endpoint `/sync` retorna `acao: "apply_delta"` contendo croquis e entidades em `deletes` e `upserts`
- **THEN** o `RepositorioCatalogo` executa em uma única transação SQLite os `DELETE` em `catalogo_aresta`, `catalogo_croquis` e `catalogo_distancias_estrada`, seguidos dos `INSERT OR REPLACE` em `catalogo_croquis` e `catalogo_aresta`, e grava `versao_atual` em `catalogo_meta`.

#### Scenario: Aplicação atômica de lote de upserts e deletes incluindo malha rodoviária
- **WHEN** o endpoint `/sync` retorna `acao: "apply_delta"` contendo nós de estrada e distâncias de estrada (com `distancia_metros`, `na_borda` e `duracao_minutos`) em `upserts` e `deletes`
- **THEN** o `RepositorioCatalogo` executa na mesma transação SQLite a remoção de `deletes.distancias_estrada` e os `INSERT OR REPLACE` em `catalogo_nos_estrada` e `catalogo_distancias_estrada` antes de atualizar `versao_catalogo`.

#### Scenario: Preservação de integridade em caso de falha durante o batch
- **WHEN** ocorre um erro inesperado durante a aplicação do batch SQLite
- **THEN** a transação sofre rollback automático, preservando os dados e a `versao_catalogo` anteriores sem corromper o banco local.

#### Scenario: Migração transparente de banco local sem a coluna duracao_minutos
- **WHEN** o `RepositorioCatalogo` abre um `catalogo.db` existente cuja tabela `catalogo_distancias_estrada` ainda não possui a coluna `duracao_minutos`
- **THEN** o repositório migra a tabela `catalogo_distancias_estrada` (`WITHOUT ROWID`) incluindo `duracao_minutos INTEGER NOT NULL DEFAULT 0` sem perda dos registros existentes.
