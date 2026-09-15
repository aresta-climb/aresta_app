## Purpose

Permite a transmissão, exploração sob demanda e atualização contínua de croquis remotos e mídias sem exigir download prévio obrigatório do catálogo.

## Requirements

### Requirement: Carregamento Sob Demanda do Protobuf `.binarypb`
O sistema DEVE (MUST) permitir a recuperação e desserialização direta do arquivo `.binarypb` de um croqui via HTTP a partir do servidor remoto (`NetworkConstants.officialServerUrl`) quando o croqui não estiver salvo localmente em `/downloads`. O buffer obtido DEVE ser mantido em memória e opcionalmente em cache temporário volátil (`getTemporaryDirectory()`), permitindo renderização imediata da hierarquia de setores e vias, e seus arquivos externos (`arquivosExternos`) DEVEM ser indexados imediatamente na tabela de dispersão de SHA-256 do `DatasetRepository`.

#### Scenario: Acesso a croqui não baixado
- **WHEN** o usuário seleciona um pico disponível que não possui arquivos na pasta `/downloads`
- **THEN** o sistema requisita o `.binarypb` correspondente ao caminho relativo do resumo via HTTP
- **AND** desserializa o protobuf `Croqui` instantaneamente sem bloquear a UI com telas de download obrigatório
- **AND** indexa imediatamente os hashes SHA-256 de todas as mídias externas no repositório.

#### Scenario: Fallback de falha de rede ao tentar carregar croqui online
- **WHEN** o usuário tenta abrir um croqui não baixado e o dispositivo está sem conectividade com a internet
- **THEN** o sistema exibe uma mensagem de erro amigável informando a ausência de conexão
- **AND** não insere o croqui no estado ativo de navegação.

### Requirement: Polling Periódico com ETag para Atualizações Online
Enquanto o usuário estiver ativamente navegando nas telas de um croqui em modo online (não baixado), o sistema DEVE (MUST) executar verificações periódicas leves (a cada 30 a 60 segundos) enviando o cabeçalho `If-None-Match: <etag>` para a URL do `.binarypb`. Caso o servidor retorne status `304 Not Modified`, nenhum dado de corpo deve ser trafegado. Caso o servidor retorne status `200 OK`, o sistema DEVE consumir o buffer retornado no corpo da resposta para desserializar a nova instância de `Croqui`, atualizar o `GerenciadorSessaoOnline`, persistir a cópia atualizada no cache volátil (`/temp_cache`), reindexar os hashes SHA-256 de arquivos externos no `DatasetRepository` e emitir notificação para atualização da interface. Se a atualização ocorrer fora do modo experimental, a interface DEVE exibir uma notificação visual informando que o croqui foi atualizado. Se a atualização ocorrer em modo experimental, a recarga da tela DEVE ser imediata e silenciosa com pulso visual no banner. O timer de polling DEVE ser cancelado assim que o usuário sair das telas do referido pico.

#### Scenario: Nenhuma modificação no servidor remoto (304)
- **WHEN** o timer de polling dispara enquanto o croqui online está aberto
- **AND** o arquivo no servidor remoto não sofreu alterações
- **THEN** a requisição HTTP retorna `304 Not Modified`
- **AND** a UI permanece inalterada sem re-renderizações ou consumo de banda.

#### Scenario: Atualização detectada no servidor remoto fora do modo experimental (200)
- **WHEN** o timer de polling dispara fora do modo experimental e uma nova versão do `.binarypb` foi publicada no servidor
- **THEN** a requisição HTTP retorna status `200 OK` com os novos bytes e novo ETag
- **AND** o sistema desserializa o novo `Croqui`, atualiza o `GerenciadorSessaoOnline`, reindexa as mídias no repositório e grava no cache volátil
- **AND** a interface recarrega os dados e exibe um aviso visual amigável informando que o guia do pico foi atualizado.

#### Scenario: Atualização detectada no servidor remoto em modo experimental (200)
- **WHEN** o timer de polling dispara durante o modo experimental ativo e uma nova versão do `.binarypb` é recebida
- **THEN** o sistema atualiza o `GerenciadorSessaoOnline`, reindexa as mídias e atualiza a tela imediatamente sem exibir popups intrusivos
- **AND** o banner de modo experimental emite um pulso luminoso de recarga.

### Requirement: Resolução Híbrida de Imagens e Mídias com Cache Volátil
O provedor de imagens do sistema DEVE (MUST) resolver requisições de mídias externas seguindo a ordem de precedência:
1. Arquivo permanente na pasta `/downloads/<cragId>/` ou `$docsDir/thumbnails/` (se baixado);
2. Arquivo em cache temporário volátil do sistema operacional (`temp_cache`) no formato `<caminho>.<checksumSha256>`;
3. Requisição de streaming à CDN via HTTP utilizando o parâmetro de query para cache-busting `?v=<checksumSha256>`, persistindo imediatamente o arquivo baixado em `temp_cache/<cragId>/<caminho>.<checksumSha256>`.

As imagens carregadas online DEVEM ser transmitidas com o parâmetro `?v=<checksumSha256>` obtido do `DatasetRepository` para que qualquer alteração do croqui na sessão online force a invalidação imediata do cache de rede e a substituição do arquivo em `temp_cache`.

#### Scenario: Imagem encontrada no diretório permanente
- **WHEN** uma imagem de setor, mapa ou thumbnail é solicitada para um croqui salvo offline
- **THEN** o provedor entrega a imagem local a partir do armazenamento permanente sem realizar requisições de rede.

#### Scenario: Imagem encontrada no cache volátil local
- **WHEN** uma imagem é solicitada para um croqui em modo online e já foi previamente persistida em `temp_cache` com o hash SHA-256 esperado
- **THEN** o provedor entrega a imagem a partir do arquivo no `temp_cache` sem emitir requisições de rede.

#### Scenario: Imagem requisitada em modo online não presente no cache
- **WHEN** uma imagem é solicitada para um croqui em modo online e não existe no cache temporário com o hash atual
- **THEN** o sistema requisita a imagem via HTTP com o hash SHA-256 no query string (`?v=<checksumSha256>`)
- **AND** grava os bytes baixados no disco temporário sob `temp_cache/<cragId>/<caminho>.<checksumSha256>`
- **AND** caso uma nova versão com hash alterado seja recebida, o Flutter substitui a imagem na tela em tempo de execução.

### Requirement: Aproveitamento de Mídias em Cache Volátil no Download Offline
Durante o processo de download completo de um croqui para armazenamento permanente (`SyncService`/`DownloadIsolate`), o sistema DEVE (MUST) verificar se cada arquivo externo ou miniatura já existe no `temp_cache` com o `checksumSha256` esperado antes de efetuar a requisição HTTP. Caso o arquivo exista e seja validado pelo hash, ele DEVE ser copiado diretamente para a pasta temporária de montagem atômica (`.tmp`), evitando o tráfego de rede redundante.

#### Scenario: Mídia previamente vista online é reaproveitada no download permanente
- **WHEN** o usuário inicia o download definitivo de um pico cujas imagens já foram abertas em modo online
- **AND** o arquivo em `temp_cache/<cragId>/<caminho>.<expectedHash>` existir fisicamente com integridade válida
- **THEN** o sistema copia o arquivo existente para `<downloadsPath>/<cragId>/<caminho>.tmp`
- **AND** nenhuma requisição HTTP DEVE ser enviada para aquela mídia específica.

#### Scenario: Mídia não vista online é baixada normalmente
- **WHEN** uma mídia de croqui não estiver presente no `temp_cache` durante o download definitivo
- **THEN** o sistema executa o download HTTP normalmente com validação atômica via `.tmp` e hash SHA-256.

### Requirement: Tamanho Pré-Computado de Download no Índice
O protobuf `Indice` e seus resumos (`ResumoCroqui` ou `PrecomputadosResumoCroqui`) DEVEM (MUST) conter o campo `tamanho_download_bytes` previamente computado pelo backend/pipeline de build somando o tamanho do `.binarypb` e de todos os `arquivosExternos`. A camada de visualização DEVE consumir diretamente este valor para exibir tamanhos formatados (ex: "18.4 MB") na interface sem disparar requisições HTTP adicionais (como `HEAD`).

#### Scenario: Exibição do tamanho do download
- **WHEN** a UI renderiza o card de um pico ou o botão de download
- **THEN** o sistema lê `tamanho_download_bytes` do resumo e formata em string legível (B, KB, MB) imediatamente.
