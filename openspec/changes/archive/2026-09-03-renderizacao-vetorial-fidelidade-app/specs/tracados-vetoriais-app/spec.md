## MODIFIED Requirements

### Requirement: Conversão de Caminhos SVG e Estilização de Traço
O `ConstrutorCaminhoTrajeto` DEVE converter comandos de caminho SVG em instâncias nativas de `Path` do Flutter e aplicar o estilo de traço configurado (`TRACEJADO`, `SOLIDO`, `PONTILHADO`, `CAMINHADA`) diretamente com proporções adequadas para tela, mantendo cache em memória para prevenir alocações excessivas a cada quadro de animação.

#### Scenario: Conversão de SVG para caminho contínuo sólido
- **WHEN** o trajeto possui estilo `SOLIDO` e uma string `caminho_svg` válida
- **THEN** o construtor retorna um `Path` contínuo reproduzindo fielmente as curvas cúbicas e retas

#### Scenario: Aplicação de estilo tracejado no espaço do viewport
- **WHEN** o trajeto possui estilo `TRACEJADO`
- **THEN** o construtor aplica intervalos nítidos e visíveis de traço e espaço diretamente escalados para a tela (ex: 8.0dp traço / 4.0dp espaço) sem que os vãos se percam na transformação

#### Scenario: Reutilização via cache de memória
- **WHEN** o construtor é solicitado a gerar o caminho para um mesmo ID de ponto e estilo já computados anteriormente
- **THEN** o construtor retorna a instância de `Path` já cacheada sem reprocessar a string SVG

#### Scenario: Resiliência contra dados SVG corrompidos ou vazios
- **WHEN** a string `caminho_svg` for vazia ou sintaticamente inválida
- **THEN** o construtor retorna um `Path` vazio sem propagar exceções para a interface gráfica

### Requirement: Renderização em Camadas com Halo de Highlight
O `MarkerPainter` DEVE renderizar traçados vetoriais em múltiplas camadas de profundidade com espessura proporcional à escala da imagem no viewport, incluindo contorno de contraste e halo difuso (*glow*) de destaque de largura moderada ao redor do SVG quando a via correspondente estiver selecionada.

#### Scenario: Renderização da linha selecionada com espessura proporcional
- **WHEN** a linha pertence à via atualmente selecionada (`isSelected == true`)
- **THEN** o pintor renderiza o traço com espessura proporcional escalada pelas dimensões da imagem na tela (clamp entre 2.0 e 4.5dp)
- **THEN** renderiza o halo difuso com largura proporcional moderada sobreposta à camada de casing

#### Scenario: Renderização de linha não selecionada com cor personalizada
- **WHEN** a linha não está selecionada e possui o campo `ponto.cor` preenchido em hexadecimal (ex: `#00E5FF`)
- **THEN** o pintor utiliza a cor hexadecimal informada para desenhar o traçado principal com espessura fina proporcional

### Requirement: Renderização de Marcadores Compilados ao Longo do Trajeto
O `MarkerPainter` DEVE desenhar marcadores pré-posicionados (`MarcadorCompilado`) com fidelidade cromática 1:1 ao editor de mapas desktop, utilizando fundo preenchido na cor da via, texto em branco em negrito, contorno duplo e dimensionamento adaptativo proporcional ao viewport.

#### Scenario: Exibição de círculo identificador com estilo do editor
- **WHEN** a linha compilada contém um marcador do tipo `CIRCULO_IDENTIFICADOR` com rótulo textual
- **THEN** o pintor renderiza o círculo com fundo preenchido na cor da via (`corLinha`), borda interna branca, casing externo escuro e o texto do rótulo em branco centralizado
- **THEN** o raio do círculo respeita a proporção da imagem na tela dentro de um intervalo ergonômico confortável (11.0 a 15.0dp)
