## MODIFIED Requirements

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

## ADDED Requirements

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
