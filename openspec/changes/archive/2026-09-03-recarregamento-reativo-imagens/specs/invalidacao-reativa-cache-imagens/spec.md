## MODIFIED Requirements

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
