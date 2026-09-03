## Purpose

Fornecer capacidades completas de interpretação vetorial, estilização de traço, desenho acelerado por GPU com highlight dinâmico e marcadores semânticos para linhas de escalada em formato SVG, assegurando isolamento arquitetural rigoroso de dependências externas através de testes automatizados.

## ADDED Requirements

### Requirement: Isolamento Arquitetural da Biblioteca de SVG e Traçados
The system SHALL encapsular todo o acesso a bibliotecas externas de SVG e traçado (como `path_drawing`) estritamente dentro de `lib/utils/trajeto_path_helper.dart`, proibindo importações diretas dessas dependências em qualquer outro componente da aplicação.

#### Scenario: Teste de barreira arquitetural de importações
- **WHEN** a suíte de testes de integridade arquitetural varre todos os arquivos de código-fonte `.dart` em `lib/`
- **THEN** nenhum arquivo fora de `lib/utils/trajeto_path_helper.dart` contém importação para o pacote `package:path_drawing/`

### Requirement: Conversão de Caminhos SVG e Estilização de Traço
The system SHALL converter comandos de caminho SVG em instâncias nativas de `Path` do Flutter e aplicar o estilo de traço configurado (`TRACEJADO`, `SOLIDO`, `PONTILHADO`, `CAMINHADA`).

#### Scenario: Conversão de SVG para caminho contínuo sólido
- **WHEN** o trajeto possui estilo `SOLIDO` e uma string `caminho_svg` válida
- **THEN** o helper retorna um `Path` contínuo reproduzindo fielmente as curvas cúbicas e linhas

#### Scenario: Aplicação de estilo tracejado para rota livre
- **WHEN** o trajeto possui estilo `TRACEJADO`
- **THEN** o helper decompõe o caminho base em intervalos regulares de traço e espaço (ex: 12dp traço / 6dp espaço)

#### Scenario: Resiliência contra dados SVG corrompidos ou vazios
- **WHEN** a string `caminho_svg` é vazia ou inválida
- **THEN** o helper retorna um `Path` vazio sem disparar exceções não tratadas na interface gráfica

### Requirement: Renderização em Camadas com Halo de Highlight
The system SHALL renderizar traçados vetoriais em múltiplas camadas no `MarkerPainter`, incluindo contorno de contraste e um halo difuso (*glow*) de destaque ao redor do SVG quando a via correspondente estiver selecionada.

#### Scenario: Renderização da linha selecionada com halo de highlight
- **WHEN** a linha pertence à via atualmente selecionada (`isSelected == true`)
- **THEN** o pintor renderiza uma camada de fundo com traço largo e desfoque (`MaskFilter.blur`) na cor de destaque
- **THEN** renderiza o traço principal com espessura nominal e opacidade total sobreposta ao halo

#### Scenario: Renderização de linha não selecionada com cor personalizada
- **WHEN** a linha não está selecionada e possui o campo `ponto.cor` preenchido em hexadecimal (ex: `#00E5FF`)
- **THEN** o pintor utiliza a cor hexadecimal informada para desenhar o traçado principal

### Requirement: Pulso de Destaque nas Linhas ao Tocar Fora
The system SHALL desenhar um halo pulsante ao redor de todas as linhas não selecionadas quando o usuário tocar em área livre da tela, utilizando o valor da animação `highlightIntensity`.

#### Scenario: Pulso de linhas clicáveis ao tocar no vazio do mapa
- **WHEN** o usuário toca em uma área não clicável do mapa e a animação de pulso é acionada (`highlightIntensity > 0`)
- **THEN** todas as linhas desenham um halo luminoso suave ao seu redor com largura e opacidade proporcionais a `highlightIntensity`

### Requirement: Renderização de Marcadores Compilados ao Longo do Trajeto
The system SHALL desenhar marcadores pré-posicionados (`MarcadorCompilado`) nas coordenadas indicadas, incluindo círculo identificador na base e símbolos de proteções fixas, paradas e cruxes.

#### Scenario: Exibição de círculo com rótulo na base
- **WHEN** a linha compilada contém um marcador do tipo `INICIO_BASE` com rótulo textual
- **THEN** o pintor renderiza o círculo com o texto do rótulo centralizado na coordenada `(x, y)` do marcador
