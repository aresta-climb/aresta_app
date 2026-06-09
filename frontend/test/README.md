# Testes — Aresta Climb Frontend

Esta pasta contém todos os testes automatizados do frontend do aplicativo Aresta Climb.

## Estrutura

```
test/
├── services/        Testes unitários dos serviços principais (ZipInterceptor, EditorDeCroqui, DatasetRepository, SyncService, SyncNetwork, SyncStorage)
├── view_functions/  Testes unitários de funções utilitárias compartilhadas
├── navigation/      Testes unitários da árvore de navegação e prevenção de loops (rewinding)
├── theme/           Testes unitários do gerenciamento de temas e persistência do tema ao reiniciar
├── protobuf/        Testes de serialização/desserialização dos objetos Protobuf
├── integration/     Testes de integração de fluxos completos (download, leitura de croqui)
├── pages/           Testes de widget das páginas de roteamento superior (ex: mapao_global)
└── widgets/         Testes de widget da interface do usuário
```

Cada pasta tem seu próprio `README.md` com detalhes sobre os arquivos e os cenários cobertos.

## Como executar

```bash
# Rodar TODOS os testes
flutter test

# Rodar uma pasta específica
flutter test test/services/
flutter test test/view_functions/
flutter test test/navigation/
flutter test test/theme/
flutter test test/protobuf/
flutter test test/integration/
flutter test test/widgets/

# Rodar um arquivo específico
flutter test test/services/zip_interceptor_test.dart
```

## Resumo dos testes

| Pasta | Arquivos | Testes |
|---|---|---|
| `services/` | 8 | ~76 |
| `view_functions/` | 4 | ~32 |
| `navigation/` | 1 | ~7 |
| `theme/` | 1 | ~3 |
| `protobuf/` | 1 | ~18 |
| `integration/` | 2 | ~10 |
| `pages/` | 1 | ~1 |
| `widgets/` | 4 | ~25 |

## Convenções

- Todos os comentários e nomes de testes estão em **português**.
- Arquivos temporários criados nos testes são armazenados em `Directory.systemTemp` e removidos no `tearDown`.
- Testes que dependem de I/O de rede usam o interceptor `aresta-zip://` para simular respostas locais, sem fazer requisições reais.
- Testes que dependem do binding do Flutter (ex: `path_provider`) são separados nos testes de widget ou integração com binding explícito.
