## Purpose

Fornecer capacidades completas de interpretação vetorial, estilização de traço, desenho acelerado por GPU com highlight dinâmico e marcadores semânticos para linhas de escalada em formato SVG, assegurando isolamento arquitetural rigoroso de dependências externas através de testes automatizados e aderência aos princípios do repositório.

## Requirements

### Requirement: Isolamento Arquitetural da Biblioteca de SVG e Traçados
O sistema DEVE encapsular todo o acesso a bibliotecas externas de SVG e traçado (como `path_drawing`) estritamente dentro da classe `ConstrutorCaminhoTrajeto` em `lib/utils/construtor_caminho_trajeto.dart`, proibindo importações diretas dessas dependências em qualquer outro componente da aplicação.

#### Scenario: Teste de barreira arquitetural de importações
- **WHEN** a suíte de testes de integridade arquitetural varre todos os arquivos de código-fonte `.dart` em `lib/`
- **THEN** nenhum arquivo fora de `lib/utils/construtor_caminho_trajeto.dart` contém importação para o pacote `package:path_drawing/`

### Requirement: Conversão de Caminhos SVG e Estilização de Traço
O `ConstrutorCaminhoTrajeto` DEVE (MUST) converter comandos de caminho SVG em instâncias nativas de `Path` do Flutter e aplicar o estilo de traço configurado (`TRACEJADO`, `SOLIDO`, `PONTILHADO`, `CAMINHADA`) diretamente com proporções adequadas para tela através do método `aplicarEstiloNoViewport`, mantendo cache em memória indexado por chave canônica composta no formato `${mapa.caminhoImagemMapa}#${ponto.id}` para prevenir alocações excessivas a cada quadro de animação e impedir colisões entre mapas distintos, sem fallbacks ambíguos para IDs isolados.

#### Scenario: Conversão de SVG para caminho contínuo sólido
- **WHEN** o trajeto possui estilo `SOLIDO` e uma string `caminho_svg` válida
- **THEN** o construtor retorna um `Path` contínuo reproduzindo fielmente as curvas cúbicas e retas

#### Scenario: Aplicação de estilo tracejado no espaço do viewport
- **WHEN** o trajeto possui estilo `TRACEJADO`
- **THEN** o construtor aplica intervalos nítidos e visíveis de traço e espaço diretamente escalados para a tela (8.0dp traço / 4.0dp espaço) sem que os vãos se percam na transformação

#### Scenario: Reutilização via cache de memória
- **WHEN** o construtor é solicitado a gerar o caminho para uma mesma chave canônica composta (`caminhoImagemMapa#ponto.id`) e estilo já computados anteriormente
- **THEN** o construtor retorna a instância de `Path` já cacheada sem reprocessar a string SVG

#### Scenario: Isolamento determinístico entre mapas com mesmo ID local
- **WHEN** dois mapas distintos possuem elementos com o mesmo identificador local (ex: `linha_1`)
- **THEN** as chaves compostas resultantes (`mapa1#linha_1` e `mapa2#linha_1`) são diferentes e o construtor gera e armazena caminhos independentes sem contaminação mútua

#### Scenario: Resiliência contra dados SVG corrompidos ou vazios
- **WHEN** a string `caminho_svg` for vazia ou sintaticamente inválida
- **THEN** o construtor retorna um `Path` vazio sem propagar exceções para a interface gráfica

### Requirement: Renderização em Camadas com Halo de Highlight
O `MarkerPainter` DEVE (MUST) renderizar traçados vetoriais em múltiplas camadas de profundidade com espessura estritamente proporcional à escala da imagem no viewport (`espessura * escalaX`), incluindo contorno de contraste e halo difuso (*glow*) de destaque de largura moderada ao redor do SVG quando a via correspondente estiver selecionada, sem a aplicação de multiplicadores arbitrários ou clamps visuais artificiais.

#### Scenario: Renderização da linha selecionada com espessura proporcional
- **WHEN** a linha pertence à via atualmente selecionada (`isSelected == true`)
- **THEN** o pintor renderiza o traço com espessura proporcional calculada como `espessura * escalaX` a partir dos pixels nominais da imagem, sem aplicação de multiplicador de expansão ou clamp mínimo visual
- **THEN** renderiza o halo difuso com largura proporcional moderada (`espessuraVisual + 6.0dp`) sobreposta à camada de casing

#### Scenario: Renderização de linha não selecionada com cor personalizada
- **WHEN** a linha não está selecionada e possui o campo `ponto.cor` preenchido em hexadecimal (ex: `#00E5FF`)
- **THEN** o pintor utiliza a cor hexadecimal informada para desenhar o traçado principal com espessura proporcional estrita (`espessura * escalaX`)

### Requirement: Pulso de Destaque nas Linhas ao Tocar Fora
O `MarkerPainter` DEVE desenhar um halo pulsante ao redor de todas as linhas não selecionadas quando o usuário tocar em área livre da tela, utilizando o valor da animação `highlightIntensity`.

#### Scenario: Pulso de linhas clicáveis ao tocar no vazio do mapa
- **WHEN** o usuário toca em uma área não clicável do mapa e a animação de pulso é acionada (`highlightIntensity > 0`)
- **THEN** todas as linhas desenham um halo luminoso suave ao seu redor com largura e opacidade proporcionais a `highlightIntensity`

### Requirement: Renderização de Marcadores Compilados ao Longo do Trajeto
O `MarkerPainter` DEVE (MUST) desenhar marcadores pré-posicionados (`MarcadorCompilado`) com fidelidade cromática e geométrica 1:1 ao editor de mapas desktop, utilizando fundo preenchido na cor da via, texto em branco em negrito, contorno duplo e dimensionamento estritamente proporcional aos pixels da imagem (`raio * escalaX` e `tamanhoFonte * escalaX`), sem clamps visuais inflados.

#### Scenario: Exibição de círculo identificador com estilo do editor
- **WHEN** a linha compilada contém um marcador do tipo `CIRCULO_IDENTIFICADOR` com rótulo textual
- **THEN** o pintor renderiza o círculo com fundo preenchido na cor da via (`corLinha`), borda interna branca, casing externo escuro e o texto do rótulo em branco centralizado
- **THEN** o raio do círculo respeita estritamente a proporção geométrica da imagem na tela (`raio * escalaX`), sem limite mínimo artificial de clamp visual

### Requirement: Hitbox Ergonômica Adaptativa ao Tamanho em Tela
O `MarkerPainter` DEVE (MUST) desacoplar a dimensão visual desenhada da área de toque no método `hitTest`, assegurando uma área de toque mínima ergonômica em pontos lógicos de tela (raio mínimo de 22.0 dp para marcadores/pontos e 16.0 dp para linhas) no estado panorâmico, reduzindo a tolerância extra de forma contínua conforme o elemento visual cresce na tela com o zoom, até colapsar a tolerância extra para zero quando a dimensão visual na tela atingir ou superar o tamanho ergonômico mínimo.

#### Scenario: Toque facilitado com tolerância ergonômica no panorama geral
- **WHEN** o usuário toca no mapa com zoom 1.0x onde o elemento visual ocupa menos que o raio ergonômico mínimo em tela
- **THEN** o `hitTest` infla dinamicamente a distância de tolerância necessária para garantir a área de toque mínima confortável para o dedo humano na tela

#### Scenario: Toque com precisão milimétrica ao aproximar o zoom
- **WHEN** o usuário aproxima o zoom na rocha e a dimensão visual do traçado ou marcador na tela atinge ou ultrapassa o tamanho ergonômico mínimo
- **THEN** a tolerância extra colapsa para zero e o `hitTest` restringe-se cirurgicamente à geometria visual exata do elemento original

### Requirement: Higiene de Memória e Descarte do Cache de Traçados
O aplicativo DEVE (MUST) fornecer rotinas explícitas de descarte de cache através de `ConstrutorCaminhoTrajeto.limparCache()` acionadas em eventos macro do ciclo de vida da aplicação, preservando os caminhos em memória durante toda a navegação interna de um mesmo pico e liberando a memória ao sair ou atualizar dados.

#### Scenario: Limpeza de cache ao sair da tela do pico
- **WHEN** o usuário sai da hierarquia do pico retornando para a tela inicial ou listagem geral de picos
- **THEN** o sistema invoca `ConstrutorCaminhoTrajeto.limparCache()`, liberando todas as instâncias cacheadas de `Path`

#### Scenario: Limpeza de cache ao atualizar ou baixar croqui
- **WHEN** um croqui tem seu download concluído ou é atualizado via sincronização em segundo plano ou Live Reload
- **THEN** o sistema invoca `ConstrutorCaminhoTrajeto.limparCache()`, garantindo que os novos traçados do croqui atualizado sejam recalculados
