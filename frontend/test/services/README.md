# Testes de Serviços

Esta pasta contém os testes unitários dos serviços principais da aplicação. Os serviços testados aqui são responsáveis por lógica de negócio central, como leitura de arquivos ZIP, gerenciamento de configuração e sincronização de dados.

## Arquivos

| Arquivo | Serviço testado | Descrição |
|---|---|---|
| `editor_croqui_test.dart` | `EditorDeCroqui` | Testa lógica de modos (oficial, editor, experimental), cálculo de caminhos (`downloadsPath`, `indicePath`) e notificadores de estado |
| `experimental_mode_test.dart`| `EditorDeCroqui` | Testa o comportamento do Modo Experimental: timer em background, persistência de URL na desconexão e limpeza total (Nuke) |
| `repositorio_dataset_test.dart` | `DatasetRepository` | Testa estado público do repositório, mapeamento de propriedades (ex: descrição) e inicializações tipadas |
| `sync_rede_test.dart` | `SyncNetwork` | Testa a leitura HTTP pura com retentativas, ETags (304 Not Modified) e timeouts |
| `sync_armazenamento_test.dart` | `SyncStorage` | Testa a persistência atômica usando arquivos `.tmp` e a extração do `indice.binarypb` |
| `sync_status_timer_test.dart`| `SyncStatusTimer` | Testa a debouncer do status de sync que previne *flickering* rápido na UI |
| `sync_service_test.dart` | `SyncService` | Testes complexos de sincronização atômica, checagem de hashes SHA-256 e extração de imagens Markdown |

| `feedback/feedback_queue_service_test.dart` | `FeedbackQueueService` | Testa o enfileiramento na fila local e a integração com o repositório de persistência |
| `feedback/feedback_metadata_collector_test.dart` | `FeedbackMetadataCollector` | Testa a coleta correta dos metadados de telemetria do dispositivo e auditoria de hashes |
| `feedback/feedback_network_service_test.dart` | `FeedbackNetworkService` | Testa envio multipart protegido por App Check para o backend Supabase |
| `feedback/gatilho_feedback_rede_test.dart` | `NetworkFeedbackTrigger` | Testa disparo automático de envio quando a conectividade é restabelecida |
| `feedback/tarefa_feedback_test.dart` | `TarefaFeedback` | Testa modelo de tarefas da fila de persistência atômica em disco |
| `dataset/gerenciador_arquivos_locais_test.dart` | `GerenciadorArquivosLocais` | Testa operações diretas de arquivos e diretórios de croquis no disco local |
| `dataset/gerenciador_sessao_online_test.dart` | `GerenciadorSessaoOnline` | Testa gestão de croquis em memória RAM e cache volátil sob demanda |

## Como executar

```bash
# Todos os testes desta pasta
flutter test test/services/

# Um arquivo específico
flutter test test/services/editor_croqui_test.dart
```

## Notas

- Os testes criam arquivos temporários em `Directory.systemTemp` e os removem após cada teste.
- Testes que dependem de `getApplicationDocumentsDirectory()` **não são testados aqui** pois requerem o binding do Flutter.
