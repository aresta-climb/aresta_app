# map-hierarchy-navigation Specification

## Purpose
TBD - created by archiving change mapa-interativo-up-navigation. Update Purpose after archive.
## Requirements
### Requirement: Botão de Navegação Hierárquica "Subir" (Up) no Mapa
O mapa interativo MUST prover um botão de navegação hierárquica "Subir" quando houver um mapa de nível superior disponível na estrutura do pico.

#### Scenario: Mapa de setor com um grupo pai
- **WHEN** o usuário visualiza o mapa de um Setor e esse setor pertence a um Grupo que possui mapas
- **THEN** o sistema exibe um botão para subir para o mapa do Grupo
- **THEN** o texto do botão indica o destino dinamicamente (ex: `^ Grupo Oculto`)

#### Scenario: Mapa de setor sem grupo pai, ou Mapa de grupo
- **WHEN** o usuário visualiza o mapa de um Grupo, ou de um Setor que não tem Grupo pai
- **THEN** o sistema verifica se o Pico possui mapas gerais (`mapasGerais`)
- **THEN** se um mapa geral existir, o sistema exibe o botão para subir para o Mapa Geral (ex: `^ Mapa Geral`)

#### Scenario: Nenhum mapa de nível superior disponível
- **WHEN** o usuário está visualizando o mapa geral do Pico, ou não existem mapas de nível superior cadastrados
- **THEN** o botão de navegação "Subir" NÃO DEVE ser exibido

#### Scenario: Restrições de Exibição na Interface
- **WHEN** o botão de navegação "Subir" é exibido
- **THEN** o texto DEVE ser truncado com reticências (ellipsis) caso exceda a largura máxima segura, prevenindo obstrução da interface do mapa interativo

#### Scenario: Empilhamento de Navegação (Navigation Stack)
- **WHEN** o usuário toca no botão de navegação "Subir"
- **THEN** o sistema DEVE empurrar (push) um novo nó de mapa interativo na pilha de navegação
- **THEN** o usuário pode utilizar o botão "Voltar" (Back) do sistema para retornar exatamente ao mapa anterior

### Requirement: Telemetria de Navegação Hierárquica no Mapa
O sistema MUST disparar um evento de telemetria específico quando o usuário utilizar o botão de subir nível hierárquico no mapa.

#### Scenario: Subida de Nível Registrada
- **WHEN** o usuário toca no botão de navegação "Subir"
- **THEN** o sistema dispara o evento `logNavegacaoHierarquica` contendo o ID do pico/croqui e o rótulo do destino
