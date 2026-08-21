## ADDED Requirements

### Requirement: Migração em Segundo Plano Pós-Atualização de Pacote no Android
O sistema MUST (DEVE) escutar o evento de atualização de pacote no Android (`ACTION_MY_PACKAGE_REPLACED`) e enfileirar uma tarefa em segundo plano via `WorkManager` para sincronizar o catálogo de dados e migrar os croquis salvos de forma silenciosa.

#### Scenario: Atualização automática da Google Play com Wi-Fi
- **WHEN** a Google Play Store atualizar o aplicativo e o dispositivo possuir conexão com a internet
- **THEN** o `WorkManager` executa a tarefa `tarefa_migracao_pos_atualizacao` em segundo plano, baixando o novo índice e os croquis salvos antes do primeiro acesso do usuário

### Requirement: Prioridade de Primeiro Plano (Foreground Takeover)
O sistema MUST (DEVE) cancelar qualquer execução em andamento da tarefa de migração em segundo plano ao iniciar a aplicação em primeiro plano, assumindo o controle do processo e aproveitando os arquivos temporários já baixados.

#### Scenario: Abertura do app durante a migração em segundo plano
- **WHEN** o usuário abrir o aplicativo enquanto a tarefa de migração do `WorkManager` estiver em execução
- **THEN** o aplicativo cancela a tarefa em segundo plano, retoma o download a partir dos arquivos `.tmp` existentes e conclui a migração na interface com o usuário

