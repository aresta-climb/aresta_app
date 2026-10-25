# descoberta-picos-proximidade Specification

## Purpose
Define o contrato de comportamento para descoberta de picos de escalada por proximidade geográfica no carrossel da página inicial e no catálogo da aba Explorar, assegurando consistência de ordenação por distância, exibição de quilometragem e transição contínua entre as telas.

## Requirements

### Requirement: Exibição Linear dos Top 6 Picos no Carrossel da Home
O carrossel de picos próximos na página inicial DEVE (MUST) exibir no máximo os 6 picos mais próximos da localização do usuário em ordem crescente de distância geodésica, sem repetição circular (sem loop infinito).

#### Scenario: Catálogo possui 6 ou menos picos com localização
- **WHEN** o usuário possui localização disponível e o catálogo contém até 6 picos com coordenadas válidas
- **THEN** o carrossel exibe apenas esses picos uma única vez em ordem crescente de distância, sem repetir itens ao final da rolagem horizontal e sem exibir o card `"VER MAIS ->"`

#### Scenario: Catálogo possui mais de 6 picos disponíveis
- **WHEN** o usuário possui localização disponível e o catálogo contém mais de 6 picos
- **THEN** o carrossel exibe os 6 picos mais próximos em ordem crescente de distância sem repetir nenhum pico na rolagem

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
A aba Explorar DEVE (MUST) oferecer três opções de ordenação — **Mais próximos** (padrão), **Alfabético (A-Z)** e **Mais escaladas** — utilizando o mesmo cálculo geodésico da página inicial e exibindo a *badge* de distância formatada (`m` ou `km`) em todos os cards de picos com coordenadas quando a localização do usuário estiver disponível.

#### Scenario: Ordenação padrão por Mais próximos com localização ativa
- **WHEN** o usuário acessa a aba Explorar com localização (GPS ou cache) disponível
- **THEN** os picos são listados por padrão na ordem "Mais próximos" seguindo exatamente o mesmo cálculo de distância da página inicial, exibindo a *badge* de distância (ex: `450 m` ou `12.3 km`) em cada card

#### Scenario: Preservação da badge de distância ao alterar ordenação
- **WHEN** o usuário com localização disponível altera a ordenação na aba Explorar para "Alfabético (A-Z)" ou "Mais escaladas"
- **THEN** a lista é reordenada conforme o critério escolhido e cada card continua exibindo sua respectiva *badge* de distância

#### Scenario: Fallback de ordenação sem localização disponível
- **WHEN** o usuário acessa a aba Explorar na ordenação "Mais próximos" mas não há localização de GPS nem cache disponível
- **THEN** os picos são exibidos sem *badge* de distância em ordem alfabética (A-Z) como fallback determinístico
