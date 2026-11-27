## MODIFIED Requirements

### Requirement: Estimativa de Tempo de Conexão Inicial do Usuário ao Nó da Malha
O cálculo do tempo de acesso inicial $\text{TempoAcesso}(U \to K)$ sobre a distância estimada $d_{U \to K} = \text{dist\_reta}(U, K) \times 1{,}25$ DEVE (MUST) aplicar velocidade média de `24 km/h` para os primeiros `3 km` (saída urbana/local com semáforos e cruzamentos) e `40 km/h` para a distância excedente acima de `3 km`.

#### Scenario: Usuário a 8 km estimados de estrada até o nó da malha
- **WHEN** a distância de acesso $d_{U \to K} = \text{dist\_reta}(U, K) \times 1{,}25$ até o nó $K$ é de `8000` metros (`8 km`)
- **THEN** o tempo de acesso inicial até $K$ é calculado como $7{,}5\text{ min}$ (primeiros `3 km` a `24 km/h`) $+ 7{,}5\text{ min}$ (`5 km` restantes a `40 km/h`) $= 15\text{ min}$, somado ao `duracao_minutos` de $K$ até o pico.
