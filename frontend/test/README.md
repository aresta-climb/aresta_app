# Testes — Aresta Climb Frontend

Este diretório contém a suíte de testes automatizados de `frontend/`.

## Estrutura

```text
test/
├── application_managers/ Orquestradores de background, feedback e migração
├── architecture/         Regras de isolamento de pacotes, logs, HTTP, smoke_ci e MVVM
├── caos/                 Testes exploratórios determinísticos (Robô Caótico), ddmin e regressão JSON
├── constants/            Constantes de rede e URLs
├── data/                 Modelos de domínio e serialização JSON
├── integration/          Fluxos integrados de sincronização e persistência
├── legal/                Datas e versões dos documentos legais
├── navigation/           Árvore de navegação, AppNav, deep links e PageListenableBuilder
├── pages/                Testes de widget das páginas
├── protobuf/             Serialização e desserialização Protobuf
├── services/             Serviços e Fakes determinísticos (autenticação, mídia, caderneta, comunidade, HTTP/Sync)
├── theme/                Paleta de cores e alternância de tema
├── utils/                Geometria vetorial, graus, filtros, UIDs e extratores
├── view/                 function_library e view_models
└── widgets/              Componentes reutilizáveis de UI
```

## Execução (a partir de `frontend/`)

```bash
# Executar toda a suíte (inclui regressões JSON; ignora a campanha aleatória longa por padrão)
flutter test

# Executar com relatório de cobertura LCOV
flutter test --coverage

# Executar uma pasta ou arquivo específico
flutter test test/services/
flutter test test/navigation/
flutter test test/widgets/navegacao/botao_voltar_com_retorno_inicio_test.dart

# Executar apenas as receitas salvas de regressão do Robô Caótico
flutter test test/caos/regressao_caminhos_test.dart

# Executar campanha exploratória do Robô Caótico no terminal (ex.: 60s)
flutter test test/caos/robo_caotico_exploratorio_test.dart --dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS=60

# Executar campanha em dispositivo ou emulador conectado
flutter test integration_test/robo_caotico_dispositivo_test.dart --dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS=60
```

## Convenções

- Nomes de arquivos, grupos e testes em português brasileiro, espelhando `lib/` na proporção 1:1 (`*_test.dart`).
- Sem uso de `mocktail` ou `mockito` para classes internas; fronteiras externas utilizam bibliotecas `*_fake.dart` (com seus próprios `*_fake_test.dart`), `ClienteHttpAresta.paraTestes` ou servidores HTTP locais em `localhost`.
- Arquivos temporários usam `Directory.systemTemp` e são removidos em `tearDown`.
