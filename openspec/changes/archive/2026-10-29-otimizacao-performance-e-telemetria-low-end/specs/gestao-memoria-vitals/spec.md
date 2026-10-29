## MODIFIED Requirements

### Requirement: Limite de Cache de Imagens em Memória
O sistema DEVE (MUST) limitar o tamanho máximo do cache de imagens decodificadas na memória RAM (`imageCache.maximumSizeBytes`) de forma adaptativa ao porte de memória RAM do dispositivo (`tier_dispositivo`), configurando 50 MB para dispositivos de tier `'baixo'` (≤ 3 GB RAM), 100 MB para tier `'medio'` (4 a 6 GB RAM, ou como fallback padrão) e 150 MB para tier `'alto'` (≥ 8 GB RAM), garantindo conformidade com os limites de Vitals do Google Play.

#### Scenario: Inicialização do aplicativo
- **WHEN** o aplicativo Flutter é inicializado em um dispositivo de tier `'medio'` (4–6 GB RAM) ou antes da resolução de hardware
- **THEN** o `PaintingBinding.instance.imageCache.maximumSizeBytes` é configurado para 100 MB mantendo o comportamento LRU

#### Scenario: Ajuste adaptativo do cache de imagens para dispositivo de baixa memória
- **WHEN** o classificador de dispositivo identifica um aparelho de tier `'baixo'` (≤ 3 GB de RAM física)
- **THEN** o `PaintingBinding.instance.imageCache.maximumSizeBytes` é ajustado para 50 MB (52.428.800 bytes)

#### Scenario: Ajuste adaptativo do cache de imagens para dispositivo de alta memória
- **WHEN** o classificador de dispositivo identifica um aparelho de tier `'alto'` (≥ 8 GB de RAM física)
- **THEN** o `PaintingBinding.instance.imageCache.maximumSizeBytes` é ajustado para 150 MB (157.286.400 bytes)
