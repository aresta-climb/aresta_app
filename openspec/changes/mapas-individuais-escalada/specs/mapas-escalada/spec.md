## Purpose

Permite que vias de escalada, boulders e multienfiadas possuam mapas interativos dedicados e autocontidos para detalhar saídas, agarras de partida e lances técnicos com alta fidelidade e peso otimizado.

## ADDED Requirements

### Requirement: Exibição de MapaThumbnail Rico na Página da Escalada
O aplicativo SHALL renderizar o componente visual `MapaThumbnail` no corpo da `ViaPage` caso a escalada em exibição possua um ou mais mapas individuais cadastrados em seu campo `mapas`, substituindo o botão textual genérico.

#### Scenario: Escalada com mapas próprios
- **WHEN** o usuário abre a página de detalhes de uma escalada que possui um ou mais mapas próprios em `escalada.mapas`
- **THEN** o aplicativo renderiza o card visual `MapaThumbnail` com pré-visualização da primeira imagem e indicação da contagem de mapas
- **AND** nenhum botão textual plano "VER NO CROQUI INTERATIVO" é exibido

#### Scenario: Escalada sem mapas próprios mas referenciada no setor
- **WHEN** o usuário abre a página de uma escalada que não possui mapas próprios (`escalada.mapas.isEmpty`), mas ela está desenhada no mapa do setor
- **THEN** o aplicativo mantém a exibição do botão interativo direcionado para o mapa do setor onde a rota está desenhada

### Requirement: Carrossel Unificado de Mapas na Escalada
Ao acionar a visualização de mapas a partir de uma escalada que possui mapas próprios, o aplicativo SHALL abrir um carrossel unificado (`MapasCarrosselNode`) contendo primeiramente os mapas locais da própria escalada, seguidos pelos mapas hierárquicos (setor, grupo ou pico) onde a escalada é referenciada.

#### Scenario: Abertura do carrossel a partir de escalada com mapas próprios e de setor
- **WHEN** o usuário toca no `MapaThumbnail` da escalada
- **THEN** o carrossel de mapas é aberto na primeira página exibindo o mapa de detalhe da escalada
- **AND** as páginas subsequentes contêm os demais mapas da escalada e, por fim, os mapas do setor em que a via se encontra, com a rota pré-focada

### Requirement: Ação Secundária Ver Mapas no Mapa Interativo
No mapa interativo do setor (`mapa_interativo.dart`), ao selecionar uma escalada que possui mapas próprios em `mapas`, o painel inferior de ações SHALL exibir a ação secundária "Ver mapas" para permitir navegação direta aos mapas da escalada.

#### Scenario: Seleção de rota com mapa próprio no mapa do setor
- **WHEN** o usuário clica sobre o marcador ou traçado de uma escalada no mapa do setor
- **AND** a escalada possui itens em seu campo `mapas`
- **THEN** a barra inferior de ações exibe o botão secundário com rótulo "Ver mapas"
- **AND** ao clicar no botão, o aplicativo navega diretamente para os mapas individuais daquela escalada
