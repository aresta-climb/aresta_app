## MODIFIED Requirements

### Requirement: Armazenamento Esparso de Nós Rodoviários e Distâncias no Catálogo SQLite
O banco SQLite do catálogo (`catalogo.db`) DEVE (MUST) armazenar os nós rodoviários compartilhados em `catalogo_nos_estrada` (`no_osm_id`, `latitude_e7`, `longitude_e7`) e os caminhos pré-computados por croqui em `catalogo_distancias_estrada` (`croqui_uid`, `no_osm_id`, `distancia_metros`, `na_borda`, `duracao_minutos`), permitindo atualização incremental isolada por `croqui_uid`.

#### Scenario: Deduplicação automática de nó compartilhado entre dois croquis
- **WHEN** dois croquis distintos da mesma região possuem caminhos pré-computadas a partir do mesmo `no_osm_id`
- **THEN** `catalogo_nos_estrada` armazena apenas um único registro para aquele `no_osm_id` e `catalogo_distancias_estrada` mantém uma linha para cada par `(croqui_uid, no_osm_id)` com seus respectivos `distancia_metros` e `duracao_minutos`.

#### Scenario: Atualização seletiva da malha de um único croqui
- **WHEN** a malha rodoviária de um croqui específico é atualizada ou removida no catálogo
- **THEN** apenas os registros daquele `croqui_uid` em `catalogo_distancias_estrada` são substituídos ou excluídos, preservando intactas as distâncias e durações dos demais croquis.

### Requirement: Amostragem Determinística em 3 Anéis Concêntricos e Inclusão do Estacionamento
A malha pré-computada de cada pico DEVE (MUST) cobrir até 180 km em 3 anéis concêntricos ancorados na grade global (`0.02°` de 0 a 15 km, `0.06°` de 15 a 60 km e `0.18°` de 60 a 180 km), elegendo o nó vencedor de cada célula exclusivamente pela prioridade intrínseca `(rank_rodovia, -grau_cruzamento, hash_id)` e incluindo o próprio estacionamento com `distancia_metros = 0` e `duracao_minutos = 0`.

#### Scenario: Coincidência determinística de nó vencedor entre Anel 2 e Anel 3 de picos distintos
- **WHEN** uma mesma região geográfica cai no Anel 2 (`0.06°`) do Pico A e no Anel 3 (`0.18°`, bloco $3 \times 3$ de `0.06°`) do Pico B
- **THEN** o nó vencedor eleito para o bloco de `0.18°` do Pico B é obrigatoriamente idêntico ao vencedor de uma das 9 células de `0.06°` do Pico A, sem criar nós duplicados adjacentes.

#### Scenario: Usuário posicionado no próprio estacionamento do pico
- **WHEN** o usuário encontra-se nas imediações do estacionamento de um pico cadastrado
- **THEN** o nó do estacionamento consta na malha com `distancia_metros = 0` e `duracao_minutos = 0` para aquele pico, resultando no tempo e distância imediatos de aproximação local sem desviar até uma rodovia distante.

### Requirement: Indexação Espacial 2D em KD-Tree e Cálculo Regional pelos Vizinhos Mais Próximos
O aplicativo DEVE (MUST) indexar os nós de `catalogo_nos_estrada` em uma árvore de particionamento espacial 2D (KD-Tree) em memória e, para uma coordenada do usuário, consultar em $O(\log N)$ os até 6 nós mais próximos num raio máximo de 25 km, selecionando para cada pico presente nesses nós o nó $K$ que minimiza o tempo total estimado $\text{TempoAcesso}(U \to K) + \text{duracao\_minutos}(K \to P)$ e retornando tanto a duração total em minutos quanto a distância correspondente $\text{dist\_reta}(U, K) \times 1{,}25 + \text{dist\_estrada}(K \to P)$.

#### Scenario: Usuário dentro da malha regional com barreira geográfica entre ele e o pico
- **WHEN** o usuário está a 14 km em linha reta de um pico situado atrás de uma serra, mas os nós rodoviários a até 25 km do usuário registram 42 km (48 min) de estrada até o pico
- **THEN** o cálculo retorna o tempo e a distância rodoviária estimados combinando a aproximação até o melhor nó vizinho com o tempo e a distância de estrada pré-computados.

#### Scenario: Seleção do nó vizinho na direção favorável de saída
- **WHEN** o usuário está entre dois nós rodoviários próximos ($K_{\text{norte}}$ a 1,0 km e $K_{\text{sul}}$ a 1,4 km) e o pico fica ao sul
- **THEN** a minimização entre os até 6 nós mais próximos seleciona $K_{\text{sul}}$ por produzir o menor tempo total até o pico ao sul, evitando retorno em sentido contrário.

#### Scenario: Usuário no Anel 3 a até 25 km do nó amostrado mais próximo
- **WHEN** o usuário está posicionado no Anel 3 (células de `0.18°` $\approx 20\text{ km}$) a 19 km do nó rodoviário amostrado mais próximo
- **THEN** a busca na KD-Tree com raio de 25 km e até 6 vizinhos captura os nós rodoviários ao redor do usuário e retorna a estimativa de tempo e distância pela malha viária.

## ADDED Requirements

### Requirement: Otimização por Menor Tempo de Direção Sem Trânsito no Grafo Viário
A geração da malha viária de cada pico DEVE (MUST) calcular o caminho de menor tempo de viagem sem trânsito (`duracao_minutos`) a partir do estacionamento usando velocidades livres estimadas por segmento OSM (`maxspeed` ajustado ou velocidade tabelada por `highway` e `surface`), armazenando no nó tanto `duracao_minutos` quanto a `distancia_metros` acumulada ao longo desse caminho mais rápido.

#### Scenario: Caminho por rodovia expressa mais longo em km porém mais rápido em minutos
- **WHEN** entre um nó rodoviário e o pico existem duas rotas: uma estrada secundária de terra de 35 km (`25 km/h`, ~84 min) e uma rodovia pavimentada de 48 km (`85 km/h`, ~34 min)
- **THEN** o algoritmo de Dijkstra seleciona a rota pela rodovia pavimentada e persiste `duracao_minutos = 34` e `distancia_metros = 48000` para aquele nó.

### Requirement: Estimativa de Tempo de Conexão Inicial do Usuário ao Nó da Malha
O cálculo do tempo de acesso inicial $\text{TempoAcesso}(U \to K)$ sobre a distância estimada $d_{U \to K} = \text{dist\_reta}(U, K) \times 1{,}25$ DEVE (MUST) aplicar velocidade média de `30 km/h` para os primeiros `3 km` (saída urbana/local) e `50 km/h` para a distância excedente acima de `3 km`.

#### Scenario: Usuário a 8 km estimados de estrada até o nó da malha
- **WHEN** a distância de acesso $d_{U \to K} = \text{dist\_reta}(U, K) \times 1{,}25$ até o nó $K$ é de `8000` metros (`8 km`)
- **THEN** o tempo de acesso inicial até $K$ é calculado como $6\text{ min}$ (primeiros `3 km` a `30 km/h`) $+ 6\text{ min}$ (`5 km` restantes a `50 km/h`) $= 12\text{ min}$, somado ao `duracao_minutos` de $K$ até o pico.
