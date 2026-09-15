## Purpose

Garante a invalidação reativa, resolução e integridade por checksum SHA-256 de imagens em tempo real no aplicativo, tanto para arquivos locais e temporários em disco quanto para transmissões da CDN.

## Requirements

### Requirement: Pré-indexação Centralizada de SHA-256 no Repositório
O `DatasetRepository` MUST manter uma tabela de dispersão indexada $O(1)$ mapeando caminhos canônicos normalizados de mídias para seus respectivos hashes `checksumSha256`, consolidando os arquivos de `croqui.arquivosExternos` e as miniaturas (`checksumSha256Thumbnail`) presentes no `indice.croquis`. Caso uma consulta de mídia não seja encontrada inicialmente e o croqui esteja carregado na sessão online, o repositório DEVE reindexar dinamicamente o croqui online sob demanda.

#### Scenario: Indexação de mídias de croqui ao carregar dataset
- **WHEN** um `Croqui` é carregado ou atualizado na memória pelo `DatasetRepository`
- **THEN** o sistema DEVE extrair todos os pares `(caminho, checksumSha256)` de `arquivosExternos` e disponibilizá-los para consulta imediata $O(1)$
- **AND** os caminhos DEVEM ser normalizados removendo prefixos `./`, `/` e convertendo separadores de barra invertida (`\`) em barras normais (`/`)

#### Scenario: Indexação de miniatura de pico ao carregar índice
- **WHEN** o `Indice` é carregado ou atualizado na memória pelo `DatasetRepository`
- **THEN** o sistema DEVE mapear a miniatura de cada pico sob `thumbnails/<picoId>.webp` associada ao respectivo `checksumSha256Thumbnail`

#### Scenario: Re-indexação sob demanda para croquis online
- **WHEN** o método `obterSha256DaMidia` for consultado para um caminho de mídia não previamente indexado
- **AND** o pico correspondente estiver registrado no `GerenciadorSessaoOnline`
- **THEN** o sistema DEVE indexar imediatamente os `arquivosExternos` do croqui online em memória e retornar o hash correspondente

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

### Requirement: Invalidação e Atualização Reativa em Hot Reload
O sistema MUST substituir na interface imediatamente qualquer imagem cujo `checksumSha256` tenha sido modificado após um evento de recarregamento (*Live Reload*) ou sincronização, purgar o cache ativo de imagens do Flutter (`PaintingBinding.instance.imageCache.clear()` e `clearLiveImages()`), e manter inalteradas e cacheadas na GPU todas as imagens cujo hash permaneceu idêntico.

#### Scenario: Atualização visual de imagem modificada sem reiniciar tela
- **WHEN** um evento de Live Reload ou sincronização atualizar o arquivo em disco ou a versão em streaming online
- **AND** a tela aberta contiver a visualização dessa imagem
- **THEN** o sistema DEVE expurgar o cache de imagens do Flutter (`clear()` e `clearLiveImages()`)
- **AND** o Flutter DEVE detectar a mudança na chave do provedor de imagem e redesenhar a nova imagem sem exigir navegação ou fechamento da tela
- **AND** a posição de rolagem do usuário DEVE ser preservada

#### Scenario: Imagens inalteradas continuam em cache sem recarga
- **WHEN** um evento de Live Reload ocorrer e uma imagem na tela mantiver o mesmo `checksumSha256`
- **THEN** o Flutter DEVE reutilizar a textura em memória RAM/GPU existente sem executar nova leitura de disco ou requisição de rede

### Requirement: Re-resolução do Ciclo de Vida em Telas com Estado
Os componentes visuais com estado (`SetorPage`, `GrupoPage`, `MapaInterativoPage`, `MapaThumbnail`, `MapasCarrosselPage`) MUST re-resolver seus futuros de imagem e notificar o framework durante a execução do método `didUpdateWidget` chamando `setState()`.

#### Scenario: Atualização de capa em SetorPage e GrupoPage
- **WHEN** a `SetorPage` ou `GrupoPage` for reconstruída pelo `PageListenableBuilder`
- **THEN** o método `didUpdateWidget` DEVE re-chamar a resolução da imagem de capa via `setState()` para obter o novo provedor de imagem atualizado

#### Scenario: Atualização de mapa em MapaInterativoPage e MapaThumbnail
- **WHEN** a `MapaInterativoPage` ou `MapaThumbnail` for reconstruída pelo `PageListenableBuilder`
- **THEN** o método `didUpdateWidget` DEVE re-chamar a resolução do mapa via `setState()` sem depender de checagem rasa de igualdade no objeto Protobuf `Mapa`

#### Scenario: Atualização de carrossel em MapasCarrosselPage
- **WHEN** o `MapasCarrosselPage` for reconstruído pelo `PageListenableBuilder` após um Live Reload
- **THEN** o método `didUpdateWidget` DEVE executar `setState()` para propagar as alterações para o `PageView.builder` e remontar os nós filhos com chaves reativas

### Requirement: Preservação de Cache de Memória no OfflineMarkdown
O widget `OfflineMarkdown` MUST preservar instâncias ativas de imagens em memória RAM durante atualizações de ciclo de vida (`didUpdateWidget`), abstendo-se de chamar `provider.evict()` cegamente, exceto quando houver alteração substancial no conteúdo Markdown renderizado (`widget.data != oldWidget.data`).

#### Scenario: Reconstrução de tela sem alteração de conteúdo markdown
- **WHEN** o widget `OfflineMarkdown` for reconstruído devido a eventos do `PageListenableBuilder`, rolagem ou polling
- **AND** o conteúdo `data` for idêntico ao do widget anterior
- **THEN** o widget NÃO DEVE evictar as imagens da memória RAM
- **AND** as texturas cacheadas DEVEM permanecer visíveis sem recarga ou cintilação visual.

### Requirement: Test-Driven Development e Cobertura Integral
O desenvolvimento MUST ser orientado estritamente por Testes em Primeiro Lugar (TDD), priorizando testes de widget para validar o comportamento visual ponta a ponta e assegurando 100% de cobertura de código para os arquivos modificados e criados.

#### Scenario: Testes de widget escritos e validados em falha antes da implementação
- **WHEN** uma nova funcionalidade ou correção de ciclo de vida for iniciada
- **THEN** os testes de widget e de unidade DEVEM ser criados e executados em falha (Red) antes da escrita do código de produção (Green)
- **AND** a cobertura final de testes nos arquivos criados ou modificados DEVE ser de 100%

### Requirement: Nomenclatura e Documentação em Português Brasileiro
Todo o código, identificadores, classes, variáveis, métodos, comentários e documentação técnica MUST estar integralmente em português brasileiro, acompanhados de docstrings explicativas com blocos `///`.

#### Scenario: Identificadores e docstrings no código
- **WHEN** novas classes, tipos ou métodos forem adicionados (ex: `ImagemArquivoAresta`, `ChaveImagemArquivoAresta`, `obterSha256DaMidia`)
- **THEN** os nomes DEVEM estar em português brasileiro
- **AND** as classes e métodos públicos DEVEM conter docstrings explicando a intenção e o funcionamento
