# Testes de Integração (`test/integration/`)

Este diretório contém testes que exercitam múltiplos serviços e camadas em conjunto sem depender de servidores externos.

## Arquivos

| Arquivo | Descrição |
|---|---|
| `reactive_sync_test.dart` | Valida o ciclo de sincronização, download em `Isolate`, gravação em disco temporário e atualização reativa de estado |

## Execução

```bash
flutter test test/integration/
flutter test test/integration/reactive_sync_test.dart
```

## Notas

- Diretórios temporários são criados em `Directory.systemTemp` e apagados ao final de cada teste.
- Respostas HTTP são servidas por cliente de teste ou servidor HTTP local em `localhost`.
