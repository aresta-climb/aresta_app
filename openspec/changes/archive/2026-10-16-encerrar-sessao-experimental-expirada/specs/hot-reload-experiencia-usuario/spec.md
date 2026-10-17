# Spec Delta

## ADDED Requirements

### Requirement: Encerramento Automático da Sessão Experimental Expirada e Diálogo de Retorno ao Catálogo Oficial
O sistema DEVE (MUST) encerrar automaticamente o Modo Experimental quando detectar que a sessão remota do Editor Desktop foi encerrada ou expirou (resposta `HTTP 404` ao sincronizar o índice experimental), limpando os dados temporários, restaurando o catálogo oficial de produção e exibindo um diálogo modal elegante informando ao usuário o retorno ao Modo Oficial.

#### Scenario: Sincronização no modo experimental recebe HTTP 404 (sessão do editor encerrada)
- **WHEN** o aplicativo está no Modo Experimental e uma sincronização (manual ou automática) recebe resposta `HTTP 404` ao buscar `indice.binarypb` na URL do editor
- **THEN** o sistema DEVE encerrar o Modo Experimental e limpar os arquivos temporários experimentais (`nukeExperimentalData`)
- **AND** o sistema DEVE interromper imediatamente o loop de reconexão do WebSocket de Live Reload
- **AND** o sistema DEVE restaurar o catálogo oficial de produção na memória (`datasetRepo.init()`) e redirecionar a navegação para a tela inicial (`HomeNode`)
- **AND** o sistema DEVE exibir o diálogo modal `ModalSessaoExperimentalEncerrada` avisando de forma amigável que a conexão com o Editor Desktop foi encerrada e que o aplicativo retornou ao catálogo oficial do Aresta Climb, contendo um botão de confirmação (`"ENTENDI"`).

#### Scenario: Confirmação no diálogo de sessão experimental encerrada
- **WHEN** o diálogo `ModalSessaoExperimentalEncerrada` está visível na tela e o usuário toca no botão `"ENTENDI"`
- **THEN** o diálogo DEVE ser fechado e o usuário DEVE permanecer na tela inicial com os dados oficiais de produção ativos.
