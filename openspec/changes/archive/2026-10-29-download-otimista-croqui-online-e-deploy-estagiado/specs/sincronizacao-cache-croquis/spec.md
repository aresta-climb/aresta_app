# Spec Delta

## ADDED Requirements

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

## MODIFIED Requirements

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
