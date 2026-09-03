## Why

Quando o usuário opta por salvar um croqui para uso offline, o download envolve o arquivo compilado `.binarypb` e dezenas a centenas de imagens WebP em alta resolução. Caso o usuário minimize o aplicativo, bloqueie a tela ou o sistema operacional entre em modo de economia de energia, o processo em segundo plano pode ser suspenso ou eliminado silenciosamente pelo SO. Isso causa surpresas desagradáveis na base da montanha, onde não há conectividade.

Para garantir que o download termine com resiliência total mesmo com o aplicativo fechado ou em segundo plano, é essencial elevar o processo de download a um **Foreground Service** no Android, acompanhado de uma **notificação contínua e persistente (`ongoing: true`)** na barra de status do sistema, informando visualmente o progresso em tempo real e o sucesso da operação.

## What Changes

- **Serviço de Notificação em Primeiro Plano (Foreground Service)**: Adiciona suporte a Foreground Service no Android com tipo `dataSync`, garantindo prioridade máxima de CPU e rede durante o download.
- **Notificação Contínua no SO**: Exibe e atualiza dinamicamente na bandeja do sistema uma notificação persistente com barra de progresso (`progress: X%`), nome do pico sendo baixado e estado visual em tempo real.
- **Finalização e Tratamento de Erros**:
  - Em caso de sucesso: a notificação transita para "✓ [Nome do Pico] salvo para uso offline" e torna-se dispensável (`ongoing: false`).
  - Em caso de falha: a notificação avisa o erro de conexão e permite toque para reabrir o app.
- **Orquestração Desacoplada**: Conexão entre as emissões de progresso do `SyncService` e o `ServicoDownloadSegundoPlano`, mantendo a UI do app e a bandeja do sistema perfeitamente sincronizadas.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capability de alto nível além das existentes -->

### Modified Capabilities
- `download-segundo-plano-persistente`: Adiciona os requisitos específicos de notificação persistente do sistema operacional (`ongoing: true`, barra de progresso nativa, canal de notificação de alta prioridade e transição de estado pós-download).

## Impact

- **Manifesto Android** (`android/app/src/main/AndroidManifest.xml`): Adição de permissões `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_DATA_SYNC` e `POST_NOTIFICATIONS`.
- **Dependências** (`frontend/pubspec.yaml`): Adição do pacote `flutter_local_notifications` para gestão de canais e notificações de progresso no Android/iOS.
- **Serviços** (`frontend/lib/services/`): Criação do `ServicoNotificacaoDownload` e integração com `ServicoDownloadSegundoPlano` e `SyncService`.
- **Testes** (`frontend/test/`): Mocks e testes unitários/integração para o ciclo de vida das notificações nativas.
