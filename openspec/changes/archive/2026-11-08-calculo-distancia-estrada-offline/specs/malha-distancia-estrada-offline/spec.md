# malha-distancia-estrada-offline Specification

## Purpose

Define o contrato de armazenamento relacional esparso, deduplicação determinística em anéis concêntricos, indexação espacial 2D (KD-Tree) e estimativa offline de distância rodoviária até os picos de escalada no catálogo local.

## ADDED Requirements

### Requirement: Armazenamento Esparso de Nós Rodoviários e Distâncias no Catálogo SQLite
O banco SQLite do catálogo (`catalogo.db`) DEVE (MUST) armazenar os nós rodoviários compartilhados em `catalogo_nos_estrada` (`no_osm_id`, `latitude_e7`, `longitude_e7`) e as distâncias pré-computadas por croqui em `catalogo_distancias_estrada` (`croqui_uid`, `no_osm_id`, `distancia_metros`, `na_borda`), permitindo atualização incremental isolada por `croqui_uid`.

#### Scenario: Deduplicação automática de nó compartilhado entre dois croquis
- **WHEN** dois croquis distintos da mesma região possuem distâncias pré-computadas a partir do mesmo `no_osm_id`
- **THEN** `catalogo_nos_estrada` armazena apenas um único registro para aquele `no_osm_id` e `catalogo_distancias_estrada` mantém uma linha para cada par `(croqui_uid, no_osm_id)`.

#### Scenario: Atualização seletiva da malha de um único croqui
- **WHEN** a malha rodoviária de um croqui específico é atualizada ou removida no catálogo
- **THEN** apenas os registros daquele `croqui_uid` em `catalogo_distancias_estrada` são substituídos ou excluídos, preservando intactas as distâncias dos demais croquis.

### Requirement: Amostragem Determinística em 3 Anéis Concêntricos e Inclusão do Estacionamento
A malha pré-computada de cada pico DEVE (MUST) cobrir até 180 km em 3 anéis concêntricos ancorados na grade global (`0.02°` de 0 a 15 km, `0.06°` de 15 a 60 km e `0.18°` de 60 a 180 km), elegendo o nó vencedor de cada célula exclusivamente pela prioridade intrínseca `(rank_rodovia, -grau_cruzamento, hash_id)` e incluindo o próprio estacionamento com `distancia_metros = 0`.

#### Scenario: Coincidência determinística de nó vencedor entre Anel 2 e Anel 3 de picos distintos
- **WHEN** uma mesma região geográfica cai no Anel 2 (`0.06°`) do Pico A e no Anel 3 (`0.18°`, bloco $3 \times 3$ de `0.06°`) do Pico B
- **THEN** o nó vencedor eleito para o bloco de `0.18°` do Pico B é obrigatoriamente idêntico ao vencedor de uma das 9 células de `0.06°` do Pico A, sem criar nós duplicados adjacentes.

#### Scenario: Usuário posicionado no próprio estacionamento do pico
- **WHEN** o usuário encontra-se nas imediações do estacionamento de um pico cadastrado
- **THEN** o nó do estacionamento consta na malha com `distancia_metros = 0` para aquele pico, resultando na distância imediata de aproximação local sem desviar até uma rodovia distante.

### Requirement: Indexação Espacial 2D em KD-Tree e Cálculo Regional pelos Vizinhos Mais Próximos
O aplicativo DEVE (MUST) indexar os nós de `catalogo_nos_estrada` em uma árvore de particionamento espacial 2D (KD-Tree) em memória e, para uma coordenada do usuário, consultar em $O(\log N)$ os até 3 nós mais próximos num raio máximo de 15 km, calculando a distância para cada pico presente nesses nós como $\min_{K} \big(\text{dist\_reta}(U, K) \times 1{,}25 + \text{dist\_estrada}(K \to P)\big)$.

#### Scenario: Usuário dentro da malha regional com barreira geográfica entre ele e o pico
- **WHEN** o usuário está a 14 km em linha reta de um pico situado atrás de uma serra, mas os nós rodoviários a até 15 km do usuário registram 42 km de estrada até o pico
- **THEN** o cálculo retorna a distância rodoviária estimada (~42 km) combinando a aproximação até o melhor nó vizinho com a distância de estrada pré-computada.

#### Scenario: Seleção do nó vizinho na direção favorável de saída
- **WHEN** o usuário está entre dois nós rodoviários próximos ($K_{\text{norte}}$ a 1,0 km e $K_{\text{sul}}$ a 1,4 km) e o pico fica ao sul
- **THEN** a minimização entre os 3 nós mais próximos seleciona $K_{\text{sul}}$ por produzir a menor soma total até o pico ao sul, evitando retorno em sentido contrário.

### Requirement: Estimativa de Longa Distância via Portais de Borda e Fallback Geodésico
Quando um pico não constar na lista esparsa dos nós vizinhos do usuário (distância $> 180\text{ km}$ ou usuário fora da malha), o sistema DEVE (MUST) estimar a distância minimizando $\text{dist\_reta}(U, B) \times 1{,}25 + \text{dist\_estrada}(B \to P)$ sobre os portais de borda (`na_borda = 1`) do pico, ou aplicar o fallback $\text{dist\_reta}(U, P) \times 1{,}25$ caso o pico ainda não possua malha cadastrada.

#### Scenario: Escolha do portal de borda ótimo evitando ponto bloqueado por serra ou represa
- **WHEN** o usuário está a mais de 180 km de um pico que possui um portal de borda $B_1$ (a 110 km em linha reta do usuário, mas a 95 km de volta sinuosa até o pico) e um portal $B_2$ (a 125 km em linha reta do usuário e a 35 km diretos de estrada até o pico)
- **THEN** o sistema avalia a soma total de ambos os portais e seleciona $B_2$ ($125 \times 1{,}25 + 35 = 191{,}25\text{ km} < 110 \times 1{,}25 + 95 = 232{,}5\text{ km}$).

#### Scenario: Croqui sem malha pré-computada (modo Editor ou banco ainda não sincronizado)
- **WHEN** um croqui possui coordenada válida de localização mas não possui registros em `catalogo_distancias_estrada`
- **THEN** o sistema calcula a distância estimada aplicando o fator de sinuosidade rodoviária sobre a distância geodésica ($\text{dist\_reta}(U, P) \times 1{,}25$).
