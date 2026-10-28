# Proposal

## Why

Ao abrir qualquer croqui no aplicativo (seja pela aba "Meus Croquis", "Home" ou "Explorar"), a rotina `DatasetRepository.updatePriorityAfterNavigation` reconstrói toda a lista de croquis baixados do zero a partir de `picosDisponiveis`, descartando os objetos `Croqui` já residentes em memória, varrendo o disco para todos os itens do catálogo, relendo e redesserializando os arquivos `compilado.binarypb` de todos os croquis salvos offline e invocando `ExtratorMetadadosCroqui._resolverCapaPath` (`ProvedorImagemAresta.preCarregarNoDisco`) para resolver imagens de capa cujo resultado (`ResumoPico.capaPath`) sequer é consumido pela camada de UI atual. Esse mesmo desperdício de I/O em série e reprocessamento integral ocorre em `loadIndiceToMemory` e `_refreshActiveDataset`, gerando contenção de disco e CPU durante transições de navegação e na inicialização do aplicativo.

## What Changes

- **Reordenação em Memória ao Navegar (`updatePriorityAfterNavigation`)**: Atualiza a lista de prioridade no arquivo `recent_picos.yaml` e, caso o croqui aberto pertença aos croquis baixados, reordena diretamente em memória as listas `picosBaixados` e `croquisBaixados` já carregadas no `activeDataset`, sem varrer `picosDisponiveis` no disco, sem reler `compilado.binarypb` e sem chamar `ExtratorMetadadosCroqui`.
- **Simplificação do `ExtratorMetadadosCroqui` e Remoção de Resolução Antecipada de Capas**: Remove a busca antecipada de arquivos de capa em disco (`_resolverCapaPath` e `ProvedorImagemAresta.preCarregarNoDisco` durante o carregamento de metadados) e remove o método legado sem uso `atualizarMetadadosPico`, mantendo `carregarMetadadosLocais` focado exclusivamente em vincular as entidades Protobuf `Croqui` e `Pico` ao `ResumoPico`. As capas e miniaturas continuam sendo resolvidas sob demanda pelos widgets visíveis via `ProvedorImagemAresta.resolver`.
- **Otimização de `loadIndiceToMemory` e `_refreshActiveDataset`**:
  - Substitui o loop sequencial de `await verificarPicoBaixado` por verificação em paralelo (`Future.wait`) e elimina a duplicação de mapeamento em `loadIndiceToMemory` reutilizando `ExtensaoMetadadosIndice.paraResumoPico`.
  - Preserva e reaproveita em `_refreshActiveDataset` e `loadIndiceToMemory` as instâncias de `ResumoPico` / `Croqui` já carregadas em memória para croquis baixados que permaneceram inalterados, lendo do disco apenas croquis recém-baixados ou ainda não carregados.

## Capabilities

### New Capabilities

<!-- Nenhuma nova capability precisa ser criada. -->

### Modified Capabilities

- `sincronizacao-cache-croquis`: Atualiza os requisitos de carregamento de metadados locais, resolução de capas sob demanda e manutenção em memória dos croquis baixados (`loadIndiceToMemory`, `_refreshActiveDataset` e `updatePriorityAfterNavigation`) para evitar releituras redundantes de `compilado.binarypb` e buscas antecipadas de imagens de capa em disco.

## Impact

- **`frontend/lib/services/dataset/metadados/extrator_metadados_croqui.dart`**: Simplificação de `carregarMetadadosLocais` (remoção de `_resolverCapaPath` e remoção do método morto `atualizarMetadadosPico`).
- **`frontend/lib/services/repositorio_dataset.dart`**: Otimização de `loadIndiceToMemory`, `updatePriorityAfterNavigation` e `_refreshActiveDataset` para preservar instâncias já carregadas em memória, paralelizar verificações de armazenamento local e delegar a criação de `ResumoPico` para `ExtensaoMetadadosIndice.paraResumoPico`.
- **`frontend/lib/services/dataset/modelos/metadados_indice.dart`**: Ajuste em `paraResumoPico` para respeitar a presença de `checksumSha256Thumbnail` ao definir `thumbnailUrl` (mantendo paridade exata com `loadIndiceToMemory`).
- **Testes espelhados (`frontend/test/services/dataset/extrator_metadados_croqui_test.dart` e `frontend/test/services/repositorio_dataset_test.dart`)**: Atualização e adição de testes orientados a comportamento validando a reordenação em memória sem releitura de disco e o reaproveitamento de croquis carregados.
