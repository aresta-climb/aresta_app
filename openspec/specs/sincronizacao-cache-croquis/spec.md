# sincronizacao-cache-croquis Specification

## Purpose

Define a arquitetura de resolução hierárquica e integridade de cache para croquis (`compilado.binarypb`), garantindo cache-busting mandatório, padronização de nomenclatura e expurgo automático sem custo de hashing em tempo de execução.

## Requirements

### Requirement: Cache-Busting Mandatório na Navegação Online
Toda requisição HTTP destinada a carregar o arquivo compilado de um croqui em modo online DEVE (MUST) incluir o parâmetro de consulta `v=<checksum_sha256>`, cujo valor corresponde ao `checksumSha256Croqui` informado no `indice.binarypb`. O sistema DEVE assumir como premissa mandatória a existência desse checksum, não devendo realizar requisições sem o parâmetro de versão.

#### Scenario: Construção da URL de croqui online com parâmetro de versão
- **WHEN** a URL do croqui é resolvida para visualização online sob demanda
- **THEN** a URL gerada contém a query string `?v=<checksumSha256Croqui>` correspondente ao hash cadastrado no índice.

#### Scenario: Prevenção de cache antigo da CDN
- **WHEN** uma nova versão do croqui é publicada no servidor com novo checksum no índice
- **THEN** a requisição online é enviada com o novo hash no parâmetro `v`, forçando a CDN a entregar a versão mais recente em vez de uma resposta em cache estático.

### Requirement: Endereçamento por Conteúdo no Cache Volátil (`temp_cache`)
O cache temporário de croquis consultados sob demanda DEVE (MUST) armazenar os arquivos seguindo o padrão de nomenclatura `compilado.binarypb.<sha256>`. Ao persistir um novo binário, o sistema DEVE expurgar automaticamente quaisquer arquivos irmãos no mesmo diretório do pico que possuam o prefixo `compilado.binarypb.` e hashes divergentes.

#### Scenario: Reutilização imediata de croqui em cache temporário
- **WHEN** o usuário abre um croqui em modo online e o arquivo `compilado.binarypb.<sha256>` já existe no diretório temporário do pico
- **THEN** o sistema lê o croqui diretamente do arquivo existente no cache volátil sem realizar requisições HTTP de rede.

#### Scenario: Expurgo de versão antiga ao baixar atualização online
- **WHEN** o sistema baixa uma nova versão do croqui online cujo hash é diferente do arquivo temporário existente
- **THEN** o novo arquivo `compilado.binarypb.<novo_hash>` é gravado
- **AND** a versão antiga com o hash defasado é deletada do diretório temporário.

### Requirement: Padronização de Armazenamento Permanente e Migração Transparente
Os croquis baixados para visualização offline permanente no diretório `/downloads` DEVEM (MUST) ser armazenados sob o caminho canônico `<downloads>/<picoId>/compilado.binarypb`. O sistema DEVE realizar migração transparente sob demanda (*lazy migration*) ao detectar o formato legado `<picoId>.binarypb`, renomeando-o para `compilado.binarypb`, e o serviço de sincronização DEVE remover sobras de arquivos legados após atualizar o pico.

#### Scenario: Leitura com migração transparente de arquivo legado
- **WHEN** o sistema tenta carregar um croqui baixado e localiza `<downloads>/<picoId>/<picoId>.binarypb` na ausência de `compilado.binarypb`
- **THEN** o arquivo legado é renomeado atomicamente para `compilado.binarypb`
- **AND** o croqui é carregado normalmente a partir do novo arquivo.

#### Scenario: Limpeza de arquivo legado no download ou atualização do sync
- **WHEN** o serviço de sincronização conclui o download atômico de uma nova versão para `compilado.binarypb`
- **THEN** o sistema verifica se ainda existe o arquivo legado `<picoId>/<picoId>.binarypb` no disco
- **AND** se existir, remove-o para evitar acúmulo de lixo no armazenamento do dispositivo.

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

### Requirement: Sincronização Rápida de Índice e Catálogo Não-Bloqueante para Mídias
A sincronização do índice (`syncIndex`) DEVE (MUST) aguardar apenas a verificação do `indice.binarypb` (via ETag) e a sincronização incremental do `catalogo.db`, retornando imediatamente após atualizar os metadados para liberar fluxos dependentes, enquanto a atualização de thumbnails e de croquis baixados executa de forma assíncrona em segundo plano com commit atômico em disco.

#### Scenario: Retorno rápido do syncIndex antes do download de thumbnails e picos
- **WHEN** `syncIndex()` recebe um novo `indice.binarypb` (`200 OK`) do servidor
- **THEN** ele sincroniza o `catalogo.db` imediatamente, dispara o download de thumbnails e atualização de croquis baixados em segundo plano e retorna sem bloquear o chamador pela conclusão das mídias

#### Scenario: Atualização atômica do dataset ativo após conclusão das thumbnails em segundo plano
- **WHEN** a etapa em segundo plano do `syncIndex` conclui o download dos arquivos `.tmp` de thumbnails e croquis
- **THEN** o sistema renomeia os arquivos de forma atômica antes de emitir a atualização final dos cartões na interface

### Requirement: Resolução Unificada e em Camadas para Capas e Cartões de Picos
A exibição de imagens de capa e miniaturas em cartões e cabeçalhos de picos DEVE (MUST) consultar sob demanda o provedor unificado de imagens em camadas no momento da renderização visual, garantindo a ordem estrita de precedência (armazenamento local permanente ➔ cache volátil por hash ➔ streaming remoto da CDN com gravação atômica), sem realizar desvios para provedores de rede puros desprovidos de cache e sem disparar verificações ou pré-carregamentos de arquivos de capa em disco durante o carregamento de metadados do catálogo ou reordenação de picos baixados.

#### Scenario: Resolução de imagem de cartão com pico baixado
- **WHEN** o cartão de pico for renderizado para um croqui salvo localmente
- **THEN** o provedor localiza a imagem de capa ou miniatura no diretório do pico em disco e a exibe sem realizar requisições de rede.

#### Scenario: Resolução de imagem de cartão em modo online com integridade
- **WHEN** o cartão de pico for renderizado para um croqui em modo online
- **THEN** a imagem é consultada no cache volátil através de seu hash SHA-256 e, na ausência, baixada da CDN e persistida atomicamente no cache volátil antes da exibição.

#### Scenario: Carregamento de metadados locais sem resolução antecipada de capa em disco
- **WHEN** o sistema carrega ou atualiza os metadados locais dos croquis salvos offline na memória
- **THEN** ele vincula os dados estruturados do croqui e do pico sem realizar buscas em disco ou chamadas ao provedor de imagem para resolver caminhos de capa antecipadamente.

### Requirement: Reordenação em Memória na Atualização de Prioridade de Navegação
Ao abrir um croqui, a atualização da lista de prioridade de acesso recente DEVE (MUST) persistir a nova ordem de identificadores e reordenar diretamente em memória as coleções de croquis baixados já carregadas no conjunto de dados ativo, sem reconsultar a existência de arquivos no sistema de arquivos e sem reler ou redesserializar binários `compilado.binarypb` do disco.

#### Scenario: Abertura de croqui salvo offline altera a ordem dos croquis baixados
- **WHEN** o usuário abre um croqui salvo offline que não ocupava a primeira posição da lista de croquis baixados
- **THEN** o identificador do croqui é movido para o topo da lista de prioridade persistida
- **AND** as listas de croquis baixados em memória são reordenadas preservando as instâncias já carregadas sem reler arquivos `compilado.binarypb` do disco.

#### Scenario: Abertura de croqui online não reprocessa croquis salvos offline
- **WHEN** o usuário abre um croqui em modo online que não está salvo no armazenamento permanente
- **THEN** a lista de prioridade persistida registra o acesso recente sem disparar releitura de disco ou reconstrução das listas de croquis baixados em memória.

### Requirement: Preservação de Instâncias Carregadas em Atualizações do Conjunto de Dados
Durante a atualização do conjunto de dados ativo após o download ou exclusão de um croqui, ou ao recarregar o índice em memória, o sistema DEVE (MUST) reaproveitar as instâncias de croquis baixados já desserializadas em memória cujos arquivos ou checksums não sofreram alteração, realizando leitura e desserialização de `compilado.binarypb` a partir do disco apenas para croquis recém-baixados ou ainda não carregados.

#### Scenario: Download de um novo croqui preserva demais croquis já carregados em memória
- **WHEN** o usuário conclui o download offline de um novo croqui enquanto outros croquis já estavam carregados na lista de baixados
- **THEN** o sistema carrega o binário do novo croqui e reaproveita as instâncias em memória dos croquis anteriormente baixados sem relê-los do disco.

#### Scenario: Exclusão de um croqui preserva demais croquis em memória
- **WHEN** o usuário exclui um croqui salvo offline
- **THEN** o croqui excluído é removido da lista de baixados e os demais croquis permanecem com suas instâncias já carregadas em memória sem releitura do disco.
