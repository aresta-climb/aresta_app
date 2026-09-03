## ADDED Requirements

### Requirement: Gerenciamento do Canal de Notificação e Permissões
O sistema DEVE (MUST) criar e configurar um canal de notificação dedicado no Android (`downloads_croquis`) com prioridade adequada e solicitar em tempo de execução a permissão de notificações (`POST_NOTIFICATIONS`) no Android 13+ antes de iniciar o primeiro download.

#### Scenario: Criação de canal e solicitação de permissão
- **WHEN** o usuário aciona o salvamento offline de um pico pela primeira vez
- **THEN** o sistema assegura que o canal de notificação esteja registrado no sistema operacional
- **AND** solicita permissão caso ainda não tenha sido concedida.

### Requirement: Notificação Persistente de Progresso em Tempo Real
Durante o download, o serviço DEVE (MUST) emitir e atualizar uma notificação contínua (`ongoing: true`) exibindo o título do croqui, uma barra de progresso numérica e visual (`maxProgress: 100`, `progress: X`), e desativar alertas sonoros a cada atualização intermediária (`onlyAlertOnce: true`).

#### Scenario: Atualização de progresso intermediário
- **WHEN** novos lotes de bytes e arquivos são confirmados pelo `SyncService`
- **THEN** a notificação do sistema atualiza o percentual sem emitir novos sons ou vibrações repetidas.

### Requirement: Transição de Notificação ao Concluir ou Falhar
Ao término do download, o serviço DEVE (MUST) cancelar o estado persistente (`ongoing: false`) e atualizar a notificação para alertar o usuário:
1. Em caso de sucesso: título indicando conclusão ("Download concluído") e corpo indicando que o croqui está disponível offline.
2. Em caso de erro: aviso claro de falha de conexão permitindo ao usuário tocar para reabrir o app e retentar.

#### Scenario: Transição para notificação de sucesso
- **WHEN** todos os arquivos são salvos com sucesso na pasta permanente
- **THEN** a notificação deixa de ser fixa e pode ser dispensada pelo usuário.
