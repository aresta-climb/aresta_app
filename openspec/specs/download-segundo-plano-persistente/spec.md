# download-segundo-plano-persistente Specification

## Purpose

Esta especificação define os requisitos de download resiliente de croquis em segundo plano com integração a notificações do sistema operacional móvel (Android e iOS).

## Requirements

### Requirement: Gerenciamento Multiplataforma de Permissões de Notificação
O sistema DEVE (MUST) solicitar ao usuário as permissões de notificação necessárias de acordo com a plataforma em execução:
1. No Android (API 33+): solicitar permissão em tempo de execução `POST_NOTIFICATIONS` e registrar o canal de notificação `downloads_croquis` com importância padrão.
2. No iOS: solicitar autorização para alertas, badges e sons através de `requestPermissions` do centro de notificações da Apple.

#### Scenario: Primeira solicitação de permissão de notificação no Android
- **WHEN** o usuário toca para salvar um croqui offline no Android 13+
- **THEN** o sistema exibe o diálogo nativo solicitando autorização para enviar notificações
- **AND** registra o canal de notificação de downloads do Aresta.

#### Scenario: Primeira solicitação de permissão de notificação no iOS
- **WHEN** o usuário toca para salvar um croqui offline no iOS
- **THEN** o sistema solicita autorização para notificações locais ao usuário.

### Requirement: Notificação Persistente e Manutenção do Processo no Android
No Android, o sistema DEVE (MUST) promover a tarefa de download a um Foreground Service com tipo `dataSync`, exibindo uma notificação contínua (`ongoing: true`) com barra de progresso nativa (`maxProgress: 100`, `progress: X`), mantendo alertas silenciosos a cada atualização de percentual (`onlyAlertOnce: true`) e utilizando exclusivamente o ícone principal do aplicativo (`@mipmap/ic_launcher`, garantido no APK base via `anydpi-v26`) sem carregar `largeIcon` a partir de recursos `drawable` restritos a splits de densidade.

#### Scenario: Atualização contínua do progresso no Android
- **WHEN** novos lotes de arquivos de um pico são recebidos pelo `SyncService`
- **THEN** a notificação na barra de status do Android atualiza o progresso visual e textual (ex: "45%") exibindo o ícone principal `@mipmap/ic_launcher` sem `largeIcon` adicional
- **AND** a notificação não pode ser descartada manualmente enquanto o download estiver ativo.

#### Scenario: Compatibilidade com Split APKs da Google Play Store
- **WHEN** uma notificação de progresso, conclusão ou falha de download é emitida em um dispositivo com o aplicativo instalado via Split APKs oriundos de Android App Bundle (`.aab`)
- **THEN** o sistema resolve apenas `@mipmap/ic_launcher` diretamente no pacote base (`base-master.apk`) sem consultar recursos ausentes do pacote base que provocariam falha de segmentação (`SIGSEGV`) em `libandroidfw.so`.

### Requirement: Continuidade em Segundo Plano e Notificações no iOS
No iOS, o sistema DEVE (MUST) registrar uma tarefa de execução estendida em segundo plano para evitar que o download seja congelado imediatamente ao minimizar o aplicativo. Ao concluir o salvamento de todos os arquivos ou em caso de erro, o sistema DEVE emitir uma notificação local nativa no centro de notificações do iOS alertando o usuário.

#### Scenario: Notificação de conclusão no iOS
- **WHEN** o download de todos os arquivos do croqui é finalizado com o app minimizado no iOS
- **THEN** o sistema emite uma notificação local informando que o croqui está disponível offline.

### Requirement: Transição de Estados ao Concluir ou Falhar
Ao término do processo de download (em ambas as plataformas), o sistema DEVE (MUST):
1. Em caso de sucesso: transitar para notificação dispensável de sucesso ("✓ Download concluído: [Nome do Pico] pronto para uso offline").
2. Em caso de falha: emitir notificação de aviso de erro na conexão, permitindo que o usuário reabra o aplicativo e retente o download.

#### Scenario: Transição para estado de sucesso
- **WHEN** todos os arquivos são validados contra seus checksums SHA-256 e salvos no armazenamento local
- **THEN** a notificação persistente é substituída por uma notificação concluída e dispensável.

#### Scenario: Falha de conexão durante download em background
- **WHEN** a conexão de rede é interrompida durante o download dos arquivos
- **THEN** o serviço tenta reconectar de acordo com a política de retentativas
- **AND** se falhar definitivamente, notifica o usuário sobre a interrupção e descarta arquivos temporários corrompidos.
