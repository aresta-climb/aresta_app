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
A obtenção de um croqui DEVE (MUST) seguir a hierarquia de quatro etapas: (1) Sessão ativa em memória RAM, (2) Armazenamento permanente em `/downloads` priorizando `compilado.binarypb` com migração transparente de arquivos legados, (3) Cache volátil em `/temp_cache` indexado pelo hash atual, e (4) Download remoto da CDN com salvamento atômico no cache volátil. Toda rotina de leitura e extração de metadados DEVE delegar para esta hierarquia centralizada sem efetuar leituras manuais isoladas ou cálculos de SHA-256 em tempo de execução nas etapas 1, 2 e 3.

#### Scenario: Resolução priorizando memória RAM
- **WHEN** o croqui do pico solicitado já reside na memória RAM da sessão ativa
- **THEN** o croqui é retornado imediatamente sem acessar o sistema de arquivos ou rede.

#### Scenario: Resolução priorizando armazenamento permanente
- **WHEN** o croqui não está na memória RAM mas existe em `/downloads/<picoId>/compilado.binarypb`
- **THEN** o arquivo é lido e desserializado diretamente sem cálculo de SHA-256 e sem acessar o cache volátil ou a rede.

#### Scenario: Fallback transparente para cache volátil e rede em extração de metadados
- **WHEN** o sistema carregar metadados de um croqui que não reside em armazenamento permanente
- **THEN** a resolução consulta o arquivo indexado por hash no cache volátil e, se ausente, realiza o download remoto da CDN gravando no cache volátil antes de instanciar os metadados.

### Requirement: Resolução Unificada e em Camadas para Capas e Cartões de Picos
A exibição de imagens de capa e miniaturas em cartões de picos DEVE (MUST) consultar o provedor unificado de imagens em camadas, garantindo a ordem estrita de precedência (armazenamento local permanente ➔ cache volátil por hash ➔ streaming remoto da CDN com gravação atômica), sem realizar desvios para provedores de rede puros desprovidos de cache.

#### Scenario: Resolução de imagem de cartão com pico baixado
- **WHEN** o cartão de pico for renderizado para um croqui salvo localmente
- **THEN** o provedor localiza a imagem de capa ou miniatura no diretório do pico em disco e a exibe sem realizar requisições de rede.

#### Scenario: Resolução de imagem de cartão em modo online com integridade
- **WHEN** o cartão de pico for renderizado para um croqui em modo online
- **THEN** a imagem é consultada no cache volátil através de seu hash SHA-256 e, na ausência, baixada da CDN e persistida atomicamente no cache volátil antes da exibição.
