# Testes — Aresta Climb Frontend

Esta pasta contém todos os testes automatizados do frontend do aplicativo Aresta Climb.

## Estrutura

```text
test/
├── architecture/    Testes arquiteturais e de convenção de código
├── integration/     Testes de integração de fluxos completos (download, leitura de croqui)
├── legal/           Testes para validação e extração de datas de documentos legais
├── navigation/      Testes unitários da árvore de navegação, prevenção de loops e reatividade do PageListenableBuilder (Hot-Reload)
├── pages/           Testes de widget das páginas de roteamento superior (ex: mapao_global)
├── protobuf/        Testes de serialização/desserialização dos objetos Protobuf
├── services/        Testes unitários dos serviços principais (ZipInterceptor, EditorDeCroqui, DatasetRepository, SyncService, SyncNetwork, SyncStorage)
├── theme/           Testes unitários do gerenciamento de temas e persistência do tema ao reiniciar
├── utils/           Testes de funções utilitárias isoladas (ex: parsers de Markdown)
├── view_functions/  Testes unitários de funções utilitárias compartilhadas
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
flutter test test/utils/

# Rodar um arquivo específico
flutter test test/services/zip_interceptor_test.dart
```

## Resumo dos testes

| Pasta | Arquivos | Testes |
|---|---|---|
| `services/` | 12 | ~110 |
| `view_functions/` | 12 | ~40 |
| `navigation/` | 3 | ~17 |
| `theme/` | 1 | ~3 |
| `protobuf/` | 1 | ~20 |
| `integration/` | 2 | ~10 |
| `pages/` | 8 | ~50 |
| `widgets/` | 4 | ~35 |
| `architecture/` | 1 | ~10 |
| `legal/` | 1 | ~10 |
| `utils/` | 1 | ~10 |
| **Total** | **46** | **~317** |

## Convenções

- Todos os comentários e nomes de testes estão em **português**.
- Arquivos temporários criados nos testes são armazenados em `Directory.systemTemp` e removidos no `tearDown`.
- Testes que dependem de I/O de rede geralmente usam o interceptor `aresta-zip://` ou um mock de cliente `http` para simular respostas locais.
- Testes avançados de Sincronização em Background (como o `SyncService` e `SyncIsolate`) instanciam um **Micro Servidor HTTP Local** na porta `localhost` dinamicamente durante o `setUp` para garantir que instâncias de `Isolate` consigam consumir mocks de bytes através de fronteiras isoladas de memória, preservando a fidelidade da thread separada.
- Testes que dependem do binding do Flutter (ex: `path_provider`) são separados nos testes de widget ou integração com binding explícito.
