## MODIFIED Requirements

### Requirement: Provedor de Imagem Aresta com Cache-Busting Unificado
O `ProvedorImagemAresta` MUST gerar instâncias de provedores de imagem cujas chaves incorporem o `checksumSha256` da mídia para diferenciar instantaneamente versões antigas e novas, tanto para arquivos armazenados no disco quanto para transmissões da CDN. O provedor DEVE identificar como miniatura global do catálogo (`ehThumbnail`) exclusivamente caminhos que apontem para a pasta `thumbnails/` (`thumbnails/<picoId>.webp`) ou para `<picoId>.webp`, tratando qualquer caminho definido em `croqui.caminhoThumbnail` (incluindo `imagens/thumbnail.webp`) uniformemente como mídia interna normal do croqui (`croqui.arquivosExternos`), sem redirecionamento especial para `$downloadsRoot/thumbnails/<picoId>.webp`. As miniaturas permanentes DEVEM ser lidas exclusivamente de `$downloadsRoot/thumbnails/<picoId>.webp` (onde `downloadsRoot` corresponde a `editorDeCroqui.downloadsPath(docsPath)`). Ao transmitir imagens remotas da CDN para croquis em modo online ou miniaturas globais, o provedor DEVE (MUST) persistir os bytes recebidos no cache volátil do sistema operacional (`temp_cache`) utilizando a convenção `<caminho>.<checksumSha256>`, exceto para miniaturas globais que DEVEM ser salvas como `temp_cache/thumbnails/<picoId>.webp.<checksumSha256>`. A existência de um `checksumSha256` válido é estritamente obrigatória para gravação em disco; caso o hash seja nulo ou vazio ao resolver uma mídia remota, o sistema DEVE verificar se o croqui está baixado offline (`isPicoDownloaded(picoId)`): se estiver baixado offline, DEVE registrar erro na telemetria via `AppLogger.instance.logError`; caso contrário (exploração online), DEVE registrar apenas aviso via `AppLogger.instance.logAviso`, realizando em ambos os casos fallback direto para `NetworkImage` sem salvar no `temp_cache`. Caso o download da mídia remota falhe (seja por queda de conexão, socket fechado, timeout ou status HTTP diferente de 200), o provedor DEVE retornar `null` (em vez de recorrer a `NetworkImage`). Falhas operacionais de conectividade ou timeout DEVEM ser registradas via `AppLogger.instance.logAviso` sem emissão de `logError` para o Crashlytics. Após salvar uma nova versão de mídia com hash atualizado, o sistema DEVE expurgar versões anteriores com hashes divergentes do mesmo arquivo na mesma pasta.

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
- **AND** não estiver presente no diretório permanente `$downloadsRoot/thumbnails/<picoId>.webp`
- **THEN** o sistema DEVE verificar se existe o arquivo em `$caminhoCacheVolatil/thumbnails/<picoId>.webp.<checksumSha256>`
- **AND** caso não exista, baixar da CDN, gravar em `$caminhoCacheVolatil/thumbnails/<picoId>.webp.<checksumSha256>` e retornar o provedor local correspondente.

#### Scenario: Resolução de imagem local permanente via ImagemArquivoAresta
- **WHEN** uma imagem for resolvida a partir do armazenamento local permanente (`$downloadsRoot/<picoId>/...` ou `$downloadsRoot/thumbnails/<picoId>.webp`)
- **THEN** o provedor DEVE retornar uma instância de `ImagemArquivoAresta` contendo o arquivo e o `checksumSha256`
- **AND** a chave gerada (`ChaveImagemArquivoAresta`) DEVE ser sensível a alterações no `checksumSha256`.

#### Scenario: Resolução de imagens/thumbnail.webp como mídia normal do croqui
- **WHEN** o caminho solicitado for `imagens/thumbnail.webp` (definido em `Croqui.caminho_thumbnail`)
- **AND** o arquivo `$downloadsRoot/<picoId>/imagens/thumbnail.webp` existir localmente
- **THEN** o `ProvedorImagemAresta` NÃO DEVE reescrever o caminho para `thumbnails/<picoId>.webp`
- **AND** DEVE resolver o arquivo a partir de `$downloadsRoot/<picoId>/imagens/thumbnail.webp` usando o hash de `croqui.arquivosExternos`.

#### Scenario: Priorização da thumbnail de catálogo local para capa de croqui online
- **WHEN** uma capa de croqui (`caminho == 'imagens/thumbnail.webp'` ou qualquer `croqui.caminhoThumbnail`) for resolvida para um croqui online não baixado
- **AND** o arquivo de miniatura do catálogo `$downloadsRoot/thumbnails/<picoId>.webp` existir localmente
- **THEN** o `ProvedorImagemAresta` NÃO DEVE redirecionar o caminho da capa para `thumbnails/<picoId>.webp`
- **AND** a priorização de `thumbnails/<picoId>.webp` DEVE ocorrer exclusivamente nos ViewModels de cartões de listagem (`CardCroquiViewModel`).

#### Scenario: Fallback para download de capa interna quando miniatura local não existir
- **WHEN** a capa do croqui (`croqui.caminhoThumbnail`) for solicitada na página de detalhes do croqui e o arquivo local `$downloadsRoot/<picoId>/<caminho>` não existir
- **THEN** o sistema DEVE proceder com o download remoto da mídia de `croqui.caminhoThumbnail` para o cache volátil conforme as regras padrão da CDN, independentemente da existência de `$downloadsRoot/thumbnails/<picoId>.webp`.

#### Scenario: Resolução alvo de 450px para cabeçalho do pico
- **WHEN** o componente `buildCragBackground` em `card_pico.dart` for construído com parâmetros padrão nos cartões de catálogo (`CragCard`)
- **THEN** a `larguraAlvo` padrão configurada para o `ProvedorImagemAresta.resolver` DEVE ser 450px (enquanto na `PicoDetailsPage` DEVE ser 1200px com borda inteligente)
- **AND** as dimensões visuais na árvore de widgets DEVEM ser mantidas inalteradas.

#### Scenario: Auto-resolução do checksum pelo caminho da mídia
- **WHEN** um componente da interface solicitar a resolução de uma imagem sem passar o `checksumSha256` explicitamente
- **THEN** o `ProvedorImagemAresta` DEVE consultar automaticamente a tabela de dispersão pré-indexada do `DatasetRepository` utilizando o `picoId` e o `caminho`.

#### Scenario: Fallback dinâmico com log de telemetria para arquivos locais sem hash
- **WHEN** uma imagem local permanente não possuir `checksumSha256` disponível no repositório
- **THEN** o sistema DEVE registrar um erro na telemetria via `AppLogger.instance.logError`
- **AND** seguir em frente utilizando o timestamp de modificação (`lastModifiedSync`) como hash substituto para preservar a diferenciação de chave no Flutter.

#### Scenario: Anomalia de mídia remota sem hash de integridade
- **WHEN** uma imagem remota for solicitada e não possuir `checksumSha256` na tabela de dispersão nem nos argumentos
- **AND** o croqui correspondente estiver marcado como baixado offline (`isPicoDownloaded(picoId) == true`)
- **THEN** o sistema DEVE emitir erro na telemetria via `AppLogger.instance.logError`
- **AND** NENHUM arquivo DEVE ser gravado no diretório `temp_cache`
- **AND** o provedor DEVE retornar `NetworkImage` direto como salvaguarda visual.

#### Scenario: Mídia remota sem hash de integridade para croqui não baixado (online)
- **WHEN** uma imagem remota for solicitada e não possuir `checksumSha256` na tabela de dispersão nem nos argumentos
- **AND** o croqui correspondente NÃO estiver baixado offline (`isPicoDownloaded(picoId) == false`)
- **THEN** o sistema DEVE registrar apenas um aviso contextual via `AppLogger.instance.logAviso` (sem enviar `logError` ao Crashlytics)
- **AND** NENHUM arquivo DEVE ser gravado no diretório `temp_cache`
- **AND** o provedor DEVE retornar `NetworkImage` direto como salvaguarda visual.

#### Scenario: Limpeza de versões com hash antigo após download bem-sucedido
- **WHEN** o download de uma nova versão de imagem `<caminho>.<novoHash>` for concluído com sucesso em `temp_cache`
- **THEN** o sistema DEVE remover do mesmo diretório qualquer arquivo irmão do mesmo caminho base que contenha hash anterior divergente.

#### Scenario: Falha de conectividade ou rede durante download de imagem remota
- **WHEN** a tentativa de download atômico falhar devido a queda de conexão, socket inacessível (`SocketException`), timeout ou indisponibilidade de DNS
- **THEN** o `ProvedorImagemAresta` DEVE registrar o aviso como `logAviso` contextual
- **AND** NÃO DEVE invocar `logError` para o Crashlytics
- **AND** DEVE retornar `null` (não retornando `NetworkImage`).

## ADDED Requirements

### Requirement: Borda Inteligente no Cabeçalho do Croqui e Separação de Miniatura de Catálogo
O cabeçalho da página de detalhes do croqui (`PicoDetailsPage`, `expandedHeight: 300.0`) MUST exibir `croqui.caminhoThumbnail` em alta resolução (`larguraAlvo: 1200`) sem cortes usando borda inteligente: fundo `BoxFit.cover` desfocado (`ImageFilter.blur` com `TileMode.clamp`) e primeiro plano `BoxFit.contain` ocupando 100% da área disponível. Já os cartões de listagem (`CragCard` e `OfflineCragCard`) MUST priorizar `thumbnails/<picoId>.webp` com fallback para `croqui.caminhoThumbnail`.

#### Scenario: Renderização da capa sem cortes com borda inteligente na página de detalhes do croqui
- **WHEN** a página de detalhes do croqui (`PicoDetailsPage`) construir o plano de fundo da `SliverAppBar` (`expandedHeight: 300.0`) para um croqui com `caminhoThumbnail` definido
- **THEN** o sistema DEVE resolver `croqui.caminhoThumbnail` com `larguraAlvo: 1200`
- **AND** DEVE renderizar uma camada de fundo com `BoxFit.cover` e filtro de desfoque Gaussiano (`TileMode.clamp`) preenchendo toda a área do cabeçalho
- **AND** DEVE renderizar sobre ela a mesma imagem com `BoxFit.contain` ocupando 100% da altura/largura disponível sem cortar nenhuma borda da arte.

#### Scenario: Priorização de miniatura de catálogo em cartões de listagem a partir de Croqui
- **WHEN** um `CardCroquiViewModel` for instanciado a partir de um objeto `Croqui` (`CardCroquiViewModel.deCroqui`) e existir hash indexado para `thumbnails/<picoId>.webp`
- **THEN** `caminhoMiniatura` DEVE retornar `'thumbnails/<picoId>.webp'`
- **AND** caso não exista hash indexado para `thumbnails/<picoId>.webp`, `caminhoMiniatura` DEVE retornar `croqui.caminhoThumbnail` (ou `null` se ambos estiverem ausentes).

#### Scenario: Renderização padrão com preenchimento em cartões de catálogo
- **WHEN** `buildCragBackground` for utilizado nos cartões de catálogo (`CragCard`) sem borda inteligente ativada
- **THEN** a `larguraAlvo` padrão DEVE permanecer `450` e a imagem DEVE ser exibida em camada única com `BoxFit.cover`.
