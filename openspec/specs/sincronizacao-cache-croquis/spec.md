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
O cache temporário de croquis consultados sob demanda DEVE (MUST) armazenar os arquivos seguindo o padrão de nomenclatura `compilado.binarypb.<sha256_real>`, onde `<sha256_real>` é o hash SHA-256 calculado diretamente em memória RAM sobre os bytes recebidos na resposta HTTP (`response.bodyBytes`) antes da escrita em disco. A gravação DEVE (MUST) ser realizada de forma atômica através de um arquivo temporário (`.tmp`) renomeado para `compilado.binarypb.<sha256_real>`, registrando `<sha256_real>` na sessão online e expurgando versões irmãs no mesmo diretório do pico que possuam o prefixo `compilado.binarypb.` e hashes divergentes somente após a conclusão da gravação atômica.

#### Scenario: Reutilização imediata de croqui em cache temporário
- **WHEN** o usuário abre um croqui em modo online e o arquivo `compilado.binarypb.<sha256>` já existe no diretório temporário do pico
- **THEN** o sistema lê o croqui diretamente do arquivo existente no cache volátil sem realizar requisições HTTP de rede.

#### Scenario: Gravação com SHA-256 real em memória quando a CDN sofre cache miss e o R2 entrega versão mais nova
- **WHEN** o sistema requisita `compilado.binarypb?v=<hash_antigo>` a partir de um índice local defasado, mas o cache da CDN sofreu despejo (*LRU eviction*) e a origem (R2) retorna os bytes de uma versão mais recente (`<hash_real>`)
- **THEN** o sistema calcula `<hash_real>` em memória a partir de `response.bodyBytes`, grava atomicamente via `.tmp` para `compilado.binarypb.<hash_real>`, registra `<hash_real>` na sessão online e expurga versões anteriores divergentes após o rename.

#### Scenario: Expurgo de versão antiga ao baixar atualização online
- **WHEN** o sistema baixa uma nova versão do croqui online cujo hash calculado em memória é diferente do arquivo temporário existente
- **THEN** o novo arquivo é gravado primeiramente como `.tmp` e renomeado atomicamente para `compilado.binarypb.<novo_hash>`
- **AND** somente após o rename bem-sucedido a versão antiga com o hash defasado é deletada do diretório temporário.

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
A obtenção de um croqui DEVE (MUST) seguir a hierarquia de quatro etapas: (1) Sessão ativa em memória RAM, (2) Armazenamento permanente em `/downloads` priorizando `compilado.binarypb` com migração transparente de arquivos legados, (3) Cache volátil em `/temp_cache` indexado pelo hash atual do índice local, e (4) Download remoto direto da CDN em 1 RTT (`?v=<checksum_local>`) quando o `caminhoRelativo` já constar no índice local em memória, disparando a sincronização do índice (`syncIndex`) de forma silenciosa e não-bloqueante em segundo plano (`unawaited`), ou aguardando `syncIndex` antes do download apenas como fallback quando o `caminhoRelativo` do pico for desconhecido no índice local. Toda rotina de leitura e extração de metadados DEVE delegar para esta hierarquia centralizada sem efetuar leituras manuais isoladas ou cálculos de SHA-256 em tempo de execução nas etapas 1, 2 e 3.

#### Scenario: Resolução priorizando memória RAM
- **WHEN** o croqui do pico solicitado já reside na memória RAM da sessão ativa
- **THEN** o croqui é retornado imediatamente sem acessar o sistema de arquivos ou rede.

#### Scenario: Resolução priorizando armazenamento permanente
- **WHEN** o croqui não está na memória RAM mas existe em `/downloads/<picoId>/compilado.binarypb`
- **THEN** o arquivo é lido e desserializado diretamente sem cálculo de SHA-256 e sem acessar o cache volátil ou a rede.

#### Scenario: Fallback transparente para cache volátil e rede em extração de metadados
- **WHEN** o sistema carregar um croqui ou seus metadados quando não residem em armazenamento permanente
- **THEN** a resolução consulta o arquivo indexado por hash no cache volátil e, se ausente e o `caminhoRelativo` já constar no índice local, requisita imediatamente o download remoto da CDN em 1 RTT com `?v=<checksumSha256Croqui>`, grava no cache volátil com o hash SHA-256 real dos bytes recebidos e dispara `syncIndex` de forma não-bloqueante em segundo plano.

#### Scenario: Fallback de sincronização prévia quando o pico ainda não consta no índice local
- **WHEN** o sistema tenta carregar um croqui cujo identificador ainda não possui `caminhoRelativo` no índice local em memória
- **THEN** a resolução aguarda `syncIndex` para atualizar o índice mestre e o catálogo SQLite antes de realizar o download remoto da CDN.

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
Durante a atualização do conjunto de dados ativo após o download ou exclusão de um croqui, ou ao recarregar o índice em memória (`loadIndiceToMemory`), o sistema DEVE (MUST) reaproveitar as instâncias de croquis baixados já desserializadas em memória (incluindo durante a Fase 1 do `syncIndex` quando o checksum no novo índice tiver mudado mas os novos arquivos ainda estiverem sendo baixados em segundo plano pela Fase 2), realizando leitura, substituição e reconstrução reativa (*hot-reload*) apenas para croquis recém-baixados, ainda não carregados ou cujo commit atômico de atualização na Fase 2 tenha acabado de concluir.

#### Scenario: Download de um novo croqui preserva demais croquis já carregados em memória
- **WHEN** o usuário conclui o download offline de um novo croqui enquanto outros croquis já estavam carregados na lista de baixados
- **THEN** o sistema carrega o binário do novo croqui e reaproveita as instâncias em memória dos croquis anteriormente baixados sem relê-los do disco.

#### Scenario: Preservação sem piscada na Fase 1 e hot-reload atômico na Fase 2 para croqui baixado aberto
- **WHEN** um croqui salvo offline está aberto na tela e a Fase 1 do `syncIndex` carrega um novo `indice.binarypb` com checksum atualizado para esse pico
- **THEN** `loadIndiceToMemory` preserva a instância de `Croqui` já carregada em memória sem exibir tela de carregamento enquanto a Fase 2 baixa os novos arquivos em segundo plano
- **AND** assim que a Fase 2 conclui o rename atômico em `/downloads` e atualiza os metadados do pico, a página aberta reconstrói reativamente (*hot-reload*) com a nova versão do croqui.

#### Scenario: Exclusão de um croqui preserva demais croquis em memória
- **WHEN** o usuário exclui um croqui salvo offline
- **THEN** o croqui excluído é removido da lista de baixados e os demais croquis permanecem com suas instâncias já carregadas em memória sem releitura do disco.

### Requirement: Fallback de Emergência no Cache Volátil em Falha de Rede
Quando o arquivo `compilado.binarypb.<hash_esperado>` não existir no cache volátil (`temp_cache`) e a requisição HTTP para a CDN falhar por ausência de conectividade ou timeout, o sistema DEVE (MUST) verificar se existe qualquer versão anterior `compilado.binarypb.*` no diretório `temp_cache/<picoId>/` e carregá-la como fallback de emergência, registrando o hash correspondente na sessão online.

#### Scenario: Abertura de versão anterior do cache volátil quando sem internet
- **WHEN** o índice local já aponta para `<novo_hash>`, mas o dispositivo está sem conexão com a internet e existe `temp_cache/<picoId>/compilado.binarypb.<hash_antigo>` de uma visualização anterior
- **THEN** o sistema carrega e desserializa `compilado.binarypb.<hash_antigo>` a partir do cache volátil após a falha de rede e abre o croqui normalmente.

### Requirement: Publicação Estagiada de Mídias, Croquis e Manifestos no Deploy
O pipeline de publicação de dados na origem (`update_serving.py`) DEVE (MUST) realizar o upload de arquivos novos ou modificados para o armazenamento de objetos em três estágios sequenciais (cada estágio paralelizado internamente): (1) mídias externas e miniaturas, (2) arquivos `compilado.binarypb`, e (3) manifestos globais (`indice.binarypb`, `indice.yaml`, `catalogo.db`, `arquivos_serving.yaml`) seguidos da invalidação de cache dos manifestos na CDN.

#### Scenario: Ordem estrita de upload evitando envenenamento de cache na CDN
- **WHEN** um deploy contém alterações simultâneas em imagens de setores, arquivos `compilado.binarypb` e `indice.binarypb`
- **THEN** todas as imagens e miniaturas concluem o upload no estágio 1 antes do envio dos arquivos `compilado.binarypb` no estágio 2
- **AND** todos os arquivos `compilado.binarypb` concluem o upload no estágio 2 antes do envio de `indice.binarypb`, `catalogo.db` e `arquivos_serving.yaml` no estágio 3 e do disparo do purge na CDN.
