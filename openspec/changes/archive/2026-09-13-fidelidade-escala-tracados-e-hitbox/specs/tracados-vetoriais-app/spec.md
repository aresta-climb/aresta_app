## MODIFIED Requirements

### Requirement: Renderização em Camadas com Halo de Highlight
O `MarkerPainter` DEVE (MUST) renderizar traçados vetoriais em múltiplas camadas de profundidade com espessura estritamente proporcional à escala da imagem no viewport (`espessura * escalaX`), incluindo contorno de contraste e halo difuso (*glow*) de destaque de largura moderada ao redor do SVG quando a via correspondente estiver selecionada, sem a aplicação de multiplicadores arbitrários ou clamps visuais artificiais.

#### Scenario: Renderização da linha selecionada com espessura proporcional
- **WHEN** a linha pertence à via atualmente selecionada (`isSelected == true`)
- **THEN** o pintor renderiza o traço com espessura proporcional calculada como `espessura * escalaX` a partir dos pixels nominais da imagem, sem aplicação de multiplicador de expansão ou clamp mínimo visual
- **THEN** renderiza o halo difuso com largura proporcional moderada (`espessuraVisual + 6.0dp`) sobreposta à camada de casing

#### Scenario: Renderização de linha não selecionada com cor personalizada
- **WHEN** a linha não está selecionada e possui o campo `ponto.cor` preenchido em hexadecimal (ex: `#00E5FF`)
- **THEN** o pintor utiliza a cor hexadecimal informada para desenhar o traçado principal com espessura proporcional estrita (`espessura * escalaX`)

### Requirement: Renderização de Marcadores Compilados ao Longo do Trajeto
O `MarkerPainter` DEVE (MUST) desenhar marcadores pré-posicionados (`MarcadorCompilado`) com fidelidade cromática e geométrica 1:1 ao editor de mapas desktop, utilizando fundo preenchido na cor da via, texto em branco em negrito, contorno duplo e dimensionamento estritamente proporcional aos pixels da imagem (`raio * escalaX` e `tamanhoFonte * escalaX`), sem clamps visuais inflados.

#### Scenario: Exibição de círculo identificador com estilo do editor
- **WHEN** a linha compilada contém um marcador do tipo `CIRCULO_IDENTIFICADOR` com rótulo textual
- **THEN** o pintor renderiza o círculo com fundo preenchido na cor da via (`corLinha`), borda interna branca, casing externo escuro e o texto do rótulo em branco centralizado
- **THEN** o raio do círculo respeita estritamente a proporção geométrica da imagem na tela (`raio * escalaX`), sem limite mínimo artificial de clamp visual

## ADDED Requirements

### Requirement: Hitbox Ergonômica Adaptativa ao Tamanho em Tela
O `MarkerPainter` DEVE (MUST) desacoplar a dimensão visual desenhada da área de toque no método `hitTest`, assegurando uma área de toque mínima ergonômica em pontos lógicos de tela (raio mínimo de 22.0 dp para marcadores/pontos e 16.0 dp para linhas) no estado panorâmico, reduzindo a tolerância extra de forma contínua conforme o elemento visual cresce na tela com o zoom, até colapsar a tolerância extra para zero quando a dimensão visual na tela atingir ou superar o tamanho ergonômico mínimo.

#### Scenario: Toque facilitado com tolerância ergonômica no panorama geral
- **WHEN** o usuário toca no mapa com zoom 1.0x onde o elemento visual ocupa menos que o raio ergonômico mínimo em tela
- **THEN** o `hitTest` infla dinamicamente a distância de tolerância necessária para garantir a área de toque mínima confortável para o dedo humano na tela

#### Scenario: Toque com precisão milimétrica ao aproximar o zoom
- **WHEN** o usuário aproxima o zoom na rocha e a dimensão visual do traçado ou marcador na tela atinge ou ultrapassa o tamanho ergonômico mínimo
- **THEN** a tolerância extra colapsa para zero e o `hitTest` restringe-se cirurgicamente à geometria visual exata do elemento original
