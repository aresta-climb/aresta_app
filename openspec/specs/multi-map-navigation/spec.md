## Purpose

Interface e navegação sequencial entre múltiplos mapas interativos no aplicativo.

## Requirements

### Requirement: Qualidade, Cobertura (TDD) e Docstrings
O sistema DEVE ser desenvolvido utilizando Test-Driven Development (TDD), com o código alcançando obrigatoriamente 100% de cobertura nos testes unitários e de widget das lógicas e componentes modificados. O código alterado DEVE ser bem comentado, adotando docstrings descritivas nas classes e métodos.

#### Scenario: Validação de Código e Testes
- **WHEN** as modificações de contexto forem aplicadas nas classes de navegação e carrossel
- **THEN** a suíte de testes deve passar com 100% de coverage nas áreas afetadas.
- **AND** a documentação em docstrings deve estar presente explicando o motivo e a forma de passagem dos contextos geográficos.

### Requirement: Carrossel de Mapas Interativos
O sistema DEVE prover uma interface para navegar de forma sequencial entre múltiplos mapas interativos (`MapasCarrosselPage`), garantindo que o mapa ativo seja trocado apenas via controles explícitos para não conflitar com a navegação do `InteractiveViewer`. O carrossel DEVE instanciar seus mapas explicitamente instruindo-os a não fazer "pop" da navegação ao acionar o botão principal de informações (Mais Info). O sistema DEVE garantir o repasse correto do contexto geográfico (Grupo/Setor) e de objeto (Escalada) de onde o usuário partiu, para que os mapas de destino possam auto-focar na via correta.

#### Scenario: Visualizando a via em múltiplos mapas
- **WHEN** o usuário toca no botão "Ver nos mapas (N)" na tela da Via
- **THEN** a tela de Carrossel de Mapas se abre, focando no primeiro mapa com a rota correspondente focada e animada no centro, utilizando o contexto do Grupo e Setor para localizar a referência correta mesmo em estruturas aninhadas do pico.
- **AND** a barra superior de controle exibe "< 01 de N >".

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
