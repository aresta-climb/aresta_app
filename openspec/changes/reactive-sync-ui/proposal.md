## Why

Atualizações recentes introduziram o download de arquivos de croquis em segundo plano utilizando `Isolates`, mas a implementação deixou de limpar a flag de estado de download após a conclusão, fazendo com que os cards de croqui ("picos") fiquem em um estado visual permanente de "baixando" até que o aplicativo seja reiniciado. Além disso, a interface de usuário atualmente bloqueia interações com picos que estão sendo atualizados em segundo plano. Visto que a sincronização faz downloads atômicos (arquivos temporários `.tmp`), a versão anterior do pico continua perfeitamente utilizável. Devemos permitir que os usuários abram e interajam com os guias já baixados enquanto a atualização ocorre, introduzindo uma mecânica de recarregamento seguro e reativo na interface de navegação (Mapas) quando a atualização for concluída, evitando falhas ou travamentos (crash) causados pela substituição atômica de arquivos sendo ativamente lidos.

## What Changes

- Modificação da lógica interna de `_downloadOrUpdatePico` no `SyncService` para assegurar que a lista de `picos_baixando` (anteriormente `downloadingCrags`) seja devidamente limpa através de um bloco `finally`.
- Remoção do bloqueio visual na interface (`home.dart` e `browse.dart`) para croquis já disponíveis localmente, mantendo a opacidade normal e a capacidade de clique.
- Introdução do estado `pico_aberto_id` (anteriormente `openedCragId`) para rastrear qual croqui está ativamente renderizado na tela do usuário.
- Pausa condicional da substituição atômica no serviço de sincronização caso o ID atualizado seja igual ao `pico_aberto_id`, protegendo a leitura do disco.
- Implementação de um diálogo bloqueante de interface para notificar o usuário quando uma atualização para o croqui aberto estiver pronta, obrigando a ação de recarregar a interface e realizar a troca atômica dos dados.
- **TDD & Cobertura**: Os arquivos de testes correspondentes para os métodos alterados no `SyncService` e para os componentes visuais afetados deverão atingir e manter 100% de cobertura.

## Capabilities

### New Capabilities
- `reatividade-ui-sincronizacao`: Mecânica segura de recarregamento e reatividade para telas de croquis abertos que recebem finalização de download atômico em segundo plano, construída baseada nos princípios de TDD e 100% de cobertura de código.

### Modified Capabilities
- `data-sync-feedback`: Os requisitos existentes serão atualizados para garantir que croquis já baixados permaneçam interativos e que o controle de estados no motor do Isolate atenda a limpeza rigorosa na conclusão.

## Impact

- Serviço `SyncService` e a função associada de background `_downloadOrUpdatePico`: A documentação do Isolate de download será melhorada com docstrings abrangentes, e os métodos atômicos considerarão o croqui em uso.
- Interfaces `home_functions.dart` / `browse_functions.dart`: Modificações reativas de widget.
- UI do Mapa Interativo: Novos vínculos com o estado de sincronização global (`ValueNotifier` ou `Stream`).
- Requisito técnico forte: Testes abrangentes precisam preceder todas essas implementações (Ciclo Red-Green-Refactor).
