## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: Arredondamento da Estimativa de Tempo em Intervalos de 5 e 10 Minutos
O aplicativo DEVE (MUST) arredondar o tempo estimado de viagem para o múltiplo mais próximo de **5 minutos** quando a duração for inferior a 60 minutos (com mínimo de `5 min`) e para o múltiplo mais próximo de **10 minutos** quando a duração for igual ou superior a 60 minutos.

#### Scenario: Duração inferior a uma hora arredondada para múltiplo de 5 minutos
- **WHEN** o tempo estimado total até um pico é de `38` minutos
- **THEN** o badge exibe `~40 min` (e durações muito curtas como `2` minutos exibem `~5 min`).

#### Scenario: Duração igual ou superior a uma hora arredondada para múltiplo de 10 minutos
- **WHEN** o tempo estimado total até um pico é de `74` minutos
- **THEN** o tempo é arredondado para `70` minutos e o badge exibe `~1h 10min` (ou `~2h` quando o múltiplo fecha em hora exata como `120` minutos).

### Requirement: Tooltip Explicativo de Estimativa Sem Trânsito com Tempo e Quilometragem
O badge de proximidade nos cards de picos com estimativa de tempo DEVE (MUST) apresentar um `Tooltip` informando explicitamente que o valor é uma estimativa de direção sem trânsito acompanhada tanto do tempo arredondado quanto da distância estimada em quilômetros.

#### Scenario: Acionamento do tooltip em card com estimativa de tempo
- **WHEN** o usuário mantém pressionado ou passa o cursor sobre o badge de tempo (`~40 min`) de um pico com `51400` metros de distância estimada
- **THEN** o `Tooltip` exibe `"Estimativa sem trânsito: ~40 min (51.4 km)"`.
