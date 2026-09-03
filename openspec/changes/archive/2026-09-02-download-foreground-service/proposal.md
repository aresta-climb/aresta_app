## Por Que

Quando o usuário opta por salvar um croqui para uso offline, o download engloba o arquivo compilado `.binarypb` e dezenas a centenas de imagens WebP em alta resolução. Caso o usuário minimize o aplicativo, bloqueie a tela ou o sistema operacional entre em economia de bateria, o processo pode ser suspenso ou interrompido silenciosamente pelo sistema operacional. Isso causa surpresas desagradáveis na base da montanha, onde não há conectividade celular.

As duas principais plataformas móveis tratam tarefas em segundo plano de formas distintas:
- **No Android**: O sistema suporta explicitamente **Foreground Services** acompanhados de uma notificação persistente (`ongoing: true`) com barra de progresso em tempo real na barra de status, impedindo que o SO finalize o processo por falta de memória.
- **No iOS**: A Apple não permite o conceito de Foreground Service com notificações persistentes fixas na central de notificações. No ecossistema iOS, a continuidade de downloads ao minimizar o app é garantida através de tarefas de segundo plano do sistema operacional (`beginBackgroundTask` / sessão em segundo plano do `URLSession`), notificando o usuário com alertas locais nativos ao término do salvamento.

Esta proposta unifica o gerenciamento de downloads resilientes com notificações nativas do sistema operacional em ambas as plataformas, respeitando as diretrizes de cada plataforma e os princípios de engenharia do Aresta App (`PRINCIPIOS.md`).

## O Que Muda

- **Suporte Multiplataforma para Download Resiliente**:
  - **Android**: Inicialização de Foreground Service com tipo `dataSync` e emissão de notificação persistente (`ongoing: true`) com barra de progresso nativa em tempo real.
  - **iOS**: Registro de tarefa de execução em segundo plano para proteção contra suspensão imediata e emissão de notificação local de conclusão/alerta via `UNUserNotificationCenter`.
- **Serviço Desacoplado `GerenciadorNotificacaoDownload`**:
  - Encapsula a criação do canal de notificações, pedido de permissões em tempo de execução (`POST_NOTIFICATIONS` no Android 13+ e autorizações no iOS) e controle de ciclo de vida das mensagens.
- **Transição de Estados e Feedback**:
  - Durante o download: atualizações contínuas de percentual no Android (`onlyAlertOnce: true`).
  - Sucesso: notificação dispensável de sucesso ("✓ [Nome do Pico] pronto para uso offline").
  - Falha: notificação de erro informando instabilidade de rede e permitindo retentativa.
- **Conformidade Estrita com `PRINCIPIOS.md`**:
  - Nomenclatura 100% em português brasileiro em todas as classes, métodos, testes e documentação.
  - TDD com 100% de cobertura e mocks isolados para execução rápida no `flutter test`.

## Capacidades

### Novas Capacidades
<!-- Nenhuma nova capability além das existentes -->

### Capacidades Modificadas
- `download-segundo-plano-persistente`: Atualizada para especificar o comportamento multiplataforma (Foreground Service no Android e Tarefa de Segundo Plano no iOS com notificações locais correspondentes).

## Impacto

- **Android** (`android/app/src/main/AndroidManifest.xml`): Declaração de permissões `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_DATA_SYNC` e `POST_NOTIFICATIONS`.
- **iOS** (`ios/Runner/Info.plist`): Configuração de permissões de notificação local e modos de background se aplicável.
- **Dependências** (`frontend/pubspec.yaml`): Adição de `flutter_local_notifications` para entrega das notificações nativas.
- **Serviços** (`frontend/lib/services/notificacoes/`): Implementação de `GerenciadorNotificacaoDownload` e integração com `ServicoDownloadSegundoPlano` e `SyncService`.
- **Testes** (`frontend/test/services/notificacoes/`): Suíte de testes unitários com mocks do plugin nativo, garantindo 100% de cobertura.
