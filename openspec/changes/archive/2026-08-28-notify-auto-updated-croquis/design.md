## Context

O `SyncService` orquestra o ciclo de vida de sincronização do Aresta, baixando o `indice.binarypb` e verificando quais croquis armazenados localmente (na pasta de downloads) precisam de atualização delta por terem tido seu `checksumSha256Croqui` alterado no servidor.

Atualmente, existem duas formas de sincronização no app:
1. **Sincronização Explícita / Manual (`auto: false`)**: Acionada diretamente pelo usuário ao clicar no botão "Sincronizar" nas Configurações ou ao fazer scroll para baixo (*pull-to-refresh* via `RefreshIndicator`) na tela Home. Nesse fluxo (`sincronizar()` em `common_functions.dart`), o usuário sempre recebe feedback visual imediato em todos os cenários (se houve atualizações, se não havia atualizações a fazer, se está offline ou se houve erro). Esse fluxo permanece **intacto e sem alterações**.
2. **Sincronização Automática de Abertura (`auto: true`)**: Disparada em segundo plano quando o aplicativo é inicializado (`main.dart`). Atualmente, `TreeNavigationWrapper` escuta o `syncStatus` e só reage em caso de erro. Quando ocorrem atualizações em croquis baixados pelo usuário, nada é exibido.

O objetivo deste design é introduzir uma notificação via SnackBar (`"Seus croquis baixados foram atualizados!"`) exclusivamente no fluxo automático de abertura quando **croquis baixados** forem efetivamente atualizados, mantendo o silêncio caso apenas o catálogo tenha mudado ou caso não haja novidades (HTTP 304).

Todas as definições seguem rigorosamente as diretrizes de [PRINCIPIOS.md](file:///c:/Renato/Devel/aresta-climb/aresta_app/PRINCIPIOS.md):
- **Tudo em Português** (I): Nomenclatura 100% em português brasileiro (`quantidadeCroquisBaixadosAtualizadosNoUltimoSync`).
- **TDD e Testes de Widget em Primeiro Lugar** (IV e V): Especificação de fluxos de teste antes da implementação.
- **100% de Cobertura de Testes** (III).
- **Simplicidade e Anti-Abstração** (VI): Sem camadas ou wrappers desnecessários; uso direto de `ValueNotifier`.
- **Documentação Abrangente** (VII): Docstrings explicativas em `///` e atualização dos arquivos `README.md`.

## Goals / Non-Goals

**Goals:**
- Identificar e rastrear no `SyncService` a contagem de croquis baixados que foram atualizados durante o ciclo de sincronização através de `quantidadeCroquisBaixadosAtualizadosNoUltimoSync` (`ValueNotifier<int>`).
- Exibir SnackBar com a mensagem `"Seus croquis baixados foram atualizados!"` (com a cor `context.colors.dryMoss`) no `TreeNavigationWrapper` quando a sincronização for a **automática de abertura** (`lastSyncWasAuto == true`) e houver croquis baixados atualizados (`quantidadeCroquisBaixadosAtualizadosNoUltimoSync > 0`).
- Permanecer em silêncio quando a sincronização automática de abertura resultar apenas em atualizações do catálogo/índice (sem croquis locais baixados afetados) ou em 304 Not Modified (`noNewUpdates`).
- Preservar integralmente o comportamento existente de feedback da sincronização explícita/manual (botão nas configurações e *pull-to-refresh* na Home via `common_functions.dart`).
- Adicionar docstrings em português (`///`) e atualizar a documentação nos arquivos `README.md`.
- Assegurar 100% de cobertura de testes (widget e unitários).

**Non-Goals:**
- Alterar o comportamento da sincronização manual/pull-to-refresh (`common_functions.dart`), que continua fornecendo feedbacks explícitos para todas as situações ("Nenhum croqui precisava ser atualizado", "Croquis foram atualizados!", "Sem conexão", etc.).
- Alterar a mecânica interna de atomicidade ou lock de croqui aberto (`recarga_pendente_pico_id`).

## Decisions

### 1. Nomenclatura em Português e Reatividade no `SyncService` (Princípios I, VI)
- **Decisão**: Adicionar o notificador reativo `final ValueNotifier<int> quantidadeCroquisBaixadosAtualizadosNoUltimoSync = ValueNotifier<int>(0);` no `SyncService`.
- **Funcionamento**: 
  - Ao iniciar `syncIndex()`, o valor é resetado para `0`.
  - Durante `_checkForUpdates()`, caso croquis locais presentes no disco recebam com sucesso novos arquivos/metadados, o contador é incrementado e atribuído ao notificador antes de acionar `setUpdatedStatus()`.
- **Justificativa**: Respeita o Princípio I (Tudo em Português) e Princípio VI (Simplicidade), utilizando a estrutura nativa de `ValueNotifier` do Flutter sem criar classes intermediárias redundantes.

### 2. Feedback Visual no `TreeNavigationWrapper` para Sincronização de Abertura (Princípios II, V)
- **Decisão**: Em `_TreeNavigationWrapperState._onSyncStatusChanged` (`main.dart`), ao receber o status `SyncStatus.justUpdated`, validar se a sincronização foi automática (`widget.syncService.lastSyncWasAuto.value == true`) e se houve croquis baixados atualizados (`widget.syncService.quantidadeCroquisBaixadosAtualizadosNoUltimoSync.value > 0`). Em caso positivo, disparar a SnackBar via `ScaffoldMessenger.of(context)`.
- **Estilo visual**:
  - Mensagem: `'Seus croquis baixados foram atualizados!'`
  - Cor de fundo: `context.colors.dryMoss`
  - Duração: 4 segundos.

### 3. Estratégia de Testes TDD (Princípios III, IV, V)
1. **Testes de Widget (`test/main_test.dart` ou `test/widgets/tree_navigation_wrapper_test.dart`)**:
   - Cenário: Auto-sync de abertura conclui com `justUpdated` e `quantidadeCroquisBaixadosAtualizadosNoUltimoSync > 0` -> SnackBar com texto "Seus croquis baixados foram atualizados!" DEVE ser encontrada na tela.
   - Cenário: Auto-sync de abertura conclui com `justUpdated` mas `quantidadeCroquisBaixadosAtualizadosNoUltimoSync == 0` (somente índice/catálogo mudou) -> Nenhuma SnackBar DEVE ser exibida.
   - Cenário: Auto-sync de abertura conclui com `noNewUpdates` (HTTP 304) -> Nenhuma SnackBar DEVE ser exibida.
2. **Testes Unitários (`test/services/http/sync_service_test.dart`)**:
   - Validar que `quantidadeCroquisBaixadosAtualizadosNoUltimoSync` é resetada para `0` no início do sync.
   - Validar que o contador reflete o número exato de picos baixados atualizados após `_checkForUpdates`.

## Risks / Trade-offs

- **[Contexto desmontado antes do término do sync]** → Mitigação: Sempre validar `if (mounted)` antes de invocar `ScaffoldMessenger.of(context)`.
- **[Sincronizações repetidas ou consecutivas]** → Mitigação: `quantidadeCroquisBaixadosAtualizadosNoUltimoSync` é resetada no início de toda invocação de `syncIndex()`.
