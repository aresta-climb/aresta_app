# Testes de Serviços

Esta pasta contém os testes unitários dos serviços principais da aplicação. Os serviços testados aqui são responsáveis por lógica de negócio central, como leitura de arquivos ZIP, gerenciamento de configuração e sincronização de dados.

## Arquivos

| Arquivo | Serviço testado | Descrição |
|---|---|---|
| `zip_interceptor_test.dart` | `ZipInterceptorClient` | Testa o interceptor HTTP que serve arquivos de dentro de um `.croqui` ou `.zip` local usando o protocolo `aresta-zip://` |
| `archive_service_test.dart` | `ArchiveService` | Testa extração de arquivos `.croqui` (ZIP ofuscado com XOR), re-ofuscação do cabeçalho e geração de índice temporário |
| `editor_croqui_test.dart` | `EditorDeCroqui` | Testa lógica de modos (oficial, editor, experimental), cálculo de caminhos (`downloadsPath`, `indicePath`) e notificadores de estado |
| `dataset_repository_test.dart` | `DatasetRepository` | Testa estado público do repositório, extração de caminho de capa markdown e busca recursiva de imagens no sistema de arquivos |
| `sync_service_test.dart` | `SyncService` / lógica markdown | Testa extração de caminhos de imagens em strings markdown, o enum `SyncStatus` e a classe `TopoDataset` |

## Como executar

```bash
# Todos os testes desta pasta
flutter test test/services/

# Um arquivo específico
flutter test test/services/zip_interceptor_test.dart
```

## Notas

- Os testes do `ZipInterceptorClient` e do `ArchiveService` criam arquivos temporários em `Directory.systemTemp` e os removem após cada teste.
- Testes que dependem de `getApplicationDocumentsDirectory()` (como `connect`, `disconnect` e `activateExperimental`) **não são testados aqui** pois requerem o binding do Flutter; esses cenários são cobertos pelos testes de integração.
- O protocolo `aresta-zip://` usa hífen (não sublinhado) por ser compatível com o padrão RFC 3986 exigido pela classe `Uri` do Dart.
