# Testes — Aresta Climb Frontend

Esta pasta contém todos os testes automatizados do frontend do aplicativo Aresta Climb.

## Estrutura

```text
test/
├── application_managers/ Testes dos orquestradores de background, feedback e migração
├── architecture/         Testes arquiteturais e de convenção de código (isolamento de pacotes)
├── constants/            Testes de validação de constantes de rede e URLs
├── data/                 Testes de DTOs e serialização de metadados
├── integration/          Testes de integração de fluxos completos (download, leitura, hot reload)
├── legal/                Testes para validação e extração de datas de documentos legais
├── navigation/           Testes unitários da árvore de navegação, prevenção de loops e reatividade do PageListenableBuilder
├── pages/                Testes de widget de todas as páginas de navegação
├── protobuf/             Testes de serialização/desserialização dos objetos Protobuf
├── services/             Testes unitários dos serviços centrais (DatasetRepository, SyncService, EditorDeCroqui, etc.)
├── theme/                Testes unitários do gerenciamento de temas e persistência
├── utils/                Testes de funções utilitárias isoladas (FormatadorCreditos, ConstrutorCaminhoTrajeto, etc.)
├── view_functions/       Testes unitários de funções de formatação e visualização compartilhadas
└── widgets/              Testes de componentes e widgets reutilizáveis da interface
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
flutter test test/pages/

# Rodar um arquivo específico
flutter test test/services/editor_croqui_test.dart
```

## Resumo dos testes

| Módulo | Descrição | Status |
|---|---|---|
| `services/` e `application_managers/` | Gestão de dados, sincronização atômica, Isolates, offline-first e feedback | 100% aprovado |
| `navigation/` | Árvore de nós, prevenção de loops, Hot-Reload passivo e API `AppNav` | 100% aprovado |
| `pages/` e `widgets/` | Interfaces de usuário, carrossel de mapas, busca global, créditos e banners | 100% aprovado |
| `view_functions/` e `utils/` | Formatação de graus, traçados vetoriais, hit-testing e créditos | 100% aprovado |
| `architecture/`, `legal/` e `protobuf/` | Garantia de isolamento arquitetural, conformidade e integridade binária | 100% aprovado |
| **Total Geral** | **102 arquivos de teste / 737 cenários automatizados** | **100% aprovado** |

## Convenções

- Todos os comentários e nomes de testes estão em **português**.
- Arquivos temporários criados nos testes são armazenados em `Directory.systemTemp` e removidos no `tearDown`.
- Testes que dependem de I/O de rede usam um mock de cliente `http` ou servidor local de teste para simular respostas.
- Testes avançados de Sincronização em Background (como o `SyncService` e `SyncIsolate`) instanciam um **Micro Servidor HTTP Local** na porta `localhost` dinamicamente durante o `setUp` para garantir que instâncias de `Isolate` consigam consumir mocks de bytes através de fronteiras isoladas de memória, preservando a fidelidade da thread separada.

- Testes que dependem do binding do Flutter (ex: `path_provider`) são separados nos testes de widget ou integração com binding explícito.
