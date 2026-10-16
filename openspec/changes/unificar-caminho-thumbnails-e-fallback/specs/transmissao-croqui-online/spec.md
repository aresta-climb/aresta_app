# Spec Delta

## MODIFIED Requirements

### Requirement: Resolução Híbrida de Imagens e Mídias com Cache Volátil
O provedor de imagens do sistema DEVE (MUST) resolver requisições de mídias externas seguindo a ordem de precedência:
1. Arquivo permanente na pasta `$downloadsRoot/<cragId>/` ou `$downloadsRoot/thumbnails/` (onde `downloadsRoot = editorDeCroqui.downloadsPath(docsPath)`);
2. Arquivo em cache temporário volátil do sistema operacional (`temp_cache`) no formato `<caminho>.<checksumSha256>`;
3. Requisição de streaming à CDN via HTTP utilizando o parâmetro de query para cache-busting `?v=<checksumSha256>`, persistindo imediatamente o arquivo baixado em `temp_cache/<cragId>/<caminho>.<checksumSha256>` (ou `temp_cache/thumbnails/<cragId>.webp.<checksumSha256>` para miniaturas globais).

As imagens carregadas online DEVEM ser transmitidas com o parâmetro `?v=<checksumSha256>` obtido do `DatasetRepository` para que qualquer alteração do croqui na sessão online force a invalidação imediata do cache de rede e a substituição do arquivo em `temp_cache`.

#### Scenario: Imagem encontrada no diretório permanente
- **WHEN** uma imagem de setor, mapa ou thumbnail é solicitada para um croqui salvo offline ou com miniatura sincronizada em `$downloadsRoot/thumbnails/`
- **THEN** o provedor entrega a imagem local a partir do armazenamento permanente sem realizar requisições de rede.

#### Scenario: Imagem encontrada no cache volátil local
- **WHEN** uma imagem é solicitada para um croqui em modo online e já foi previamente persistida em `temp_cache` com o hash SHA-256 esperado
- **THEN** o provedor entrega a imagem a partir do arquivo no `temp_cache` sem emitir requisições de rede.

#### Scenario: Imagem requisitada em modo online não presente no cache
- **WHEN** uma imagem é solicitada para um croqui em modo online e não existe no cache temporário com o hash atual
- **THEN** o sistema requisita a imagem via HTTP com o hash SHA-256 no query string (`?v=<checksumSha256>`)
- **AND** grava os bytes baixados no disco temporário sob `temp_cache/<cragId>/<caminho>.<checksumSha256>`
- **AND** caso uma nova versão com hash alterado seja recebida, o Flutter substitui a imagem na tela em tempo de execução.
