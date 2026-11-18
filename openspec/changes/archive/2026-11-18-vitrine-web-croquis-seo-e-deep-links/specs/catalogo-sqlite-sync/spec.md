# Spec Delta

## MODIFIED Requirements

### Requirement: Aplicação Transacional de Deltas (`apply_delta`) via Batch SQLite
Quando `versao_local` divergir de `versao_destino`, o sincronizador DEVE (MUST) consultar `GET https://catalogo.arestaclimb.com/sync?versao_local=<local>&versao_destino=<destino>` — onde o Worker condensa `croquis` (incluindo `latitude_e7`, `longitude_e7` e `url_google_maps`), `entidades`, `nos_estrada` e `distancias_estrada` (`upserts` e `deletes`) — e, ao receber `acao: "apply_delta"`, aplicar todas as remoções (`deletes`), inserções/atualizações (`upserts`, incluindo `latitude_e7`, `longitude_e7`, `url_google_maps` e `duracao_minutos`) e a atualização de `catalogo_meta` (`versao_catalogo = versao_atual`) dentro de uma única transação/batch atômico do `sqflite`.

#### Scenario: Aplicação atômica de lote de upserts e deletes
- **WHEN** o endpoint `/sync` retorna `acao: "apply_delta"` contendo croquis (com `latitude_e7`, `longitude_e7` e `url_google_maps`) e entidades em `deletes` e `upserts`
- **THEN** o `RepositorioCatalogo` executa em uma única transação SQLite os `DELETE` em `catalogo_aresta`, `catalogo_croquis` e `catalogo_distancias_estrada`, seguidos dos `INSERT OR REPLACE` em `catalogo_croquis` (persistindo `latitude_e7`, `longitude_e7` e `url_google_maps`) e `catalogo_aresta`, e grava `versao_atual` em `catalogo_meta`.

#### Scenario: Aplicação atômica de lote de upserts e deletes incluindo malha rodoviária
- **WHEN** o endpoint `/sync` retorna `acao: "apply_delta"` contendo nós de estrada e distâncias de estrada (com `distancia_metros`, `na_borda` e `duracao_minutos`) em `upserts` e `deletes`
- **THEN** o `RepositorioCatalogo` executa na mesma transação SQLite a remoção de `deletes.distancias_estrada` e os `INSERT OR REPLACE` em `catalogo_nos_estrada` e `catalogo_distancias_estrada` antes de atualizar `versao_catalogo`.

#### Scenario: Preservação de integridade em caso de falha durante o batch
- **WHEN** ocorre um erro inesperado durante a aplicação do batch SQLite
- **THEN** a transação sofre rollback automático, preservando os dados e a `versao_catalogo` anteriores sem corromper o banco local.

#### Scenario: Migração transparente de banco local sem a coluna duracao_minutos
- **WHEN** o `RepositorioCatalogo` abre um `catalogo.db` existente cuja tabela `catalogo_distancias_estrada` ainda não possui a coluna `duracao_minutos`
- **THEN** o repositório migra a tabela `catalogo_distancias_estrada` (`WITHOUT ROWID`) incluindo `duracao_minutos INTEGER NOT NULL DEFAULT 0` sem perda dos registros existentes.

#### Scenario: Migração transparente de banco local sem colunas geográficas em `catalogo_croquis`
- **WHEN** o `RepositorioCatalogo` abre um `catalogo.db` existente cuja tabela `catalogo_croquis` ainda não possui `latitude_e7`, `longitude_e7` ou `url_google_maps`
- **THEN** o repositório adiciona automaticamente as colunas ausentes via `ALTER TABLE catalogo_croquis ADD COLUMN` preservando integralmente os registros já armazenados.
