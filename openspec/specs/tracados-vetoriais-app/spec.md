## Purpose

Fornecer capacidades completas de interpretação vetorial, estilização de traço, desenho acelerado por GPU com highlight dinâmico e marcadores semânticos para linhas de escalada em formato SVG, assegurando isolamento arquitetural rigoroso de dependências externas através de testes automatizados e aderência aos princípios do repositório.

## Requirements

### Requirement: Isolamento Arquitetural da Biblioteca de SVG e Traçados
O sistema DEVE encapsular todo o acesso a bibliotecas externas de SVG e traçado (como `path_drawing`) estritamente dentro da classe `ConstrutorCaminhoTrajeto` em `lib/utils/construtor_caminho_trajeto.dart`, proibindo importações diretas dessas dependências em qualquer outro componente da aplicação.

#### Scenario: Teste de barreira arquitetural de importações
- **WHEN** a suíte de testes de integridade arquitetural varre todos os arquivos de código-fonte `.dart` em `lib/`
- **THEN** nenhum arquivo fora de `lib/utils/construtor_caminho_trajeto.dart` contém importação para o pacote `package:path_drawing/`

### Requirement: Conversão de Caminhos SVG e Estilização de Traço
O `ConstrutorCaminhoTrajeto` DEVE converter comandos de caminho SVG em instâncias nativas de `Path` do Flutter e aplicar o estilo de traço configurado (`TRACEJADO`, `SOLIDO`, `PONTILHADO`, `CAMINHADA`) diretamente com proporções adequadas para tela através do método `aplicarEstiloNoViewport`, mantendo cache em memória para prevenir alocações excessivas a cada quadro de animação.

#### Scenario: Conversão de SVG para caminho contínuo sólido
- **WHEN** o trajeto possui estilo `SOLIDO` e uma string `caminho_svg` válida
- **THEN** o construtor retorna um `Path` contínuo reproduzindo fielmente as curvas cúbicas e retas

#### Scenario: Aplicação de estilo tracejado no espaço do viewport
- **WHEN** o trajeto possui estilo `TRACEJADO`
- **THEN** o construtor aplica intervalos nítidos e visíveis de traço e espaço diretamente escalados para a tela (8.0dp traço / 4.0dp espaço) sem que os vãos se percam na transformação

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
- **THEN** o pintor renderiza o traço com espessura proporcional escalada pelas dimensões da imagem na tela (clamp entre 2.0 e 4.0dp)
- **THEN** renderiza o halo difuso com largura proporcional moderada (`espessuraVisual + 6.0dp`) sobreposta à camada de casing

#### Scenario: Renderização de linha não selecionada com cor personalizada
- **WHEN** a linha não está selecionada e possui o campo `ponto.cor` preenchido em hexadecimal (ex: `#00E5FF`)
- **THEN** o pintor utiliza a cor hexadecimal informada para desenhar o traçado principal com espessura fina proporcional

### Requirement: Pulso de Destaque nas Linhas ao Tocar Fora
O `MarkerPainter` DEVE desenhar um halo pulsante ao redor de todas as linhas não selecionadas quando o usuário tocar em área livre da tela, utilizando o valor da animação `highlightIntensity`.

#### Scenario: Pulso de linhas clicáveis ao tocar no vazio do mapa
- **WHEN** o usuário toca em uma área não clicável do mapa e a animação de pulso é acionada (`highlightIntensity > 0`)
- **THEN** todas as linhas desenham um halo luminoso suave ao seu redor com largura e opacidade proporcionais a `highlightIntensity`

### Requirement: Renderização de Marcadores Compilados ao Longo do Trajeto
O `MarkerPainter` DEVE desenhar marcadores pré-posicionados (`MarcadorCompilado`) com fidelidade cromática 1:1 ao editor de mapas desktop, utilizando fundo preenchido na cor da via, texto em branco em negrito, contorno duplo e dimensionamento adaptativo proporcional ao viewport.

#### Scenario: Exibição de círculo identificador com estilo do editor
- **WHEN** a linha compilada contém um marcador do tipo `CIRCULO_IDENTIFICADOR` com rótulo textual
- **THEN** o pintor renderiza o círculo com fundo preenchido na cor da via (`corLinha`), borda interna branca, casing externo escuro e o texto do rótulo em branco centralizado
- **THEN** o raio do círculo respeita a proporção da imagem na tela dentro de um intervalo ergonômico confortável (11.0 a 15.0dp)
