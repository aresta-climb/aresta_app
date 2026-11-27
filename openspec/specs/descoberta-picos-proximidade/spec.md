# descoberta-picos-proximidade Specification

## Purpose
Define o contrato de comportamento para descoberta de picos de escalada por proximidade geográfica no carrossel da página inicial e no catálogo da aba Explorar, assegurando consistência de ordenação por distância, exibição de quilometragem e transição contínua entre as telas.

## Requirements

### Requirement: Exibição Linear dos Top 6 Picos no Carrossel da Home
O carrossel de picos próximos na página inicial DEVE (MUST) exibir no máximo os 6 picos mais próximos da localização do usuário ordenados em duas faixas — primeiro os picos alcançáveis pela malha local ($\le 200\text{ km}$) em ordem crescente de tempo estimado de viagem sem trânsito, seguidos pelos demais picos em ordem crescente de distância estimada em quilômetros — sem repetição circular (sem loop infinito).

#### Scenario: Catálogo possui 6 ou menos picos com localização
- **WHEN** o usuário possui localização disponível e o catálogo contém até 6 picos com coordenadas válidas
- **THEN** o carrossel exibe apenas esses picos uma única vez ordenados primeiro por menor tempo estimado (Faixa 1) e depois por menor distância em km (Faixa 2), sem repetir itens ao final da rolagem horizontal e sem exibir o card `"VER MAIS ->"`

#### Scenario: Catálogo possui mais de 6 picos disponíveis
- **WHEN** o usuário possui localização disponível e o catálogo contém mais de 6 picos
- **THEN** o carrossel exibe os 6 picos mais próximos conforme a ordenação em duas faixas (tempo e distância) sem repetir nenhum pico na rolagem

#### Scenario: Ordenação corrige distorção de pico atrás de barreira geográfica
- **WHEN** o Pico A está a 14 km em linha reta mas a 55 min (44 km por estrada secundária atrás de uma serra) e o Pico B está a 25 km em linha reta e 30 min (29 km por rodovia)
- **THEN** o carrossel exibe o Pico B antes do Pico A, refletindo a proximidade real em tempo de direção pela malha viária

#### Scenario: Transição entre picos dentro do raio de 200 km e picos distantes
- **WHEN** o catálogo contém 2 picos alcançáveis pela malha local (com estimativa de tempo) e 5 picos a mais de 200 km (apenas distância em km)
- **THEN** os 2 picos com estimativa de tempo aparecem nas posições 1 e 2 ordenados por minutos e os 4 mais próximos dentre os restantes aparecem nas posições 3 a 6 ordenados por quilômetros

### Requirement: Card Minimalista de Ver Mais no Final do Carrossel
Quando houver mais de 6 picos disponíveis no catálogo, o carrossel da página inicial DEVE (MUST) exibir na 7ª posição (após os 6 picos mais próximos) um card de ação com as mesmas dimensões dos cards de pico contendo exclusivamente o texto `"VER MAIS ->"`.

#### Scenario: Renderização do card VER MAIS no fim do carrossel
- **WHEN** o usuário rola o carrossel de picos próximos até o final havendo mais de 6 picos no catálogo
- **THEN** o 7º elemento renderizado no carrossel é um card com o texto `"VER MAIS ->"` centralizado e dimensões idênticas aos demais cards do carrossel

### Requirement: Navegação do Card Ver Mais com Auto-Scroll para o 7º Pico na Aba Explorar
Ao tocar no card `"VER MAIS ->"`, o sistema DEVE (MUST) alternar para a aba Explorar com a ordenação "Mais próximos" selecionada, sem filtro de busca textual ativo, e rolar automaticamente a listagem vertical até posicionar o 7º pico no topo da área visível, preservando os 6 primeiros picos acessíveis acima na rolagem.

#### Scenario: Usuário toca no card VER MAIS no carrossel da Home
- **WHEN** o usuário toca no card `"VER MAIS ->"` ao final do carrossel da página inicial
- **THEN** o aplicativo exibe a aba Explorar ordenada por "Mais próximos" e posiciona automaticamente a rolagem vertical no 7º pico da lista

#### Scenario: Usuário rola para cima após o auto-scroll na aba Explorar
- **WHEN** a aba Explorar foi aberta no 7º pico via card `"VER MAIS ->"` e o usuário desliza a lista para baixo (scroll para o topo)
- **THEN** os 6 primeiros picos estão presentes e visíveis no início da lista na exata mesma ordem do carrossel da Home

### Requirement: Ordenação Unificada e Exibição de Distância na Aba Explorar
A aba Explorar DEVE (MUST) oferecer três opções de ordenação — **Mais próximos** (padrão), **Alfabético (A-Z)** e **Mais escaladas** — utilizando na opção "Mais próximos" a mesma ordenação em duas faixas da página inicial (1º picos com estimativa de tempo ordenados por minutos; 2º demais picos ordenados por km) e exibindo no badge do card o tempo arredondado (quando na Faixa 1) ou a distância em km (quando na Faixa 2).

#### Scenario: Ordenação padrão por Mais próximos com localização ativa
- **WHEN** o usuário acessa a aba Explorar com localização (GPS ou cache) disponível
- **THEN** os picos são listados por padrão na ordem "Mais próximos" em duas faixas (primeiro picos alcançáveis pela malha local ordenados por menor tempo com badge `~X min` / `~Xh Ymin`, seguidos pelos demais picos ordenados por menor distância com badge `Y.Z km`)

#### Scenario: Preservação da badge de distância ao alterar ordenação
- **WHEN** o usuário com localização disponível altera a ordenação na aba Explorar para "Alfabético (A-Z)" ou "Mais escaladas"
- **THEN** a lista é reordenada conforme o critério escolhido e cada card continua exibindo sua respectiva *badge* de tempo estimado (se dentro da malha local) ou distância rodoviária estimada

#### Scenario: Fallback de ordenação sem localização disponível
- **WHEN** o usuário acessa a aba Explorar na ordenação "Mais próximos" mas não há localização de GPS nem cache disponível
- **THEN** os picos são exibidos sem *badge* de distância em ordem alfabética (A-Z) como fallback determinístico

### Requirement: Arredondamento da Estimativa de Tempo em Intervalos de 5 e 10 Minutos
O aplicativo DEVE (MUST) arredondar o tempo estimado de viagem para o múltiplo mais próximo de **5 minutos** quando a duração for inferior a 60 minutos (com mínimo de `5 min`) e para o múltiplo mais próximo de **10 minutos** quando a duração for igual ou superior a 60 minutos.

#### Scenario: Duração inferior a uma hora arredondada para múltiplo de 5 minutos
- **WHEN** o tempo estimado total até um pico é de `38` minutos
- **THEN** o badge exibe `~40 min` (e durações muito curtas como `2` minutos exibem `~5 min`).

#### Scenario: Duração igual ou superior a uma hora arredondada para múltiplo de 10 minutos
- **WHEN** o tempo estimado total até um pico é de `74` minutos
- **THEN** o tempo é arredondado para `70` minutos e o badge exibe `~1h 10min` (ou `~2h` quando o múltiplo fecha em hora exata como `120` minutos).

### Requirement: Badge Clicável com Ícone Informativo e Mini Bottom Sheet Explicativo de Viagem
Nos cards de picos que possuem estimativa de tempo pela malha local, o badge de proximidade DEVE (MUST) exibir um ícone informativo `ⓘ` ao lado do tempo arredondado e interceptar o toque simples (`onTap`) sem disparar a abertura ou download do croqui, abrindo um Mini Bottom Sheet explicativo contendo o título do pico, o tempo médio estimado em fluxo normal, a distância estimada por estrada em quilômetros e o aviso de que o cálculo é realizado offline pela malha do OpenStreetMap sem trânsito em tempo real.

#### Scenario: Toque simples no badge de tempo abre o Mini Bottom Sheet sem abrir o croqui
- **WHEN** o usuário toca no badge de tempo (`~1h` com ícone `ⓘ`) de um card de pico com distância por estrada de `54.1 km`
- **THEN** o callback de abertura/download do card NÃO é acionado e o aplicativo exibe um Mini Bottom Sheet apresentando o tempo médio estimado (`~1h`), a distância por estrada (`54.1 km`) e a explicação sobre o cálculo offline sem trânsito em tempo real.

#### Scenario: Badge apenas com quilometragem não exibe ícone informativo nem intercepta abertura do card
- **WHEN** o pico está fora da malha local de tempo e exibe apenas quilometragem no badge (ex.: `425.0 km`)
- **THEN** o badge é renderizado sem o ícone `ⓘ` e tocar sobre o card ou sobre o badge executa normalmente a ação do card.
