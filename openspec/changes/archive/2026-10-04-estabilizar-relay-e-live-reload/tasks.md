# Tarefas de Implementação

## 1. Suporte a ETag e HTTP 304 no Túnel Retransmissor Desktop (`aresta_db`)

- [x] 1.1 Criar testes unitários em `aresta_db/tests/test_tunel_retransmissor.py` validando o cálculo de ETag (SHA-256) e a resposta HTTP 304 Not Modified com corpo vazio quando o cabeçalho `If-None-Match` corresponder ao arquivo em disco.
- [x] 1.2 Implementar a verificação de `If-None-Match`, cabeçalho `ETag` e resposta 304 Not Modified em `editor/core/tunel_retransmissor.py` em `aresta_db`, verificando que todos os testes passem.

## 2. Dormência de Polling com WebSocket Conectado (`aresta_app`)

- [x] 2.1 Criar testes unitários em `frontend/test/services/http/servico_croqui_online_test.dart` validando que a rotina periódica de verificação de ETag ignora chamadas HTTP enquanto o WebSocket de Live Reload estiver conectado.
- [x] 2.2 Implementar verificação de conectividade do WebSocket em `ServicoCroquiOnline` em `frontend/lib/services/http/servico_croqui_online.dart`, mantendo o intervalo padrão de 30 segundos dormente durante conexões ativas.

## 3. Ciclo de Vida do `PicoViewModel` e Eliminação de Timers Zumbis (`aresta_app`)

- [x] 3.1 Criar testes de widget e de ciclo de vida em `frontend/test/pages/pico_test.dart` e `frontend/test/view/view_models/pico_view_model_test.dart` verificando que a reconstrução da página cancela deterministamente timers de polling prévios sem acumular instâncias ativas.
- [x] 3.2 Injetar o singleton gerenciado `datasetRepo.servicoCroquiOnline` na construção de `PicoViewModel` em `frontend/lib/navigation/construtor_view_arvore.dart`.
- [x] 3.3 Implementar `didUpdateWidget` e descarte determinístico de recursos em `_PicoDetailsPageState` em `frontend/lib/pages/pico.dart`.

## 4. Coalescência e Proteção contra Reentrância de Sincronizações (`aresta_app`)

- [x] 4.1 Criar testes unitários em `frontend/test/services/sync_service_test.dart` validando que chamadas simultâneas de `syncIndex()` reutilizam a mesma Future em trânsito sem disparar múltiplas requisições de rede.
- [x] 4.2 Implementar mecanismo de coalescência de requisições ativas (*in-flight request sharing*) em `SyncService.syncIndex()` em `frontend/lib/services/http/sync_service.dart`.
- [x] 4.3 Ajustar os ouvintes de transição de modo em `frontend/lib/main.dart` e `frontend/lib/services/inicializacao_app.dart` para evitar requisições redundantes de sincronização.

## 5. Validação Integrada, Documentação e Cobertura

- [x] 5.1 Executar a suíte de testes completa do Flutter com `flutter test` e assegurar 100% de aprovação e cobertura nos arquivos modificados.
- [x] 5.2 Atualizar os arquivos de documentação `README.md` pertinentes em `frontend/lib/services/` e `frontend/lib/pages/` registrando as regras de dormência de polling e ciclo de vida do relay.
