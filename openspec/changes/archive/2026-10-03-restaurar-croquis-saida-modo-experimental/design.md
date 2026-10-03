## Context

A arquitetura de dados do Aresta Climb opera em modo isolado entre Produção e Modo Experimental (`editor/experimental`). Ao alternar entre esses modos, o aplicativo utiliza notificadores reativos (`isExperimentalMode` e `editorUrl` em `EditorDeCroqui`) para informar os serviços (`DatasetRepository`, `SyncService`) e as telas.

Atualmente, ao acionar o encerramento do modo experimental:
1. `EditorDeCroqui.nukeExperimentalData()` apaga o diretório experimental e limpa `editorUrl.value = null` antes de desativar `isExperimentalMode`.
2. Ouvintes reativos disparam `datasetRepo.loadEmpty()`, instanciando `ConjuntoDadosCroqui.vazio()`.
3. `SyncService.syncIndex()` roda em segundo plano. Ao receber HTTP `304 Not Modified`, ele verifica se `activeDataset.value == null`. Como `ConjuntoDadosCroqui.vazio()` não é nulo, a restauração do índice local é ignorada.
4. Chamadas assíncronas concorrentes de `syncIndex()` atropelam chamadas a `datasetRepo.init()`, resultando em listas de croquis vazias na UI.

## Goals / Non-Goals

**Goals:**
- Assegurar que ao sair do modo experimental, o catálogo oficial de produção seja restaurado imediatamente na memória e exibido nas telas de Início, Explorar e Meus Croquis.
- Corrigir a verificação de cache HTTP `304 Not Modified` no `SyncService` para recarregar o índice do disco quando a memória estiver vazia (`activeDataset.value == null || activeDataset.value!.isEmpty`).
- Ordenar a desativação do modo experimental e a limpeza de URLs no `EditorDeCroqui` para evitar acessos concorrentes a diretórios já excluídos.
- Coordenar a transição de modo em `main.dart` e `BannerModoExperimental` para que `datasetRepo.init()` prevaleça sobre esvaziamentos prematuros de memória.
- Manter 100% de cobertura de testes unitários e de widget, seguindo TDD e idioma português brasileiro.

**Non-Goals:**
- Não alterar a estrutura binária dos arquivos compilados (`.binarypb`) nem dos schemas de protobuf.
- Não modificar o fluxo de emparelhamento por QR Code ou Cloudflare Relay ao entrar no modo experimental.

## Decisions

### Decisão 1: Detecção de Dataset Vazio em HTTP 304 no `SyncService`
No método `syncIndex()` do `SyncService`, dentro do caso `IndiceUnchanged()`, a condição de recarga local será expandida:
```dart
case IndiceUnchanged():
  if (datasetRepository.activeDataset.value == null ||
      datasetRepository.activeDataset.value!.isEmpty) {
    await _loadLocalIndiceAndNotify(localIndicePath);
  }
```
*Racional*: Mantém a otimização de performance introduzida para evitar re-renderizações desnecessárias quando o dataset já possui dados carregados, mas garante a recuperação imediata do catálogo do disco caso o repositório tenha sido esvaziado durante a mudança de modo.
*Alternativas consideradas*:
- Mudar `loadEmpty()` para atribuir `activeDataset.value = null`: Rejeitado, pois diversos componentes da UI e view models esperam instâncias concretas para evitar null check excessivo ou spinners infinitos.

### Decisão 2: Atomicidade e Sequência de Limpeza em `EditorDeCroqui`
No método `nukeExperimentalData()`, a desconexão do modo experimental (`isExperimentalMode.value = false`) deve preceder ou ocorrer atomicamente com a anulação de `editorUrl.value = null`.
*Racional*: Se `editorUrl` for anulado com `isExperimentalMode` ainda ativo, métodos auxiliares como `editorDeCroqui.indicePath()` continuam apontando para a pasta temporária experimental (`editor/experimental/indice.binarypb`), que acabou de ser apagada fisicamente do sistema de arquivos.

### Decisão 3: Transição Ordenada sem Esvaziamento Prematuro em `main.dart`
No ouvinte `onModeChange` e na ação `onSairModoExperimental`:
1. `onSairModoExperimental` deve executar `await nukeExperimentalData()`, seguido de `await datasetRepo.init()`, garantindo que os dados de produção estejam carregados antes do redirecionamento de navegação para a tela inicial.
2. O ouvinte de mudança de modo em `main.dart` não deve chamar cegamente `datasetRepo.loadEmpty()` de forma síncrona sem garantir que o novo índice do modo ativo seja carregado. Em vez disso, deve invocar `datasetRepo.init()` para ler o catálogo correspondente do disco e, em seguida, sincronizar com o servidor em background.

## Risks / Trade-offs

- **[Risco]** Sobrecarga de I/O de disco em respostas 304 frequentes.
  $\rightarrow$ **Mitigação**: O recarregamento do disco em HTTP 304 só é disparado se a memória estiver efetivamente vazia (`isEmpty`). Se o catálogo já tiver picos carregados, nenhuma leitura de disco ocorre.
- **[Risco]** Concorrência com inicializações paralelas (`_currentInitFuture`).
  $\rightarrow$ **Mitigação**: O `DatasetRepository.init()` já reutiliza a Future em andamento. Ao garantir que o modo experimental é desativado antes de disparar o reload, a Future em andamento executará no contexto correto do diretório de produção.
