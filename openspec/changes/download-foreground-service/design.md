## Contexto

Atualmente o aplicativo possui o método `SyncService.downloadCrag`, que orquestra o download do `.binarypb` e de todas as imagens associadas a um pico, emitindo o progresso percentual (`0.0` a `1.0`) através do `ValueNotifier<Map<String, double>> downloadingCrags`. A interface do app reage a esse progresso no `BannerModoOnline` e nos cards de exploração.

No entanto, toda essa execução reside apenas no ciclo de vida em primeiro plano do processo Flutter. Se o usuário bloquear o smartphone, mudar de aplicativo ou se o Android entrar em economia de bateria, o processo pode ser suspenso antes do término. Para transformar essa operação em uma experiência de alta confiabilidade, é necessário integrar as notificações nativas do sistema operacional (`flutter_local_notifications`) com comportamento de notificação persistente (`ongoing: true`) e declaração de serviço de sincronização de dados (`FOREGROUND_SERVICE_DATA_SYNC`).

## Objetivos e Não-Objetivos

**Objetivos:**
- Exibir e atualizar uma notificação persistente (`ongoing: true`) com barra de progresso em tempo real na barra de status do Android/iOS durante o download de qualquer croqui.
- Declarar o canal de notificação oficial `downloads_croquis` com prioridade e comportamento silencioso para atualizações frequentes (`onlyAlertOnce: true`).
- Solicitar a permissão de notificações `POST_NOTIFICATIONS` no Android 13+ de forma transparente.
- Atualizar a notificação para status de sucesso ("Download concluído") tornando-a dispensável (`ongoing: false`) ao finalizar.
- Preservar a cobertura de testes de 100% via TDD com injeção de dependência / mocks do plugin nativo.

**Não-Objetivos:**
- Substituir a lógica interna de verificação atômica de arquivos e hashes SHA-256 já existente no `SyncService`.
- Implementar filas complexas de download concorrente em massa (o fluxo atual baixa um croqui selecionado pelo usuário por vez).

## Decisões Técnicas e Arquitetura

### Decisão 1: Plugin de Notificação Nativo (`flutter_local_notifications`)
- **Escolha**: Adicionar `flutter_local_notifications` ao `pubspec.yaml`.
- **Justificativa**: É a biblioteca padrão do ecossistema Flutter para exibição e controle detalhado de notificações na bandeja do SO, suportando canais no Android 8.0+, barras de progresso nativas (`showProgress: true`, `maxProgress: 100`), flags persistentes (`ongoing: true`) e controle de alertas sonoros únicos (`onlyAlertOnce: true`).

### Decisão 2: Permissões Nativas no `AndroidManifest.xml`
- **Escolha**: Incluir as seguintes permissões:
  - `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>`
  - `<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>`
  - `<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC"/>`
- **Justificativa**: Adequação às diretrizes do Google Play para Android 13 (Tiramisu) e Android 14 (UpsideDownCake) para serviços que realizam download de dados essenciais para uso offline.

### Decisão 3: `ServicoNotificacaoDownload` (Componente Independente)
- **Abordagem**: Criar a classe `ServicoNotificacaoDownload` em `lib/services/notificacoes/servico_notificacao_download.dart`.
- **Responsabilidades**:
  1. Inicializar o plugin e registrar o canal de notificação `downloads_croquis`.
  2. `atualizarProgresso(String picoId, String nomePico, double progresso)`: Converte o progresso (0.0 a 1.0) para inteiro (0 a 100) e emite notificação persistente.
  3. `notificarSucesso(String picoId, String nomePico)`: Transita para notificação dispensável de sucesso.
  4. `notificarFalha(String picoId, String nomePico)`: Transita para notificação de erro.
  5. `cancelar(String picoId)`: Remove a notificação da bandeja.

### Decisão 4: Identificador Numérico Estável por Pico
- **Abordagem**: Gerar um `int idNotificacao` determinístico a partir do hash do `picoId` (ex: `picoId.hashCode.abs() % 100000`).
- **Justificativa**: Garante que múltiplos picos ou atualizações sucessivas do mesmo pico atualizem exatamente a mesma notificação sem poluir a bandeja com notificações duplicadas.

### Decisão 5: Testabilidade e TDD Estrito
- **Abordagem**: `ServicoNotificacaoDownload` aceita uma interface ou wrapper injetável de `FlutterLocalNotificationsPlugin`, permitindo testar todos os cenários (início, progresso, sucesso, falha e cancelamento) em testes unitários e de integração locais sem exigir emulador aberto.

## Riscos e Mitigações

- **[Risco] O usuário nega a permissão de notificação no Android 13+** $\rightarrow$ **Mitigação**: O download continua normalmente em background/foreground; a notificação falha silenciosamente sem quebrar o fluxo de download.
- **[Risco] Atualizações frequentes de progresso engasgarem a UI ou a IPC do Android** $\rightarrow$ **Mitigação**: Atualizar a notificação apenas quando a variação de porcentagem for de pelo menos 2% ou a cada chunk de arquivo, com `onlyAlertOnce: true`.
