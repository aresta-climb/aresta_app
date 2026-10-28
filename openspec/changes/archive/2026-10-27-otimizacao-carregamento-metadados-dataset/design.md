# Design

## Context

Conforme detalhado em `proposal.md`, o `DatasetRepository` mantém em memória o `ConjuntoDadosCroqui` (`activeDataset`), contendo os metadados do catálogo (`metadadosDisponiveis` / `picosDisponiveis`) e os croquis salvos localmente (`croquisBaixados` / `picosBaixados`). Atualmente, três fluxos (`loadIndiceToMemory`, `updatePriorityAfterNavigation` e `_refreshActiveDataset`) apresentam redundâncias de I/O e processamento:

1. `updatePriorityAfterNavigation` descarta as instâncias já carregadas em `activeDataset.value!.picosBaixados`, varre todos os itens de `picosDisponiveis` no disco via `verificarPicoBaixado`, e chama `extratorMetadados.carregarMetadadosLocais` para todos os croquis baixados — provocando releitura e redesserialização de `compilado.binarypb` e chamadas a `_resolverCapaPath` (`ProvedorImagemAresta.preCarregarNoDisco`) no meio da transição de navegação para a página do pico.
2. `_refreshActiveDataset` (chamado após `updateDatasetAfterDownload` e `deleteCrag`) também descarta os objetos `ResumoPico` / `Croqui` já carregados em `picosBaixados` e relê todos os croquis baixados do disco.
3. `ExtratorMetadadosCroqui` executa `_resolverCapaPath` (com I/O de disco e risco de fallback de rede via `ProvedorImagemAresta.preCarregarNoDisco`) para preencher `ResumoPico.capaPath`, campo que não é consumido por nenhuma tela de produção desde a adoção de `CardCroquiViewModel` (`_CardCroquiMetadados` e `_CardCroquiCroqui`) e `ProvedorImagemAresta.resolver`.
4. `loadIndiceToMemory` executa `await verificarPicoBaixado` sequencialmente dentro de um laço `for` sobre todo o catálogo e duplica 68 linhas de mapeamento que já existem em `ExtensaoMetadadosIndice.paraResumoPico`.

## Goals / Non-Goals

**Goals:**
- Tornar `updatePriorityAfterNavigation` uma operação puramente em memória após persistir `recent_picos.yaml`, eliminando leituras de `compilado.binarypb` e buscas de imagem de capa ao abrir um croqui.
- Simplificar `ExtratorMetadadosCroqui` removendo `_resolverCapaPath` e o método morto `atualizarMetadadosPico`.
- Paralelizar a verificação de picos baixados e reaproveitar instâncias de `ResumoPico` / `Croqui` já carregadas em `loadIndiceToMemory` e `_refreshActiveDataset`.
- Unificar a conversão de `ResumoCroqui` (`MetadadosIndice`) para `ResumoPico` usando `ExtensaoMetadadosIndice.paraResumoPico`.

**Non-Goals:**
- Alterar o contrato visual ou a hierarquia de cache de `ProvedorImagemAresta.resolver` quando invocado pelos widgets (`CragCard`, `PicoDetailsPage`, `OfflineMarkdown`).
- Alterar o formato de persistência de `recent_picos.yaml` ou a estrutura Protobuf de `Indice` e `Croqui`.

## Decisions

### 1. Reordenação em Memória em `updatePriorityAfterNavigation`
- **Decisão**: Em `DatasetRepository.updatePriorityAfterNavigation(String id)`, após persistir o `id` no topo de `recent_picos.yaml` via `gerenciadorPrioridade.atualizarPrioridade(docsPath, id)`:
  - Verificar se `activeDataset.value` não é nulo e se `id` pertence a `activeDataset.value!.picosBaixados`.
  - Caso o pico não esteja baixado (navegação online) ou já seja o primeiro elemento de `picosBaixados`, encerrar imediatamente sem emitir nova notificação em `activeDataset`.
  - Caso esteja em `picosBaixados` em outra posição, obter a lista de prioridade atualizada e reordenar diretamente a lista `activeDataset.value!.picosBaixados` existente em memória via `gerenciadorPrioridade.ordenarPorPrioridade`, derivando `croquisBaixados` das instâncias já carregadas em `picosBaixados`.
- **Racional**: Evita 100% das chamadas de sistema de arquivos (`verificarPicoBaixado`), releituras de `compilado.binarypb` e notificações desnecessárias da UI durante a animação de abertura da página do croqui.
- **Alternativas consideradas**:
  - *Manter a verificação em disco mas passar `parsedCroqui`*: Ainda realizaria `N` chamadas `File.exists()` no catálogo a cada abertura de croqui sem necessidade.

### 2. Simplificação de `ExtratorMetadadosCroqui` e Remoção de `_resolverCapaPath`
- **Decisão**:
  - Remover `_resolverCapaPath` de `ExtratorMetadadosCroqui.carregarMetadadosLocais`, de modo que o método apenas resolva o `Croqui` (usando `parsedCroqui` ou delegando ao repositório) e retorne `pico.copyWith(croqui: croqui, pico: croqui.picos.isNotEmpty ? croqui.picos.first : null)`.
  - Remover o método legado `atualizarMetadadosPico` (baseado em `Map<String, dynamic>`), que não possui nenhum chamador em produção (Princípio IV e VI do `AGENTS.md`).
- **Racional**: Na arquitetura MVVM atual, `CragCard` e `PicoDetailsPage` resolvem miniaturas (`thumbnails/<id>.webp`) e capas (`croqui.caminhoThumbnail`) sob demanda via `ProvedorImagemAresta.resolver` com `larguraAlvo` adequada apenas para os elementos visíveis na viewport. Resolver `capaPath` antecipadamente para todos os croquis baixados gera I/O de disco desnecessário, logs enganosos e risco de requisições HTTP acidentais caso algum arquivo local esteja ausente.

### 3. Reaproveitamento de Instâncias em Memória e Verificação Paralela em `loadIndiceToMemory` e `_refreshActiveDataset`
- **Decisão**:
  - Em `loadIndiceToMemory`, usar `ExtensaoMetadadosIndice.paraResumoPico` (ajustando `paraResumoPico` para preencher `thumbnailUrl` apenas quando `hasChecksumSha256Thumbnail() && checksumSha256Thumbnail.isNotEmpty`, preservando o comportamento exato de `loadIndiceToMemory`) e executar a verificação `verificarPicoBaixado` em paralelo via `Future.wait`.
  - Criar um mapa auxiliar dos picos já carregados em `activeDataset.value?.picosBaixados` (`id -> ResumoPico`). Tanto em `_refreshActiveDataset` quanto em `loadIndiceToMemory`, se um pico baixado já possuir `croqui != null` em memória (e, no caso de `loadIndiceToMemory`, o `checksum` não tiver mudado), reutilizar o `croqui` já desserializado passando `parsedCroqui: existente.croqui` para `extratorMetadados.carregarMetadadosLocais`.
- **Racional**: Ao baixar um novo croqui ou excluir um croqui existente (`_refreshActiveDataset`), os demais croquis baixados não precisam ser relidos e redesserializados do disco.

## Risks / Trade-offs

- **[Risco] Testes legados que inspecionavam `capaPath` preenchido por `ExtratorMetadadosCroqui`** → **Mitigação**: Atualizar `extrator_metadados_croqui_test.dart` para validar o contrato enxuto de `carregarMetadadosLocais` e `extrairCapaPathFromMarkdown`, mantendo os testes de `ResumoPico` e `CragCard` que testam seus próprios campos isoladamente.
- **[Risco] Divergência sutil em `thumbnailUrl` ao unificar `loadIndiceToMemory` com `ExtensaoMetadadosIndice.paraResumoPico`** → **Mitigação**: Garantir em `ExtensaoMetadadosIndice.paraResumoPico` que `thumbnailUrl` seja vazia (`''`) quando `checksumSha256Thumbnail` estiver vazio, exatamente como validado pelo teste existente em `repositorio_dataset_test.dart`.
