## Why

Durante o Live Reload no Modo Experimental, o aplicativo passou a recarregar a tela inteira e resetar a rolagem para o topo (`offset = 0.0`) sempre que uma alteração é salva no Editor Desktop. Anteriormente, as alterações de texto e metadados atualizavam as informações localmente e de forma suave e contínua (sem saltos de rolagem nem reconstruções abruptas), mantendo o usuário exatamente na seção do croqui em que estava lendo ou editando.

Essa regressão na experiência de uso decorre de desmontagens transitórias do estado da tela causadas por quedas em `const Scaffold()` no `PageListenableBuilder`, emissões múltiplas e concorrentes no `activeDataset`, purgação agressiva de texturas ativas na GPU (`clearLiveImages()`) e ausência de chaves de preservação de rolagem (`PageStorageKey`) nos componentes com `CustomScrollView` e `SingleChildScrollView`. Além disso, a falta de visibilidade sobre quais arquivos foram efetivamente atualizados durante uma sincronização dificulta o acompanhamento do ciclo de recarga. Corrigir esse comportamento e fornecer diagnósticos detalhados é essencial para restabelecer a estabilidade e a fluidez do Aresta Climb.

## What Changes

- **Resiliência no `PageListenableBuilder`**: Manter o último estado válido resolvido do croqui (`Pico`, `Croqui`, `Setor`, etc.) em memória local no builder para impedir desmontagens transitórias (`const Scaffold()`) durante o processamento de novos binários em disco.
- **Chaves Persistentes de Rolagem (`PageStorageKey`)**: Adicionar `PageStorageKey` determinísticas aos componentes `CustomScrollView` e `SingleChildScrollView` de `PicoDetailsPage`, `SetorPage` e `ViaPage`, garantindo retenção e restauração da posição de rolagem mesmo diante de reconstruções de nós ancestrais.
- **Ciclo Atômico e Coalescido de Live Reload**: Eliminar a chamada redundante a `datasetRepo.init()` em `registrarOuvintesLiveReload` quando `syncService.syncIndex()` já consolida os dados na memória, evitando múltiplos picos concorrentes de notificação no `activeDataset`.
- **Invalidação Cirúrgica de Imagens**: Substituir a purgação global e imediata de texturas ativas (`clearLiveImages()`) por invalidação reativa cirúrgica baseada em SHA-256 e recarga suave em `didUpdateWidget`, prevenindo que cabeçalhos e carrosséis pisquem ou colapsem a geometria da tela.
- **Sincronização Reativa de Metadados em `didUpdateWidget`**: Atualizar campos de estado derivados como `_categories` em `PicoDetailsPage.didUpdateWidget`, refletindo novos textos e informações sem exigir destruição do widget.
- **Diagnóstico e Depuração de Arquivos no `syncIndex`**: Emitir mensagens de depuração claras no terminal (`debugPrint`) listando nominalmente a quantidade e o caminho de todos os arquivos atualizados, renomeados e excluídos durante a efetivação atômica em `SyncService.syncIndex`.
- **Conformidade Estrita com PRINCIPIOS.md**:
  - *I. Tudo em Português*: Todo o código, comentários, documentação, testes, nomes de variáveis, métodos e mensagens de depuração integralmente em português brasileiro.
  - *II. Componentes Independentes*: Solução modular e desacoplada, com `PageListenableBuilder` autossuficiente e chaves declarativas nas páginas.
  - *III. 100% de Test Coverage*: Cobertura integral das rotinas modificadas e criadas em navegação, telas e sincronização.
  - *IV. Imperativo do Teste em Primeiro Lugar (TDD)*: Escrita prévia e execução de testes em falha (Fase Vermelha - Red) antes de qualquer alteração no código de produção (Fase Verde - Green), seguido de refatoração contínua.
  - *V. Testes de Widget em Primeiro Lugar*: Priorização de testes de widget e interface para validar a retenção de rolagem e atualização reativa de ponta a ponta na árvore de widgets antes de descer para unidades.
  - *VI. Simplicidade e Anti-Abstração*: Uso direto dos mecanismos nativos do Flutter (`StatefulWidget`, `PageStorageKey`, `didUpdateWidget`) sem abstrações artificiais ou indireções desnecessárias.
  - *VII. Documentação Contínua e Abrangente*: Docstrings detalhadas (`///`) explicando a intenção das soluções e atualização dos documentos técnicos pertinentes (`frontend/HOT_RELOAD.md`, `frontend/lib/navigation/README.md`, `frontend/lib/services/http/README.md`).

## Capabilities

### New Capabilities
<!-- Nenhuma nova capacidade requerida; a funcionalidade se enquadra na capacidade existente de hot reload. -->

### Modified Capabilities
- `hot-reload-experiencia-usuario`: Exige que eventos de Live Reload preservem estritamente a posição de rolagem (`scroll offset`) e o estado de visualização ativa do usuário em qualquer tela de croqui (`Pico`, `Setor`, `Via`), aplicando ajustes de textos e mídias localmente e emitindo logs de depuração detalhados dos arquivos modificados durante a sincronização do índice.

## Impact

- **Navegação & Builders**: `frontend/lib/navigation/page_listenable_builder.dart`
- **Telas Afetadas**: `frontend/lib/pages/pico.dart`, `frontend/lib/pages/setor.dart`, `frontend/lib/pages/via.dart`
- **Serviço de Sincronização e Live Reload**: `frontend/lib/services/http/sync_service.dart`, `frontend/lib/main.dart` (`registrarOuvintesLiveReload`)
- **Testes de Widget e Unidade (Espelhamento Estrito)**:
  - `frontend/test/navigation/page_listenable_builder_test.dart`
  - `frontend/test/pages/pico_test.dart`
  - `frontend/test/pages/setor_test.dart`
  - `frontend/test/pages/via_test.dart`
  - `frontend/test/services/http/sync_service_test.dart`
  - `frontend/test/main_test.dart`
- **Documentação Técnica Atualizada**:
  - `frontend/HOT_RELOAD.md`
  - `frontend/lib/navigation/README.md`
  - `frontend/lib/services/http/README.md`
