# Testes de Integração

Esta pasta contém testes de integração que verificam fluxos completos da aplicação, combinando múltiplos serviços e camadas. Os testes aqui simulam cenários reais de uso sem depender de um servidor remoto.

## Arquivos

| Arquivo | Descrição |
|---|---|
| `reactive_sync_test.dart` | Testa o fluxo reativo completo de sincronização e download com persistência e atualização de estado |

## Como executar

```bash
# Todos os testes desta pasta
flutter test test/integration/

# Um arquivo específico
flutter test test/integration/reactive_sync_test.dart
```

## Fluxos cobertos

### `reactive_sync_test.dart`
- Sincronização e download reativo com mock HTTP e Isolates
- Emissão de progresso linear e atualização de dados em tempo real

## Notas

- Arquivos temporários criados nos testes são armazenados em `Directory.systemTemp` e removidos após cada teste.
- Os testes usam mock HTTP ou servidor local para simular respostas.
