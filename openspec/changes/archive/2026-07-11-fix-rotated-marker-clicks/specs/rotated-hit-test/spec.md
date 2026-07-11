## ADDED Requirements

### Requirement: Detecção Precisa de Toque no Mapa Interativo
O mapa interativo DEVE (SHALL) detectar toques com precisão dentro de marcadores de mapa rotacionados, ignorando as caixas delimitadoras alinhadas aos eixos (AABB) que obscurecem marcadores menores próximos.

#### Scenario: Usuário toca em um marcador pequeno próximo a um marcador rotacionado
- **WHEN** o usuário toca no marcador "15" que está situado dentro da AABB do rótulo rotacionado "SETOR SENTINELA", mas fora da sua forma desenhada real
- **THEN** o sistema registra corretamente o toque no marcador "15" e não no rótulo "SETOR SENTINELA"
