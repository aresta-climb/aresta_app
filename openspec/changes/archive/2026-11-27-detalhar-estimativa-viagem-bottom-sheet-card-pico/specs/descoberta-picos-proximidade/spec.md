## REMOVED Requirements

### Requirement: Tooltip Explicativo de Estimativa Sem Trânsito com Tempo e Quilometragem
**Reason**: O `Tooltip` padrão exigia segurar o toque (`longPress`) no celular, não possuía indicador visual de interatividade e fazia toques simples abrirem o croqui acidentalmente.
**Migration**: Substituído pelo badge clicável com ícone `ⓘ` e abertura do Mini Bottom Sheet explicativo (`FolhaEstimativaViagemPico`).

## ADDED Requirements

### Requirement: Badge Clicável com Ícone Informativo e Mini Bottom Sheet Explicativo de Viagem
Nos cards de picos que possuem estimativa de tempo pela malha local, o badge de proximidade DEVE (MUST) exibir um ícone informativo `ⓘ` ao lado do tempo arredondado e interceptar o toque simples (`onTap`) sem disparar a abertura ou download do croqui, abrindo um Mini Bottom Sheet explicativo contendo o título do pico, o tempo médio estimado em fluxo normal, a distância estimada por estrada em quilômetros e o aviso de que o cálculo é realizado offline pela malha do OpenStreetMap sem trânsito em tempo real.

#### Scenario: Toque simples no badge de tempo abre o Mini Bottom Sheet sem abrir o croqui
- **WHEN** o usuário toca no badge de tempo (`~1h` com ícone `ⓘ`) de um card de pico com distância por estrada de `54.1 km`
- **THEN** o callback de abertura/download do card NÃO é acionado e o aplicativo exibe um Mini Bottom Sheet apresentando o tempo médio estimado (`~1h`), a distância por estrada (`54.1 km`) e a explicação sobre o cálculo offline sem trânsito em tempo real.

#### Scenario: Badge apenas com quilometragem não exibe ícone informativo nem intercepta abertura do card
- **WHEN** o pico está fora da malha local de tempo e exibe apenas quilometragem no badge (ex.: `425.0 km`)
- **THEN** o badge é renderizado sem o ícone `ⓘ` e tocar sobre o card ou sobre o badge executa normalmente a ação do card.
