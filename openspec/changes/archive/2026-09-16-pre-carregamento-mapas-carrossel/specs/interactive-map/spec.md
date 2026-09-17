## ADDED Requirements

### Requirement: Pré-download Leve para Cache em Disco de Mapas de Setor e Carrossel
O sistema DEVE (MUST) disponibilizar o método `ProvedorImagemAresta.preCarregarNoDisco` com propriedades de idempotência, deduplicação e ausência de decodificação de imagem em RAM. O sistema DEVE disparar o pré-download assíncrono em segundo plano das páginas subsequentes de mapas tanto ao renderizar a miniatura do setor (`MapaThumbnail`) quanto ao abrir a visualização em carrossel (`MapasCarrosselPage`), garantindo disponibilidade local e navegação fluida mesmo sem conectividade na rocha.

#### Scenario: Execução de ProvedorImagemAresta.preCarregarNoDisco sem carregar em RAM
- **QUANDO** o método `ProvedorImagemAresta.preCarregarNoDisco` é invocado para uma imagem remota com checksum SHA-256 válido
- **THEN** o sistema baixa os bytes compactados da CDN e grava atomicamente em disco sob `temp_cache`
- **AND** a imagem NÃO DEVE ser decodificada na GPU nem inserida no `ImageCache` da memória RAM
- **AND** o método retorna a referência ao `File` salvo no disco

#### Scenario: Idempotência de pré-download para arquivos já presentes no disco
- **QUANDO** o método `preCarregarNoDisco` for chamado para uma imagem que já exista em `/downloads` ou `/temp_cache`
- **THEN** nenhuma requisição de rede HTTP deve ser realizada
- **AND** o arquivo local existente é retornado imediatamente

#### Scenario: Pré-download das páginas subsequentes ao exibir o Setor
- **QUANDO** o usuário visualiza a página de um setor (`SetorPage`) cujo `MapaThumbnail` possui múltiplos mapas (`mapas.length > 1`)
- **THEN** a miniatura renderiza o primeiro mapa normalmente
- **AND** o sistema agenda em segundo plano o download de todas as páginas subsequentes (índice 1 em diante) para o disco via `preCarregarNoDisco`

#### Scenario: Pré-download complementar de garantia ao abrir o carrossel
- **QUANDO** o usuário abre a visualização em carrossel (`MapasCarrosselPage`)
- **THEN** a página ativa é exibida na tela
- **AND** o sistema aciona em segundo plano a verificação e o pré-download das demais páginas para assegurar que estejam disponíveis em disco mesmo em acessos diretos


