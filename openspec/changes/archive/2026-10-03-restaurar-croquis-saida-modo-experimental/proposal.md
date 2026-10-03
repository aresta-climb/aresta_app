## Why

Ao clicar no botão de encerramento do modo experimental ("SAIR" no `BannerModoExperimental`), o aplicativo passa a exibir todas as telas de exploração, início e croquis baixados vazias ("Nenhum pico encontrado", "Nenhum croqui salvo offline ainda"), como se não houvesse croquis cadastrados no sistema. Isso ocorre devido a uma condição de corrida entre os ouvintes de transição de modo em `main.dart` (que invocam `datasetRepo.loadEmpty()` sem aguardar a reinicialização) e a uma checagem inadequada no `SyncService` que ignora o recarregamento do índice oficial em respostas HTTP `304 Not Modified` quando `activeDataset.value` já contém uma instância vazia (`ConjuntoDadosCroqui.vazio()`).

## What Changes

- **Recarga do catálogo oficial em HTTP 304**: Modificar o `SyncService` para que, ao receber `304 Not Modified`, recarregue os dados locais não apenas quando `activeDataset.value == null`, mas também quando o repositório em memória estiver vazio (`activeDataset.value!.isEmpty`).
- **Limpeza e desconexão atômica no `EditorDeCroqui`**: Reordenar e unificar a limpeza em `nukeExperimentalData()` para desativar `isExperimentalMode` e resetar `editorUrl` de maneira coordenada, evitando acessos de leitura ao caminho do diretório experimental que foi recém-excluído.
- **Sincronização ordenada na saída do modo experimental**: Ajustar os ouvintes de mudança de modo e a ação `onSairModoExperimental` em `main.dart` para que o repositório local seja reinicializado (`datasetRepo.init()`) com a base de produção antes de disparar a sincronização em segundo plano, evitando que chamadas paralelas a `loadEmpty()` sobrescrevam os dados recém-carregados.

## Capabilities

### Modified Capabilities

- `hot-reload-experiencia-usuario`: O encerramento do modo experimental através do banner rápido MUST restaurar compulsoriamente os croquis e picos oficiais de produção na memória do aplicativo, garantindo que o usuário visualize os dados de produção imediatamente ao retornar à tela inicial sem telas vazias.

## Impact

- `frontend/lib/services/http/sync_service.dart`: Correção do tratamento de `IndiceUnchanged` (304) para contemplar datasets vazios.
- `frontend/lib/services/editor_croqui.dart`: Ajuste da ordem no `nukeExperimentalData()` e desativação do modo experimental.
- `frontend/lib/main.dart`: Ajuste no manipulador `onModeChange` e no callback `onSairModoExperimental` do `BannerModoExperimental`.
- Testes unitários e de widgets em `frontend/test/` para cobrir 100% dos cenários de transição de modo e restauração de dados.
