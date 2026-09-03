## ADDED Requirements

### Requirement: Pré-indexação Centralizada de SHA-256 no Repositório
O `DatasetRepository` MUST manter uma tabela de dispersão indexada $O(1)$ mapeando caminhos canônicos de mídias para seus respectivos hashes `checksumSha256`, consolidando os arquivos de `croqui.arquivosExternos` e as miniaturas (`checksumSha256Thumbnail`) presentes no `indice.croquis`.

#### Scenario: Indexação de mídias de croqui ao carregar dataset
- **WHEN** um `Croqui` é carregado ou atualizado na memória pelo `DatasetRepository`
- **THEN** o sistema DEVE extrair todos os pares `(caminho, checksumSha256)` de `arquivosExternos` e disponibilizá-los para consulta imediata $O(1)$

#### Scenario: Indexação de miniatura de pico ao carregar índice
- **WHEN** o `Indice` é carregado ou atualizado na memória pelo `DatasetRepository`
- **THEN** o sistema DEVE mapear a miniatura de cada pico sob `thumbnails/<picoId>.webp` associada ao respectivo `checksumSha256Thumbnail`

### Requirement: Provedor de Imagem Aresta com Cache-Busting Unificado
O `ProvedorImagemAresta` MUST gerar instâncias de provedores de imagem cujas chaves incorporem o `checksumSha256` da mídia para diferenciar instantaneamente versões antigas e novas, tanto para arquivos armazenados no disco quanto para streaming remoto da CDN.

#### Scenario: Resolução de imagem remota com query parameter de versão
- **WHEN** uma imagem não baixada localmente for resolvida para streaming remoto
- **AND** existir um `checksumSha256` registrado para a mídia
- **THEN** o provedor DEVE retornar uma instância de `NetworkImage` contendo a query string `?v=<checksumSha256>` anexada à URL

#### Scenario: Resolução de imagem local via ImagemArquivoAresta
- **WHEN** uma imagem for resolvida a partir do armazenamento local (`/downloads` ou `/temp_cache`)
- **THEN** o provedor DEVE retornar uma instância de `ImagemArquivoAresta` contendo o arquivo e o `checksumSha256`
- **AND** a chave gerada (`ChaveImagemArquivoAresta`) DEVE ser sensível a alterações no `checksumSha256`

#### Scenario: Auto-resolução do checksum pelo caminho da mídia
- **WHEN** um componente da interface solicitar a resolução de uma imagem sem passar o `checksumSha256` explicitamente
- **THEN** o `ProvedorImagemAresta` DEVE consultar automaticamente a tabela de dispersão pré-indexada do `DatasetRepository` utilizando o `picoId` e o `caminho`

### Requirement: Invalidação e Atualização Reativa em Hot Reload
O sistema MUST substituir na interface imediatamente qualquer imagem cujo `checksumSha256` tenha sido modificado após um evento de recarregamento (*Live Reload*) ou sincronização, mantendo inalteradas e cacheadas na GPU todas as imagens cujo hash permaneceu idêntico.

#### Scenario: Atualização visual de imagem modificada sem reiniciar tela
- **WHEN** um evento de Live Reload ou sincronização atualizar o arquivo em disco e o `checksumSha256` no croqui
- **AND** a tela aberta contiver a visualização dessa imagem
- **THEN** o Flutter DEVE detectar a mudança na chave do provedor de imagem e redesenhar a nova imagem sem exigir navegação ou fechamento da tela
- **AND** a posição de rolagem do usuário DEVE ser preservada

#### Scenario: Imagens inalteradas continuam em cache sem recarga
- **WHEN** um evento de Live Reload ocorrer e uma imagem na tela mantiver o mesmo `checksumSha256`
- **THEN** o Flutter DEVE reutilizar a textura em memória RAM/GPU existente sem executar nova leitura de disco ou requisição de rede

### Requirement: Re-resolução do Ciclo de Vida em Telas com Estado
Os componentes visuais com estado (`SetorPage`, `GrupoPage`, `MapaInterativoPage`, `MapaThumbnail`) MUST re-resolver seus futuros de imagem durante a execução do método `didUpdateWidget` chamando `setState()`.

#### Scenario: Atualização de capa em SetorPage e GrupoPage
- **WHEN** a `SetorPage` ou `GrupoPage` for reconstruída pelo `PageListenableBuilder`
- **THEN** o método `didUpdateWidget` DEVE re-chamar a resolução da imagem de capa via `setState()` para obter o novo provedor de imagem atualizado

#### Scenario: Atualização de mapa em MapaInterativoPage e MapaThumbnail
- **WHEN** a `MapaInterativoPage` ou `MapaThumbnail` for reconstruída pelo `PageListenableBuilder`
- **THEN** o método `didUpdateWidget` DEVE re-chamar a resolução do mapa via `setState()` sem depender de checagem rasa de igualdade no objeto Protobuf `Mapa`

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
