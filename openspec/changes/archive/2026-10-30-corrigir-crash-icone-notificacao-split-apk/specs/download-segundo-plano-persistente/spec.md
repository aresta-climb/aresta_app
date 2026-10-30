# Spec Delta

## MODIFIED Requirements

### Requirement: Notificação Persistente e Manutenção do Processo no Android
No Android, o sistema DEVE (MUST) promover a tarefa de download a um Foreground Service com tipo `dataSync`, exibindo uma notificação contínua (`ongoing: true`) com barra de progresso nativa (`maxProgress: 100`, `progress: X`), mantendo alertas silenciosos a cada atualização de percentual (`onlyAlertOnce: true`) e utilizando exclusivamente o ícone principal do aplicativo (`@mipmap/ic_launcher`, garantido no APK base via `anydpi-v26`) sem carregar `largeIcon` a partir de recursos `drawable` restritos a splits de densidade.

#### Scenario: Atualização contínua do progresso no Android
- **WHEN** novos lotes de arquivos de um pico são recebidos pelo `SyncService`
- **THEN** a notificação na barra de status do Android atualiza o progresso visual e textual (ex: "45%") exibindo o ícone principal `@mipmap/ic_launcher` sem `largeIcon` adicional
- **AND** a notificação não pode ser descartada manualmente enquanto o download estiver ativo.

#### Scenario: Compatibilidade com Split APKs da Google Play Store
- **WHEN** uma notificação de progresso, conclusão ou falha de download é emitida em um dispositivo com o aplicativo instalado via Split APKs oriundos de Android App Bundle (`.aab`)
- **THEN** o sistema resolve apenas `@mipmap/ic_launcher` diretamente no pacote base (`base-master.apk`) sem consultar recursos ausentes do pacote base que provocariam falha de segmentação (`SIGSEGV`) em `libandroidfw.so`.
