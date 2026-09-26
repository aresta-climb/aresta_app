## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: Resolução Unificada e em Camadas para Capas e Cartões de Picos
A exibição de imagens de capa e miniaturas em cartões de picos DEVE (MUST) consultar o provedor unificado de imagens em camadas, garantindo a ordem estrita de precedência (armazenamento local permanente ➔ cache volátil por hash ➔ streaming remoto da CDN com gravação atômica), sem realizar desvios para provedores de rede puros desprovidos de cache.

#### Scenario: Resolução de imagem de cartão com pico baixado
- **WHEN** o cartão de pico for renderizado para um croqui salvo localmente
- **THEN** o provedor localiza a imagem de capa ou miniatura no diretório do pico em disco e a exibe sem realizar requisições de rede.

#### Scenario: Resolução de imagem de cartão em modo online com integridade
- **WHEN** o cartão de pico for renderizado para um croqui em modo online
- **THEN** a imagem é consultada no cache volátil através de seu hash SHA-256 e, na ausência, baixada da CDN e persistida atomicamente no cache volátil antes da exibição.
