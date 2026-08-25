## Por que

Para preparar a abertura pública do repositório do Aresta App no GitHub de forma segura, sustentável e juridicamente sólida, é necessário adotar uma licença que proteja contra apropriação indevida do código por concorrentes (copyleft por arquivo), permita a interoperabilidade nativa com as lojas de aplicativos (App Store e Google Play) e serviços de monetização/DRM via backend (RevenueCat), e dispense a burocracia de CLA (Contributor License Agreement) através do Developer Certificate of Origin (DCO). 

A migração unificada para a Mozilla Public License 2.0 (MPL 2.0), a padronização de identificadores SPDX em todos os arquivos de código e a validação automatizada por testes garantem total clareza legal e conformidade inegociável com os **Princípios de Engenharia do Aresta App** (`PRINCIPIOS.md`).

## O que muda

- **Adoção da Licença MPL 2.0**: Substituição do arquivo `LICENSE` raiz pela íntegra oficial da Mozilla Public License Version 2.0.
- **Documentação de Governança e Marca**:
  - Atualização do `README.md` raiz com cláusulas explícitas separando o código-fonte livre (MPL 2.0), a proteção da marca registrada ("Aresta", "Aresta Climb" e logotipos) e os direitos autorais dos dados/croquis de escalada.
  - Criação do documento `CONTRIBUTING.md` em português brasileiro estabelecendo o fluxo de contribuições via DCO (sign-off com `git commit -s`) e referenciando os Princípios de Engenharia do projeto (`PRINCIPIOS.md`).
  - Atualização de menções no `frontend/README.md`.
- **Identificadores SPDX nos Arquivos**: Adição do cabeçalho padronizado de licença e copyright no topo de todos os arquivos de código Dart em `frontend/lib/`, `frontend/test/` e scripts de `frontend/tool/`:
  ```dart
  // SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Authors
  // SPDX-License-Identifier: MPL-2.0
  ```
- **Automação de Conformidade por Teste (TDD)**: Criação de suíte de testes de unidade automatizada em `frontend/test/legal/conformidade_spdx_test.dart` que valida recursivamente se todo e qualquer arquivo `.dart` do projeto possui o cabeçalho SPDX correto, falhando o pipeline caso um novo arquivo seja inserido sem a marcação.
- **Conformidade Estrita com PRINCIPIOS.md**: Manutenção de 100% de cobertura de testes, ciclo TDD (Red-Green-Refactor) e documentação contínua abrangente em português brasileiro com docstrings explicativas.

## Capacidades

### Novas Capacidades
- `governanca-licenciamento-spdx`: Governança de licenciamento sob MPL 2.0, orientações de contribuição DCO, proteção de marcas/ativos e verificação automatizada de conformidade de cabeçalhos SPDX via testes unitários.

### Capacidades Modificadas
<!-- Nenhuma capacidade existente teve seus requisitos funcionais alterados -->

## Impacto

- **Documentação e Repositório**: `LICENSE`, `README.md`, `frontend/README.md`, `CONTRIBUTING.md`.
- **Código-Fonte**: Inclusão de comentários de cabeçalho SPDX no topo dos arquivos `.dart` em `frontend/lib/`, `frontend/test/` e ferramentas (`frontend/tool/`).
- **Suíte de Testes**: Novo teste unitário em `frontend/test/legal/conformidade_spdx_test.dart` integrado à suíte de testes do Flutter.
