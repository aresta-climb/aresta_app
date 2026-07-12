## 1. Documentação de Base e TDD Setup

- [x] 1.1 Adicionar docstrings detalhados e abrangentes ao ciclo de vida e ao motor de comunicação de `frontend/lib/services/http/sync_isolate.dart`, explicando exatamente o processamento dos blocos em segundo plano.
- [x] 1.2 No arquivo de teste `frontend/test/services/sync_service_test.dart`, modelar um novo teste (que deve falhar inicialmente) assegurando que um encerramento forçado do _downloadOrUpdatePico garanta a remoção do ID respectivo do `downloadingCrags.value`.
- [x] 1.3 Implementar a correção na base `frontend/lib/services/http/sync_service.dart` adicionando os blocos de sanitização e garantir aprovação no teste (Cobertura deve ser mantida).

## 2. Controle de Estado Ativo

- [x] 2.1 Adicionar em `DatasetRepository` ou `SyncService` as variáveis reativas essenciais: `ValueNotifier<String?> pico_aberto_id` e `ValueNotifier<String?> recarga_pendente_pico_id` com docstrings explicando o papel arquitetural na Main Isolate.
- [x] 2.2 Criar um teste unitário no motor de sincronização onde a fase final `applyAtomicFileUpdates` é bloqueada caso o pico avaliado seja equivalente ao valor atual de `pico_aberto_id`.
- [x] 2.3 Implementar este desvio arquitetural em `sync_service.dart`, acionando e expondo a pendência em `recarga_pendente_pico_id`. 
- [x] 2.4 Criar um novo método `commitPendenciasAtomaticas(String id)` que permite forçar a finalização atrasada deste processo, escrevendo primeiro um teste correspondente para a verificação do sucesso.

## 3. UI Desbloqueada

- [x] 3.1 Em `frontend/test/view_functions/home_functions_test.dart` (ou teste correspondente de componente), criar validações de Widget Test para um ambiente onde um pico com ID mapeado no `ValueListenable` de progresso ainda preserve sua opacidade (`Opacity=1.0`) e o `onTap` se ele existir ativamente no dataset fornecido.
- [x] 3.2 Modificar em `buildPicosCarousel` a lógica de UI baseando-se no que já se encontra persistido na base de dados e não apenas no status de progresso, tornando o item clicável. `browse_functions.dart`.

## 4. Diálogos e Reatividade Funcional do Mapa

- [x] 4.1 Modificar o fluxo de vida (`initState` e `dispose`) dos widgets de renderização (principalmente `MapaInterativo`) para assinar e renunciar sua responsabilidade vinculando seus IDs únicos ao `pico_aberto_id`. (Implementado globalmente na árvore de navegação via `_TreeNavigationWrapperState`).
- [x] 4.2 Envolver o Widget Root do Mapa em um `ValueListenableBuilder` focado em observar o `recarga_pendente_pico_id`. (Implementado no `PageListenableBuilder`).
- [x] 4.3 Desenvolver testes de Widget reproduzindo o disparo deste Builder ao preencher o id atrelado e garantir que o popup imperativo de recarga ("Versão Nova Disponível: Recarregar") se projeta corretamente e bloqueia Dismissões errôneas. (Criada interface robusta com `Stack` e `IgnorePointer`).
- [x] 4.4 Ligar o botão de recarregar do novo Diálogo interativo para executar nativamente a função `commitPendenciasAtomaticas` e forçar de forma otimizada a recarga da rota (Pop + Push).

## 5. Testes de Integração Fim-a-Fim

- [x] 5.1 Desenvolver um Teste de Integração validando o Fluxo de "Atualização Silenciosa": Um croqui desatualizado é atualizado pela interface, o usuário permanece na Home, a atualização corre no background, o popup não é exibido em momento nenhum e os dados são substituídos magicamente sem aviso.
- [x] 5.2 Desenvolver um Teste de Integração validando o Fluxo de "Bloqueio e Recarga Opcional": Um croqui desatualizado é atualizado, o usuário clica e entra neste croqui antes da conclusão. Quando a atualização finaliza, o sistema projeta o popup obrigatório na tela do mapa e o clique de "Recarregar" invoca com sucesso a transição.
