# descoberta-picos-proximidade Specification

## MODIFIED Requirements

### Requirement: Exibição Linear dos Top 6 Picos no Carrossel da Home
O carrossel de picos próximos na página inicial DEVE (MUST) exibir no máximo os 6 picos mais próximos da localização do usuário em ordem crescente de distância rodoviária estimada offline (com fallback geodésico ajustado quando a malha do pico não estiver disponível), sem repetição circular (sem loop infinito).

#### Scenario: Catálogo possui 6 ou menos picos com localização
- **WHEN** o usuário possui localização disponível e o catálogo contém até 6 picos com coordenadas válidas
- **THEN** o carrossel exibe apenas esses picos uma única vez em ordem crescente de distância rodoviária estimada, sem repetir itens ao final da rolagem horizontal e sem exibir o card `"VER MAIS ->"`

#### Scenario: Catálogo possui mais de 6 picos disponíveis
- **WHEN** o usuário possui localização disponível e o catálogo contém mais de 6 picos
- **THEN** o carrossel exibe os 6 picos mais próximos em ordem crescente de distância rodoviária estimada sem repetir nenhum pico na rolagem

#### Scenario: Ordenação corrige distorção de pico atrás de barreira geográfica
- **WHEN** o Pico A está a 14 km em linha reta mas a 44 km por estrada (atrás de uma serra) e o Pico B está a 25 km em linha reta e 29 km por estrada
- **THEN** o carrossel exibe o Pico B antes do Pico A, refletindo a proximidade real por estrada

### Requirement: Ordenação Unificada e Exibição de Distância na Aba Explorar
A aba Explorar DEVE (MUST) oferecer três opções de ordenação — **Mais próximos** (padrão), **Alfabético (A-Z)** e **Mais escaladas** — utilizando exatamente o mesmo cálculo de distância rodoviária estimada offline da página inicial e exibindo a *badge* de distância formatada (`m` ou `km`) em todos os cards de picos com coordenadas quando a localização do usuário estiver disponível.

#### Scenario: Ordenação padrão por Mais próximos com localização ativa
- **WHEN** o usuário acessa a aba Explorar com localização (GPS ou cache) disponível
- **THEN** os picos são listados por padrão na ordem "Mais próximos" seguindo exatamente o mesmo cálculo de distância rodoviária estimada da página inicial, exibindo a *badge* de distância (ex: `450 m` ou `42.5 km`) em cada card

#### Scenario: Preservação da badge de distância ao alterar ordenação
- **WHEN** o usuário com localização disponível altera a ordenação na aba Explorar para "Alfabético (A-Z)" ou "Mais escaladas"
- **THEN** a lista é reordenada conforme o critério escolhido e cada card continua exibindo sua respectiva *badge* de distância rodoviária estimada

#### Scenario: Fallback de ordenação sem localização disponível
- **WHEN** o usuário acessa a aba Explorar na ordenação "Mais próximos" mas não há localização de GPS nem cache disponível
- **THEN** os picos são exibidos sem *badge* de distância em ordem alfabética (A-Z) como fallback determinístico
