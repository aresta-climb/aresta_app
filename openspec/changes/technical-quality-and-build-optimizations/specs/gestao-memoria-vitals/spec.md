## ADDED Requirements

### Requirement: Limite de Cache de Imagens em Memória
O sistema DEVE limitar o tamanho máximo do cache de imagens decodificadas na memória RAM (`imageCache.maximumSizeBytes`) em 100 MB para garantir conformidade com os limites de Vitals em segundo plano do Google Play.

#### Scenario: Inicialização do aplicativo
- **WHEN** o aplicativo Flutter é inicializado
- **THEN** o `PaintingBinding.instance.imageCache.maximumSizeBytes` é configurado para 100 MB mantendo o comportamento LRU

### Requirement: Tratamento de Memória Crítica do Sistema
O sistema DEVE liberar imagens em cache não ativas quando o sistema operacional disparar alertas críticos de escassez de memória.

#### Scenario: Alerta de memória crítica recebido
- **WHEN** o aplicativo recebe um sinal de aviso de memória crítica do sistema operacional
- **THEN** o cache de imagens libera as instâncias não visíveis para aliviar a pressão de RAM do dispositivo