## ADDED Requirements

### Requirement: Renderização Incondicional de Traçados Vetoriais no Mapa
O `MapaInterativoPage` DEVE renderizar visualmente no mapa todos os pontos de interesse do tipo `linha`, independentemente de eles possuírem ou não uma entidade associada na lista `mapa.referencias`.

#### Scenario: Linha sem referência associada presente no croqui
- **WHEN** o croqui contém um ponto de interesse com geometria do tipo `linha` que não possui entrada correspondente em `mapa.referencias`
- **THEN** o componente não descarta o marcador com `SizedBox.shrink()`
- **THEN** o marcador é desenhado na rocha com seu traçado vetorial, estilo e marcadores correspondentes

#### Scenario: Toque em linha sem referência associada
- **WHEN** o usuário toca sobre uma linha vetorial que não possui referência cadastrada
- **THEN** a linha é selecionada visualmente (`isSelected == true`)
- **THEN** o sistema aplica o enquadramento de auto-zoom para a caixa delimitadora da linha
