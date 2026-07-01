## ADDED Requirements

### Requirement: Sincronização de Thumbnails em Background
O sistema DEVE baixar as thumbnails proativamente para todos os crags disponíveis durante o processo de sincronização do índice.

#### Scenario: Índice sincronizado com sucesso
- **WHEN** o `SyncService` baixa um novo `indice.binarypb`
- **THEN** o sistema itera por todos os crags disponíveis e baixa suas thumbnails para o cache local se elas estiverem faltando ou desatualizadas

### Requirement: Exibição de Thumbnails Locais
O sistema DEVE exibir as thumbnails a partir do sistema de arquivos local na aba Explorar.

#### Scenario: Usuário vê a aba Explorar offline
- **WHEN** o usuário navega para a aba Explorar sem internet
- **THEN** todas as thumbnails são carregadas com sucesso do cache no sistema de arquivos local
