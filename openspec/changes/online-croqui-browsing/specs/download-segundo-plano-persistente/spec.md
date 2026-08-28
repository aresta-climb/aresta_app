## ADDED Requirements

### Requirement: Execução de Download em Segundo Plano com Notificação do SO
O sistema DEVE (MUST) executar o download dos arquivos de um croqui (incluindo `.binarypb` e mídias externas) através de um serviço de segundo plano resiliente acoplado a uma notificação contínua no sistema operacional (`ongoing: true` no Android / Foreground Service e background `URLSession` no iOS). O download DEVE continuar progredindo sem interrupções mesmo se o usuário minimizar o aplicativo, bloquear o aparelho ou alternar para outros aplicativos.

#### Scenario: Download em andamento com aplicativo em segundo plano
- **WHEN** o usuário inicia o download de um croqui e minimiza o aplicativo
- **THEN** o sistema operacional exibe uma notificação persistente na barra de notificações com o nome do pico e barra de progresso
- **AND** os downloads continuam até a conclusão de todos os arquivos.

#### Scenario: Atualização periódica da porcentagem na notificação
- **WHEN** os arquivos de imagem e mapas do croqui são baixados e verificados
- **THEN** a notificação do sistema atualiza o percentual de conclusão em tempo real.

### Requirement: Notificação de Conclusão e Atualização Atômica
Ao concluir com sucesso o download de todos os arquivos temporários de um croqui, o serviço DEVE (MUST) mover os arquivos de forma atômica para o diretório `/downloads/<cragId>/`, registrar a versão baixada no estado do `DatasetRepository` e atualizar a notificação do sistema para o estado de sucesso ("Croqui pronto para uso offline").

#### Scenario: Conclusão bem-sucedida do download
- **WHEN** o último arquivo do croqui é baixado e validado contra seu SHA-256
- **THEN** os arquivos são movidos atomicamente para a pasta permanente
- **AND** a notificação permanente transita para aviso de conclusão
- **AND** o estado em memória marca o pico como `isDownloaded = true`.

### Requirement: Tratamento de Falhas e Retentativa Automática
Caso ocorra perda de conexão ou falha durante o download em segundo plano, o serviço DEVE (MUST) realizar retentativas automáticas e, em caso de esgotamento de tentativas, atualizar a notificação do sistema indicando a falha sem corromper arquivos já existentes na pasta `/downloads`.

#### Scenario: Falha de conexão durante download em background
- **WHEN** a conexão de rede é interrompida durante o download dos arquivos
- **THEN** o serviço tenta reconectar de acordo com a política de retentativas
- **AND** se falhar definitivamente, notifica o usuário sobre a interrupção e descarta arquivos temporários corrompidos.
