## ADDED Requirements

### Requirement: Exibição da Hierarquia Geográfica e Salto para o Croqui do Setor
O aplicativo SHALL exibir na página de detalhes da escalada (`ViaPage`) a localização geográfica completa da via informando o Grupo (quando houver) e o Setor ao qual ela pertence (ex: `Grupo > Setor`), com indicação visual evidente de que o elemento é acionável para navegar diretamente ao croqui do respectivo setor com foco na escalada.

#### Scenario: Visualização de via pertencente a setor dentro de grupo
- **WHEN** o usuário visualiza os detalhes de uma via cujo setor pertence a um grupo
- **THEN** o cabeçalho/área de contexto exibe o nome do Grupo e do Setor correspondentes
- **AND** acionar esse componente navega diretamente para a visualização do Setor correspondente destacando a via

#### Scenario: Visualização de via pertencente a setor direto no pico
- **WHEN** o usuário visualiza os detalhes de uma via cujo setor está na raiz do pico (sem grupo intermediário)
- **THEN** o componente exibe o nome do Setor com botão explícito de visualização no croqui

### Requirement: Padronização da Terminologia Multienfiada
O aplicativo SHALL utilizar consistentemente o termo "Multienfiada" em todos os rótulos de interface, badges informativos e listagens para identificar vias de múltiplas enfiadas.

#### Scenario: Exibição da modalidade multienfiada na interface
- **WHEN** uma via for do tipo ViaMultiplasEnfiadas
- **THEN** os rótulos e badges da interface devem apresentar "Multienfiada"
