## MODIFIED Requirements

### Requirement: Provedor de Imagem Aresta com Cache-Busting Unificado
O `ProvedorImagemAresta` MUST gerar instâncias de provedores de imagem cujas chaves incorporem o `checksumSha256` da mídia para diferenciar instantaneamente versões antigas e novas, tanto para arquivos armazenados no disco quanto para streaming remoto da CDN. Ao transmitir imagens remotas da CDN para croquis em modo online ou miniaturas globais, o provedor DEVE (MUST) persistir os bytes recebidos no cache volátil do sistema operacional (`temp_cache`) utilizando a convenção `<caminho>.<checksumSha256>`, exceto para miniaturas globais que DEVEM ser salvas como `temp_cache/thumbnails/<picoId>.webp.<checksumSha256>`. A existência de um `checksumSha256` válido é estritamente obrigatória para gravação em disco; caso o hash seja nulo ou vazio, o sistema DEVE registrar erro na telemetria via `AppLogger.instance.logError` e realizar fallback direto para `NetworkImage` sem salvar no `temp_cache`. Após salvar uma nova versão de mídia com hash atualizado, o sistema DEVE expurgar versões anteriores com hashes divergentes do mesmo arquivo na mesma pasta.

#### Scenario: Resolução de imagem remota com query parameter de versão e persistência atômica em cache volátil
- **WHEN** uma imagem não baixada permanentemente for resolvida para streaming remoto
- **AND** existir um `checksumSha256` válido registrado para a mídia
- **THEN** o provedor DEVE baixar os bytes da CDN utilizando a URL com `?v=<checksumSha256>`
- **AND** gravar atomicamente os bytes em `$caminhoCacheVolatil/<picoId>/<caminho>.<checksumSha256>`
- **AND** retornar uma instância de `ImagemArquivoAresta` associada ao novo arquivo gerado.

#### Scenario: Resolução imediata de imagem prévia salva em temp_cache
- **WHEN** uma imagem for solicitada e já existir o arquivo correspondente em `$caminhoCacheVolatil/<picoId>/<caminho>.<checksumSha256>`
- **THEN** o `ProvedorImagemAresta` DEVE retornar imediatamente `ImagemArquivoAresta` para o arquivo existente
- **AND** nenhuma requisição de rede HTTP DEVE ser disparada.

#### Scenario: Resolução e cache volátil de miniatura global
- **WHEN** uma miniatura de pico (`thumbnails/<picoId>.webp`) for solicitada via `ProvedorImagemAresta`
- **AND** não estiver presente no diretório permanente `$docsDir/thumbnails/<picoId>.webp`
- **THEN** o sistema DEVE verificar se existe o arquivo em `$caminhoCacheVolatil/thumbnails/<picoId>.webp.<checksumSha256>`
- **AND** caso não exista, baixar da CDN, gravar em `$caminhoCacheVolatil/thumbnails/<picoId>.webp.<checksumSha256>` e retornar o provedor local correspondente.

#### Scenario: Resolução de imagem local permanente via ImagemArquivoAresta
- **WHEN** uma imagem for resolvida a partir do armazenamento local permanente (`/downloads` ou `$docsDir/thumbnails`)
- **THEN** o provedor DEVE retornar uma instância de `ImagemArquivoAresta` contendo o arquivo e o `checksumSha256`
- **AND** a chave gerada (`ChaveImagemArquivoAresta`) DEVE ser sensível a alterações no `checksumSha256`.

#### Scenario: Auto-resolução do checksum pelo caminho da mídia
- **WHEN** um componente da interface solicitar a resolução de uma imagem sem passar o `checksumSha256` explicitamente
- **THEN** o `ProvedorImagemAresta` DEVE consultar automaticamente a tabela de dispersão pré-indexada do `DatasetRepository` utilizando o `picoId` e o `caminho`.

#### Scenario: Fallback dinâmico com log de telemetria para arquivos locais sem hash
- **WHEN** uma imagem local permanente não possuir `checksumSha256` disponível no repositório
- **THEN** o sistema DEVE registrar um erro na telemetria via `AppLogger.instance.logError`
- **AND** seguir em frente utilizando o timestamp de modificação (`lastModifiedSync`) como hash substituto para preservar a diferenciação de chave no Flutter.

#### Scenario: Anomalia de mídia remota sem hash de integridade
- **WHEN** uma imagem remota for solicitada e não possuir `checksumSha256` na tabela de dispersão nem nos argumentos
- **THEN** o sistema DEVE emitir erro na telemetria via `AppLogger.instance.logError`
- **AND** NENHUM arquivo DEVE ser gravado no diretório `temp_cache`
- **AND** o provedor DEVE retornar `NetworkImage` direto como salvaguarda visual.

#### Scenario: Limpeza de versões com hash antigo após download bem-sucedido
- **WHEN** o download de uma nova versão de imagem `<caminho>.<novoHash>` for concluído com sucesso em `temp_cache`
- **THEN** o sistema DEVE remover do mesmo diretório qualquer arquivo irmão do mesmo caminho base que contenha hash anterior divergente.

## ADDED Requirements

### Requirement: Preservação de Cache de Memória no OfflineMarkdown
O widget `OfflineMarkdown` MUST preservar instâncias ativas de imagens em memória RAM durante atualizações de ciclo de vida (`didUpdateWidget`), abstendo-se de chamar `provider.evict()` cegamente, exceto quando houver alteração substancial no conteúdo Markdown renderizado (`widget.data != oldWidget.data`).

#### Scenario: Reconstrução de tela sem alteração de conteúdo markdown
- **WHEN** o widget `OfflineMarkdown` for reconstruído devido a eventos do `PageListenableBuilder`, rolagem ou polling
- **AND** o conteúdo `data` for idêntico ao do widget anterior
- **THEN** o widget NÃO DEVE evictar as imagens da memória RAM
- **AND** as texturas cacheadas DEVEM permanecer visíveis sem recarga ou cintilação visual.
