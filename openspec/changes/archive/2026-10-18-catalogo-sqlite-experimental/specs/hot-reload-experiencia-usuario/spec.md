# Spec Delta

## MODIFIED Requirements

### Requirement: Auto-Download e Navegação Pós-Conexão Experimental
O sistema MUST sincronizar o índice e o `catalogo.db` experimental, baixar automaticamente os arquivos do croqui (quando aplicável) e navegar diretamente para a visualização após uma conexão bem-sucedida com o Editor Desktop, reutilizando a instância principal do `SyncService` para evitar execuções concorrentes duplicadas.

#### Scenario: Pareamento com índice de croqui único
- **WHEN** o aplicativo conclui com sucesso a conexão com o editor desktop e o índice contém exatamente um croqui
- **THEN** o sistema DEVE sincronizar `<docs>/editor/experimental/catalogo.db` a partir do servidor experimental
- **AND** o sistema DEVE iniciar e aguardar o download imediato do pacote binário do croqui
- **AND** o sistema DEVE carregar o dataset em memória e navegar a árvore diretamente para o PicoNode do croqui baixado

#### Scenario: Pareamento com índice de múltiplos croquis
- **WHEN** o aplicativo conclui com sucesso a conexão com o editor desktop e o índice contém mais de um croqui
- **THEN** o sistema DEVE sincronizar `<docs>/editor/experimental/catalogo.db` contendo todos os croquis do índice experimental
- **AND** o sistema DEVE navegar para a aba Explorar (BrowseNode) com o banner experimental ativo

#### Scenario: Resolução de Deep Link por UID durante o Modo Experimental
- **WHEN** o aplicativo está no Modo Experimental com `<docs>/editor/experimental/catalogo.db` sincronizado e o usuário aciona um Deep Link ou QR Code apontando para um UID do croqui experimental
- **THEN** o `LocalizadorDestinoUid` DEVE resolver o `id_slug` no `catalogo.db` experimental, carregar o croqui experimental correspondente e navegar diretamente para a entidade alvo.
