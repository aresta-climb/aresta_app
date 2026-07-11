## MODIFIED Requirements

### Requirement: Estado Visual do Mapa Interativo

O sistema DEVE preservar o estado visual do mapa interativo (incluindo nível de zoom, posição de movimentação/pan e estado inicial de animação) quando o usuário navega entre múltiplos mapas em um carrossel.

#### Scenario: Deslizando de volta para um mapa visualizado anteriormente
- **WHEN** o usuário está visualizando múltiplos mapas interativos em um carrossel
- **AND** o usuário desliza para um novo mapa, e então desliza de volta para o mapa anterior
- **THEN** o mapa anterior retém sua posição exata de zoom e movimentação
- **AND** a animação inicial de zoom não é reproduzida novamente
