## MODIFIED Requirements

### Requirement: Botão de Desconexão Rápida no Banner Superior
O banner global de modo experimental MUST conter uma ação rápida de encerramento para permitir o retorno imediato à biblioteca oficial de produção e encerramento voluntário do modo experimental sem dependência de expiração temporizada, garantindo que o catálogo oficial de produção seja restaurado imediatamente na memória e que as telas não apresentem estado vazio indevido.

#### Scenario: Clique no botão de sair do banner
- **WHEN** o usuário toca no botão de fechar/sair presente no banner superior de modo experimental
- **THEN** o sistema DEVE executar a limpeza dos dados experimentais (nukeExperimentalData)
- **AND** o sistema DEVE restaurar imediatamente os croquis oficiais de produção na memória do repositório (`activeDataset`) a partir do índice local oficial
- **AND** o sistema DEVE resetar a navegação para a tela inicial oficial (HomeNode)
- **AND** as páginas de Início, Explorar e Meus Croquis NÃO DEVEM ser exibidas como vazias caso existam dados locais oficiais de produção
- **AND** qualquer verificação remota de catálogo em segundo plano que retorne HTTP 304 (Not Modified) DEVE assegurar que os dados locais em disco permaneçam carregados em memória se o catálogo em RAM estiver vazio
