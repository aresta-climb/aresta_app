# Spec Delta

## ADDED Requirements

### Requirement: Sincronização Rápida de Índice e Catálogo Não-Bloqueante para Mídias
A sincronização do índice (`syncIndex`) DEVE (MUST) aguardar apenas a verificação do `indice.binarypb` (via ETag) e a sincronização incremental do `catalogo.db`, retornando imediatamente após atualizar os metadados para liberar fluxos dependentes, enquanto a atualização de thumbnails e de croquis baixados executa de forma assíncrona em segundo plano com commit atômico em disco.

#### Scenario: Retorno rápido do syncIndex antes do download de thumbnails e picos
- **WHEN** `syncIndex()` recebe um novo `indice.binarypb` (`200 OK`) do servidor
- **THEN** ele sincroniza o `catalogo.db` imediatamente, dispara o download de thumbnails e atualização de croquis baixados em segundo plano e retorna sem bloquear o chamador pela conclusão das mídias

#### Scenario: Atualização atômica do dataset ativo após conclusão das thumbnails em segundo plano
- **WHEN** a etapa em segundo plano do `syncIndex` conclui o download dos arquivos `.tmp` de thumbnails e croquis
- **THEN** o sistema renomeia os arquivos de forma atômica antes de emitir a atualização final dos cartões na interface

## MODIFIED Requirements

### Requirement: Hierarquia Estrita de Resolução e Zero Hashing em Runtime
A obtenção de um croqui DEVE (MUST) seguir a hierarquia de quatro etapas: (1) Sessão ativa em memória RAM, (2) Armazenamento permanente em `/downloads` priorizando `compilado.binarypb` com migração transparente de arquivos legados, (3) Cache volátil em `/temp_cache` indexado pelo hash atual, e (4) Sincronização rápida do índice (`syncIndex`) seguida do download remoto da CDN com o hash atualizado e salvamento atômico no cache volátil. Toda rotina de leitura e extração de metadados DEVE delegar para esta hierarquia centralizada sem efetuar leituras manuais isoladas ou cálculos de SHA-256 em tempo de execução nas etapas 1, 2 e 3.

#### Scenario: Resolução priorizando memória RAM
- **WHEN** o croqui do pico solicitado já reside na memória RAM da sessão ativa
- **THEN** o croqui é retornado imediatamente sem acessar o sistema de arquivos ou rede.

#### Scenario: Resolução priorizando armazenamento permanente
- **WHEN** o croqui não está na memória RAM mas existe em `/downloads/<picoId>/compilado.binarypb`
- **THEN** o arquivo é lido e desserializado diretamente sem cálculo de SHA-256 e sem acessar o cache volátil ou a rede.

#### Scenario: Fallback transparente para cache volátil e rede em extração de metadados
- **WHEN** o sistema carregar um croqui ou seus metadados quando não residem em armazenamento permanente
- **THEN** a resolução consulta o arquivo indexado por hash no cache volátil e, se ausente, garante que o índice mestre e o catálogo SQLite estejam sincronizados via `syncIndex` antes de realizar o download remoto da CDN com `?v=<checksumSha256Croqui>` e gravar no cache volátil.
