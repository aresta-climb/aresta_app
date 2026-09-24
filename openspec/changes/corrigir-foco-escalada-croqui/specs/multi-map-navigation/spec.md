## MODIFIED Requirements

### Requirement: Carrossel de Mapas Interativos
O sistema DEVE prover uma interface para navegar de forma sequencial entre múltiplos mapas interativos (`MapasCarrosselPage`), garantindo que o mapa ativo seja trocado apenas via controles explícitos para não conflitar com a navegação do `InteractiveViewer`. O carrossel DEVE instanciar seus mapas explicitamente instruindo-os a não fazer "pop" da navegação ao acionar o botão principal de informações (Mais Info). O sistema DEVE garantir o repasse correto do contexto geográfico (Grupo/Setor) e de objeto (`escaladaContextNome`) de onde o usuário partiu, para que os mapas de destino possam auto-focar e selecionar a via correta mesmo quando múltiplos itens compartilham o mesmo Ponto de Interesse (POI). O mapa DEVE sincronizar a seleção e a câmera reativamente se a via selecionada mudar mantendo a mesma imagem de fundo, sem descarregar nem recarregar a textura da imagem na memória.

#### Scenario: Visualizando a via em múltiplos mapas
- **WHEN** o usuário toca no botão "Ver nos mapas (N)" na tela da Via
- **THEN** a tela de Carrossel de Mapas se abre, focando no primeiro mapa com a rota correspondente focada e animada no centro, utilizando o contexto do Grupo e Setor para localizar a referência correta mesmo em estruturas aninhadas do pico.
- **AND** a barra superior de controle exibe "< 01 de N >".

#### Scenario: Foco em via secundária ou terciária com POI compartilhado
- **WHEN** o usuário clica em "VER NO CROQUI INTERATIVO" a partir de uma via ou boulder que não é o primeiro item indexado naquele marcador (compartilha o mesmo POI com outras vias)
- **THEN** o carrossel de mapas repassa `escaladaContextNome` para o mapa interativo.
- **AND** o mapa foca o marcador correspondente e posiciona o carrossel de abas do cartão flutuante diretamente no índice da via selecionada pelo usuário (e não na primeira via do POI).
- **AND** o auto-zoom enquadra os pontos/traçado da via selecionada.

#### Scenario: Trocando de via na mesma imagem de fundo
- **WHEN** o usuário navega para uma nova via que está mapeada na mesma imagem de fundo do mapa atualmente renderizado
- **THEN** o mapa interativo detecta a mudança de seleção via `didUpdateWidget`.
- **AND** a textura/imagem de fundo é preservada sem recarregar ou piscar a tela.
- **AND** o POI selecionado, a aba da via no cartão flutuante e a câmera animam suavemente para a nova via.

#### Scenario: Reconstrução sem mudança de seleção
- **WHEN** o mapa interativo é reconstruído por mudanças no widget pai sem que `initialSelectedId` ou `escaladaContextNome` tenham sido alterados
- **THEN** o mapa não executa animação de translação nem alteração de zoom, preservando integralmente o pan e zoom ajustados pelo usuário.

#### Scenario: Trocando de mapa no carrossel
- **WHEN** o usuário toca no botão ">" na barra superior
- **THEN** o mapa ativo muda para o próximo mapa do carrossel.
- **AND** o novo mapa automaticamente executa o autozoom para focar e destacar a exata rota referenciada, correspondendo ao seu `referencedId` e `escaladaContextNome` específico daquele mapa, prevenindo a seleção de outras rotas que compartilhem o mesmo marcador visual (SVG).

#### Scenario: Várias vias no mesmo mapa durante a navegação
- **WHEN** o usuário está num carrossel focado na Rota A, mas toca no SVG da Rota B no mesmo mapa
- **THEN** o cartão flutuante da Rota B aparece no rodapé normalmente.
- **AND** o carrossel continua gerindo as configurações da Rota A no topo da tela, mas se a Rota B possui múltiplos mapas, um botão extra surge no cartão flutuante para "Ver nos mapas".

#### Scenario: Acessando Detalhes da Via através do Carrossel
- **WHEN** o usuário toca no botão "Mais Info" no cartão flutuante de uma rota exibida dentro do carrossel, mesmo que seja a rota originalmente focada ao abrir a tela
- **THEN** o sistema DEVE abrir a tela de Detalhes da Via (PUSH) em vez de fechar o carrossel (POP).
