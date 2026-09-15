## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: Higiene de Memória e Descarte do Cache de Traçados
O aplicativo DEVE (MUST) fornecer rotinas explícitas de descarte de cache através de `ConstrutorCaminhoTrajeto.limparCache()` acionadas em eventos macro do ciclo de vida da aplicação, preservando os caminhos em memória durante toda a navegação interna de um mesmo pico e liberando a memória ao sair ou atualizar dados.

#### Scenario: Limpeza de cache ao sair da tela do pico
- **WHEN** o usuário sai da hierarquia do pico retornando para a tela inicial ou listagem geral de picos
- **THEN** o sistema invoca `ConstrutorCaminhoTrajeto.limparCache()`, liberando todas as instâncias cacheadas de `Path`

#### Scenario: Limpeza de cache ao atualizar ou baixar croqui
- **WHEN** um croqui tem seu download concluído ou é atualizado via sincronização em segundo plano ou Live Reload
- **THEN** o sistema invoca `ConstrutorCaminhoTrajeto.limparCache()`, garantindo que os novos traçados do croqui atualizado sejam recalculados
