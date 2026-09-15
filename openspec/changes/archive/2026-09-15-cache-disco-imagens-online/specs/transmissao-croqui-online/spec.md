## MODIFIED Requirements

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

## ADDED Requirements

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
