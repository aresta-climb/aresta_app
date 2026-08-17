# Testes de Serviços

Esta pasta contém os testes unitários dos serviços principais da aplicação. Os serviços testados aqui são responsáveis por lógica de negócio central, como leitura de arquivos ZIP, gerenciamento de configuração e sincronização de dados.

## Arquivos

| Arquivo | Serviço testado | Descrição |
|---|---|---|
| `zip_interceptor_test.dart` | `ZipInterceptorClient` | Testa o interceptor HTTP que serve arquivos de dentro de um `.croqui` local usando o protocolo `aresta-zip://` em memória |
| `editor_croqui_test.dart` | `EditorDeCroqui` | Testa lógica de modos (oficial, editor, experimental), cálculo de caminhos (`downloadsPath`, `indicePath`) e notificadores de estado |
| `experimental_mode_test.dart`| `EditorDeCroqui` | Testa o comportamento do Modo Experimental: timer em background, persistência de URL na desconexão e limpeza total (Nuke) |
| `dataset_repository_test.dart` | `DatasetRepository` | Testa estado público do repositório, mapeamento de propriedades (ex: descrição) e inicializações tipadas |
| `sync_network_test.dart` | `SyncNetwork` | Testa a leitura HTTP pura com retentativas, ETags (304 Not Modified) e timeouts |
| `sync_storage_test.dart` | `SyncStorage` | Testa a persistência atômica usando arquivos `.tmp` e a extração do `indice.binarypb` |
| `sync_status_timer_test.dart`| `SyncStatusTimer` | Testa a debouncer do status de sync que previne *flickering* rápido na UI |
| `sync_service_test.dart` | `SyncService` | Testes complexos de sincronização atômica, checagem de hashes SHA-256 e extração de imagens Markdown |

| `feedback/feedback_queue_service_test.dart` | `FeedbackQueueService` | Testa o enfileiramento local (SharedPreferences) e a chamada agendada do Workmanager |
| `feedback/background_worker_test.dart` | `FeedbackOrchestrator` | Testa a execução da fila de feedback em background, requests HTTP multipart e lógica de retry (Backoff) |
| `feedback/feedback_metadata_collector_test.dart` | `FeedbackMetadataCollector` | Testa a coleta correta dos metadados de telemetria do dispositivo na hora do envio do reporte |

## Como executar

```bash
# Todos os testes desta pasta
flutter test test/services/

# Um arquivo específico
flutter test test/services/zip_interceptor_test.dart
```

## Notas

- Os testes criam arquivos temporários em `Directory.systemTemp` e os removem após cada teste.
- Testes que dependem de `getApplicationDocumentsDirectory()` **não são testados aqui** pois requerem o binding do Flutter.
- O protocolo `aresta-zip://` usa hífen (não sublinhado) por ser compatível com o padrão RFC 3986 exigido pela classe `Uri` do Dart.
