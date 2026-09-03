## ADDED Requirements

### Requirement: Sincronização de Thumbnails em Background
O sistema DEVE baixar as thumbnails proativamente para todos os crags disponíveis durante o processo de sincronização do índice.

#### Scenario: Índice sincronizado com sucesso
- **WHEN** o `SyncService` baixa um novo `indice.binarypb`
- **THEN** o sistema itera por todos os crags disponíveis e baixa suas thumbnails para o cache local se elas estiverem faltando ou desatualizadas

### Requirement: Exibição de Thumbnails Locais
O sistema DEVE exibir as thumbnails a partir do sistema de arquivos local ou streaming remoto na aba Explorar e em cards de navegação, decodificando as imagens com restrição de largura/altura (downsampling) proporcional ao tamanho de exibição na tela para evitar alocação excessiva de memória RAM.

#### Scenario: Usuário vê a aba Explorar com thumbnails downsampled
- **WHEN** o usuário navega para a aba Explorar ou visualiza listas de setores e croquis
- **THEN** as thumbnails locais e remotas são decodificadas com largura restrita (`cacheWidth: 300` ou `larguraAlvo`), alocando menos de 250 KB de RAM por miniatura

