## ADDED Requirements

### Requirement: Renderização Imediata e Não-Bloqueante do Botão de Mapa no Setor
O componente de miniatura de mapa no setor SHALL renderizar imediatamente no primeiro frame o container com a proporção exata (`larguraMapa / alturaMapa`) e o botão de abertura do mapa interativo, permitindo toque e navegação instantânea para a tela cheia do mapa sem aguardar o download ou decodificação da imagem de fundo.

#### Scenario: Visualização do setor com mapa enquanto a imagem está baixando
- **WHEN** o usuário acessa um setor que possui mapas em um croqui online
- **AND** a imagem do mapa ainda não foi baixada ou está em processo de resolução
- **THEN** o card do mapa exibe imediatamente um container estilizado com cantos arredondados na proporção correta
- **AND** o botão "Abrir Mapa Interativo" é renderizado centralizado e habilitado para toque no primeiro frame
- **AND** o término do download da miniatura exibe a imagem em segundo plano com transição suave (fade-in) sem reconstruir ou piscar o botão

#### Scenario: Toque no botão de mapa antes do término do download da miniatura
- **WHEN** o usuário toca no botão "Abrir Mapa Interativo" no setor
- **AND** a miniatura do mapa ainda não completou seu download
- **THEN** o sistema aciona a navegação para a tela de mapas (`toMapas`) imediatamente sem reter o usuário no setor

### Requirement: Montagem Estrutural Imediata e Revelação Atômica no Mapa Interativo
A página do mapa interativo SHALL montar imediatamente sua estrutura visual (Scaffold, AppBar com título e controles de navegação, e tela de visualização com fundo escuro) no primeiro frame, mantendo um indicador de carregamento sutil enquanto a imagem em alta resolução é obtida, e revelando a imagem junto com os marcadores e traçados vetoriais de forma atômica e coordenada.

#### Scenario: Abertura da tela cheia do mapa interativo online
- **WHEN** a tela do mapa interativo é aberta e a imagem correspondente ainda está sendo obtida pela rede ou disco
- **AND** o modo headless não está ativo
- **THEN** a barra superior (AppBar) com botão de retorno e identificação do mapa/setor é exibida instantaneamente
- **AND** o canvas do mapa exibe um fundo escuro com indicador de carregamento centralizado
- **AND** os marcadores (POIs) e traçados vetoriais permanecem ocultos até que a imagem esteja pronta para exibição

#### Scenario: Revelação coordenada ao concluir o carregamento da imagem
- **WHEN** o carregamento e decodificação da imagem do mapa são concluídos
- **THEN** a imagem da rocha, os marcadores de interesse (POIs) e os traçados vetoriais são exibidos simultaneamente com transição suave de fade-in
- **AND** os controles de interação (zoom, pan, duplo toque) tornam-se plenamente operacionais
