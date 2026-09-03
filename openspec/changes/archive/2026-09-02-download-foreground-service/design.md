## Contexto

O Aresta Climb tem como pilar fundamental o funcionamento offline irrestrito na base da montanha. O método `SyncService.downloadCrag` orquestra o download completo de um pico baixando seu arquivo estruturado `.binarypb` e dezenas de fotografias e mapas de alta resolução, validando cada checksum SHA-256 antes de promover os arquivos para `/downloads/<picoId>/`.

Contudo, durante downloads que demandam dezenas de megabytes, o usuário pode bloquear o smartphone, alternar para mensageiros ou colocar o app em segundo plano.
- **No Android**: É necessário promover o download a um **Foreground Service** associado a uma notificação contínua (`ongoing: true`) com barra de progresso nativa. Isso garante prioridade máxima contra o mecanismo de corte de memória do sistema operacional (Low Memory Killer).
- **No iOS**: A Apple não permite Foreground Services com notificações persistentes fixas na central de notificações. No iOS, a continuidade é viabilizada através de tarefas estendidas de segundo plano (`beginBackgroundTaskWithName`) e notificações locais nativas emitidas no término do processo ou em eventuais falhas.

Este design detalha a arquitetura multiplataforma, os componentes em português brasileiro e a estratégia de testes unitários sem dependência de emuladores para respeitar rigorosamente os **Princípios de Engenharia do Aresta App** (`PRINCIPIOS.md`).

## Objetivos e Não-Objetivos

**Objetivos:**
- Prover notificações nativas em tempo real no Android e iOS durante e após o download de croquis.
- No Android: emitir notificação persistente (`ongoing: true`) com barra de progresso numérica e visual (`maxProgress: 100`, `progress: X`), utilizando o canal dedicado `downloads_croquis`.
- No iOS: registrar tarefa de segundo plano para prevenir suspensão imediata e emitir notificação local de conclusão ("✓ [Nome do Pico] pronto para uso offline").
- Gerenciar permissões de notificação em tempo de execução (`POST_NOTIFICATIONS` no Android 13+ e autorizações no iOS).
- Manter 100% de cobertura de testes automatizados com injeção de dependências e mocks via TDD.

**Não-Objetivos:**
- Reescrever a validação de hashes SHA-256 e gravação atômica em disco já maduras no `SyncService`.
- Tentar contornar as diretrizes oficiais da Apple no iOS (respeitamos as restrições da plataforma sem uso de hacks que rejeitariam o app na App Store).

## Decisões Técnicas e Arquitetura

### Decisão 1: Abstração Mínima e Plugin Multiplataforma (`flutter_local_notifications`)
- **Escolha**: Utilizar o pacote `flutter_local_notifications`.
- **Justificativa**:
  - No Android, fornece integração completa com `NotificationChannel`, `setProgress`, `setOngoing(true)` e suporte a Foreground Services.
  - No iOS, mapeia diretamente para a API oficial `UNUserNotificationCenter`, suportando solicitação nativa de permissões e entrega de alertas locais confiáveis.

### Decisão 2: Diferenciação de Plataforma no `GerenciadorNotificacaoDownload`
- **Abordagem**: A classe `GerenciadorNotificacaoDownload` (`lib/services/notificacoes/gerenciador_notificacao_download.dart`) centraliza a lógica:
  - `inicializar()`: Configura os canais do Android e inicializa as configurações do iOS.
  - `solicitarPermissoes()`: Pede `POST_NOTIFICATIONS` no Android 13+ e permissão de alertas no iOS.
  - `atualizarProgresso(String picoId, String nomePico, double progresso)`:
    - No Android: emite notificação com `ongoing: true`, `showProgress: true` e `onlyAlertOnce: true`.
    - No iOS: não polui a central de notificações com dezenas de alertas parciais, aguardando a finalização.
  - `notificarConclusao(String picoId, String nomePico)`:
    - Em ambas as plataformas: emite notificação dispensável de sucesso com som/alerta de conclusão.
  - `notificarFalha(String picoId, String nomePico)`:
    - Em ambas as plataformas: alerta o usuário sobre interrupção de rede.

### Decisão 3: Identificadores Numéricos Estáveis
- **Abordagem**: Utilizar uma função pura de hash baseada no `picoId` para gerar IDs inteiros determinísticos (`(picoId.hashCode & 0x7FFFFFFF) % 100000`).
- **Justificativa**: Garante que cada atualização de progresso do mesmo pico substitua a notificação anterior no SO em vez de empilhar novas notificações.

### Decisão 4: Configurações de Manifesto e Permissões
- **Android** (`AndroidManifest.xml`):
  ```xml
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC"/>
  ```
- **iOS** (`Info.plist`):
  - Habilitar capacidades de background para processamento de downloads conforme exigido pelo ecossistema Apple.

### Decisão 5: Testabilidade e TDD Estrito
- **Abordagem**: `GerenciadorNotificacaoDownload` recebe uma interface injetável do plugin (`FlutterLocalNotificationsPlugin`).
- **Justificativa**: Permite testar todos os métodos e cenários (inicialização, canais, progresso, conclusão, falha e cancelamento) localmente via `flutter test` com 100% de cobertura, sem necessitar de dispositivos físicos ou emuladores conectados.

## Riscos e Mitigações

- **[Risco] O usuário recusa permissão de notificação** $\rightarrow$ **Mitigação**: O download prossegue normalmente em segundo plano no app; as chamadas de notificação capturam a recusa de forma graciosa sem lançar exceções.
- **[Risco] iOS suspender download de croqui gigante se a tela for bloqueada por muito tempo** $\rightarrow$ **Mitigação**: Adoção de `beginBackgroundTaskWithName` garante tempo estendido para conclusão dos downloads; o app retoma imediatamente se o usuário reabrir o app.
