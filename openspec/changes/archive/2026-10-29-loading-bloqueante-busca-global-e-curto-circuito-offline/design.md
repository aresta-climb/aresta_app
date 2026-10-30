# Design

## Context

Conforme detalhado em `proposal.md - Why`, o fluxo atual de toque em resultados da Busca Global (`GlobalSearch._abrirDestinoPorUid`) executa a resolução de UID e o eventual download sob demanda do croqui em segundo plano sem bloquear a interface e sem feedback visual imediato. Além disso, na Etapa 4 de `DatasetRepository.getCroqui`, quando `syncAtivo.syncIndex()` falha por falta de conexão (`SyncStatus.offline`), o código prossegue e dispara uma segunda requisição HTTP via `servicoCroquiOnline.carregarCroquiRemoto`, duplicando o tempo de espera em modo offline.

Todas as decisões abaixo seguem estritamente os 8 princípios do `AGENTS.md` (código 100% em português brasileiro, modularidade, TDD com ciclo *Red-Green-Refactor*, espelhamento 1:1 de testes, 100% de cobertura comportamental e ausência de mocks internos).

## Goals / Non-Goals

**Goals:**
- Garantir feedback visual imediato e bloqueio de toques repetidos ao selecionar qualquer item na Busca Global (`GlobalSearch`).
- Garantir que apenas uma única instância de `ModalCroquiSemConexao` possa ser aberta por interação na Busca Global.
- Eliminar a segunda requisição HTTP redundante em `DatasetRepository.getCroqui` (e consultas extras em `LocalizadorDestinoUid`) quando a primeira requisição (`syncIndex`) já tiver constatado ausência de conexão (`SyncStatus.offline`).

**Non-Goals:**
- Alterar o layout ou comportamento interno do `ModalCroquiSemConexao`.
- Alterar a lógica de cache em `/downloads` ou `/temp_cache`.

## Decisions

### 1. Trava de Concorrência (`_abrindoDestino`) e Diálogo Modal Bloqueante em `GlobalSearch`
- **Decisão**:
  - Adicionar um campo booleano `_abrindoDestino = false` em `_GlobalSearchState`.
  - No início de `_abrirDestinoPorUid` (e no `onTap` de `_criarResultadoResumoPico`), se `_abrindoDestino` for `true`, retornar imediatamente.
  - Caso contrário, definir `_abrindoDestino = true`, recolher o foco do campo de texto (`_searchFocusNode.unfocus()`) e exibir um diálogo modal bloqueante (`showDialog` com `barrierDismissible: false` e `PopScope(canPop: false)`) apresentando um card compacto na paleta `AppColors` com `CircularProgressIndicator` e o texto `"Abrindo $titulo..."`.
  - Envolver a resolução (`localizador.localizarComDiagnostico(uid)`) em `try/finally` para garantir que o diálogo de carregamento seja sempre fechado (`Navigator.of(context, rootNavigator: true).pop()`) e `_abrindoDestino` seja restaurado para `false` antes de navegar para o destino ou de abrir o `ModalCroquiSemConexao`.
- **Alternativas consideradas**:
  - *Substituir a lista de resultados por um spinner inline dentro do próprio `GlobalSearch`*: Descartado porque ainda permitiria ao usuário tocar na barra de busca, nos filtros ou fechar/reabrir estados parciais, enquanto o diálogo modal bloqueante (`showDialog` com `barrierDismissible: false`, análogo ao já utilizado em `handlePicoSelection`) bloqueia toda a tela de forma uniforme.

### 2. Curto-Circuito de `SyncStatus.offline` em `DatasetRepository.getCroqui` e `LocalizadorDestinoUid`
- **Decisão**:
  - Em `DatasetRepository.getCroqui` (Etapa 4 - Rede remota): logo após `await syncAtivo.syncIndex()`, verificar `if (syncAtivo.syncStatus.value == SyncStatus.offline) return null;`. Se a sincronização do índice acabou de falhar por falta de conexão, não há razão para disparar uma segunda requisição HTTP para `carregarCroquiRemoto`.
  - Em `LocalizadorDestinoUid.localizarComDiagnostico`: no bloco `if (itemLocal == null)` que invoca `await sync.syncIndex()`, verificar `if (sync.syncStatus.value == SyncStatus.offline) return const ResultadoBuscaDestinoUid();`, evitando reconsultar o SQLite local quando nenhuma atualização pôde ser baixada.
- **Alternativas consideradas**:
  - *Pular `syncIndex()` completamente em `getCroqui`*: Descartado porque, quando online, o `syncIndex()` garante que o `checksumSha256Croqui` usado na URL `?v=<sha256>` da CDN seja o mais recente publicado. Manter o `syncIndex()` e curto-circuitar se ele falhar offline preserva a consistência de cache-busting online e elimina a segunda requisição redundante offline.

## Risks / Trade-offs

- **[Risco] Descarte do widget `GlobalSearch` enquanto o diálogo bloqueante está aberto** → **Mitigação**: Capturar o `NavigatorState` (`Navigator.of(context, rootNavigator: true)`) antes do `await` e verificar `mounted` / fechar o diálogo de carregamento com segurança no bloco `finally` antes de qualquer navegação ou abertura de *bottom sheet*.
