# Proposal

## Why

Ao tocar em um resultado de croqui não baixado na Busca Global (`GlobalSearch`) enquanto o dispositivo está sem conexão (especialmente em Modo Avião, onde o sistema operacional rejeita o socket em menos de 5 ms), a interface apresenta três piscadas visuais indesejadas: (1) o diálogo `"Abrindo <título>..."` é aberto e fechado no mesmo frame (5 ms) enquanto o teclado virtual começa a descer antes da subida do `ModalCroquiSemConexao`; (2) `DatasetRepository.getCroqui` dispara `unawaited(syncAtivo.syncIndex())` antes de saber se o download remoto funcionou, fazendo com que 4 segundos depois (após as 3 tentativas de retry) o `SyncService` chame `_loadLocalIndiceAndNotify` e reemita `activeDataset.value` mesmo offline; e (3) `GlobalSearch._loadAllData()` define `_isLoading = true` mesmo quando já há resultados renderizados, desmontando toda a `ListView` para exibir um spinner por alguns milissegundos e remontando-a em seguida.

## What Changes

- **Exibição com limiar (debounce visual de 150 ms) do diálogo `"Abrindo <título>..."` na Busca Global (`GlobalSearch`)**: Manter a trava `_abrindoDestino = true` imediatamente no primeiro toque (`0 ms`) para bloquear cliques repetidos, mas aguardar `150 ms` antes de abrir visualmente o `showDialog` bloqueante. Caso a resolução conclua ou falhe em menos de `150 ms` (como em croquis locais ou falha imediata em Modo Avião), cancelar o timer e ir direto ao destino ou ao `ModalCroquiSemConexao` sem piscar um modal intermediário.
- **Atualização silenciosa da lista na `GlobalSearch` (`_loadAllData`)**: Ativar `_isLoading = true` (que substitui a `ListView` pelo `CircularProgressIndicator`) apenas quando `_allData` estiver vazio; em recargas reativas disparadas por `activeDataset` ou `versaoNotificador`, manter a lista atual na tela até que a leitura do SQLite termine e substituir `_allData` / `_filteredResults` em um único `setState`.
- **Condicionamento do `syncIndex()` em background e curto-circuito offline em `DatasetRepository.getCroqui`**: Na Etapa 4 de `DatasetRepository.getCroqui`, abortar imediatamente se o `syncIndex()` de fallback resultar em `SyncStatus.offline` e só disparar `unawaited(syncAtivo.syncIndex())` em background quando `carregarCroquiRemoto` obtiver sucesso (`croquiRemoto != null`), evitando retentativas ociosas e notificações redundantes de `activeDataset` 4 segundos após uma falha offline.

## Capabilities

### New Capabilities

### Modified Capabilities
- `busca-global-catalogo`: Ajustar os requisitos de navegação direta por UID e de reatividade da Busca Global para especificar a trava imediata com exibição do modal de carregamento apenas para operações que excedam o limiar visual (`150 ms`) e a recarga silenciosa sem desmontar a lista de resultados já exibida.
- `transmissao-croqui-online`: Atualizar o requisito de curto-circuito de rede offline em `DatasetRepository.getCroqui` para garantir que a sincronização em segundo plano (`unawaited(syncIndex())`) não seja disparada quando o carregamento remoto do croqui falhar por falta de conexão.

## Impact

- `frontend/lib/widgets/busca_global.dart` e `frontend/test/widgets/busca_global_test.dart`
- `frontend/lib/services/repositorio_dataset.dart` e `frontend/test/services/repositorio_dataset_test.dart`
- `frontend/lib/widgets/README.md` e `frontend/lib/services/README.md`
