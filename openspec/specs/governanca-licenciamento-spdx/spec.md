# Especificação de Governança, Licenciamento e SPDX

## Requirements

### Requirement: Licença Mozilla Public License 2.0
O repositório DEVE conter o texto integral da licença Mozilla Public License 2.0 (MPL-2.0) em seu arquivo raiz `LICENSE`.

#### Scenario: Presença do arquivo de licença MPL 2.0
- **QUANDO** o repositório é inspecionado na raiz
- **ENTÃO** o arquivo `LICENSE` existe e contém os termos oficiais e completos da licença MPL 2.0

### Requirement: Documentação de Marca e Ativos
O arquivo `README.md` raiz DEVE delimitar expressamente a separação entre o código-fonte livre sob MPL 2.0, a titularidade das marcas registradas ("Aresta", "Aresta Climb", logotipos e identidade visual) e os direitos autorais dos dados e croquis de escalada.

#### Scenario: Leitura da seção legal no README
- **QUANDO** o desenvolvedor ou usuário acessa o `README.md`
- **ENTÃO** visualiza a declaração explícita de que a licença de código não transfere direitos de uso de marca nem dos dados comerciais/oficiais de croquis

### Requirement: Diretrizes de Contribuição com DCO
O repositório DEVE fornecer um guia de contribuição em `CONTRIBUTING.md` detalhando a exigência do Developer Certificate of Origin (DCO v1.1) através de commits assinados (`git commit -s`) e referenciando os princípios de engenharia inegociáveis.

#### Scenario: Orientação a novos contribuidores
- **QUANDO** um contribuidor abre o arquivo `CONTRIBUTING.md`
- **ENTÃO** encontra instruções claras de como assinar commits com `-s`, o fluxo de PRs e o link para o `PRINCIPIOS.md`

### Requirement: Identificadores SPDX em Arquivos de Código
Todos os arquivos de código-fonte Dart (`.dart`) presentes no projeto (em `frontend/lib/`, `frontend/test/` e scripts de `frontend/tool/`) DEVEM conter no topo do arquivo o identificador SPDX e o aviso de direitos autorais padronizados.

#### Scenario: Estrutura do cabeçalho SPDX
- **QUANDO** qualquer arquivo `.dart` de autoria do projeto é lido
- **ENTÃO** as primeiras linhas contêm exatamente:
  ```dart
  // SPDX-FileCopyrightText: Copyright (C) <ANO>=2026 Aresta Climb Contributors
  // SPDX-License-Identifier: MPL-2.0
  ```

### Requirement: Teste Automatizado de Conformidade SPDX
A suíte de testes de unidade do projeto DEVE conter um teste automatizado (`frontend/test/legal/conformidade_spdx_test.dart`) que varre todos os arquivos `.dart` do projeto e falha se algum arquivo não contiver o identificador SPDX e copyright válidos.

#### Scenario: Execução do teste de conformidade de licença
- **QUANDO** o comando de teste de conformidade (`flutter test test/legal/conformidade_spdx_test.dart`) é executado
- **ENTÃO** o teste verifica 100% dos arquivos Dart do projeto e passa com sucesso apenas se todos possuírem o cabeçalho SPDX obrigatório
