## ADDED Requirements

### Requirement: Salvaguarda Visual contra Falhas de Carregamento em Miniaturas e Capas
Os widgets `MapaThumbnail`, bem como as capas de `SetorPage` e `GrupoPage`, MUST fornecer salvaguarda visual defensiva com `errorBuilder` em seus componentes `Image`, prevenindo que falhas assíncronas de rede ou decodificação de imagem resultem na renderização do `ErrorWidget` do Flutter (caixa preta com linhas cruzadas vermelhas e texto cru de `SocketException`). Em caso de falha no carregamento do stream da imagem, o widget DEVE degradar graciosamente para o fundo sólido escuro do tema (`deepBasalt`), mantendo a legibilidade, o botão central de abertura de mapas e os elementos de interface totalmente operacionais.

#### Scenario: Falha de rede durante exibição do thumbnail do mapa
- **WHEN** o `MapaThumbnail` receber um provedor de imagem que falha ao carregar pela rede (offline)
- **THEN** o `errorBuilder` DEVE interceptar o erro silenciosamente
- **AND** renderizar `const SizedBox.shrink()` sobre a camada de fundo sólido do tema
- **AND** o botão de ação (ex: "Mapas Interativos") DEVE permanecer visível e interativo.

#### Scenario: Resolução nula de imagem de mapa quando offline
- **WHEN** o futuro de resolução de imagem retornar `null` devido à ausência de mídia baixada e falta de internet
- **THEN** o `MapaThumbnail` DEVE exibir a camada de fundo sólido (`deepBasalt`) e o botão central de ação sem instanciar o widget `Image`.

#### Scenario: Falha de rede na imagem de capa de setor ou grupo
- **WHEN** a imagem de capa de um setor ou grupo falhar ao carregar via streaming remoto
- **THEN** a tela DEVE manter a cor de fundo do tema e o gradiente escuro de cabeçalho sem exibir caixas de erro do framework.
