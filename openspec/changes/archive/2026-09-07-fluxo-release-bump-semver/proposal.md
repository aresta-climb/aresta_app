# Proposta: Melhoria no Fluxo de Release Unificado com Bump SemVer e Ciclo -dev Posterior

## Why

Atualmente, o workflow de lançamento unificado de novas versões do aplicativo (`release_new_app_version.yml`) exige que o desenvolvedor digite manualmente a versão semântica de lançamento em um campo de texto livre, além de possuir uma inconsistência conceitual no ciclo de vida de desenvolvimento pós-release: ao lançar uma versão como `0.1.3+11`, o pipeline grava na branch `main` o ciclo seguinte como `0.1.3-dev+12`, mantendo a numeração da versão que já foi disponibilizada em produção.

Esta proposta alinha o fluxo de lançamento de versões do aplicativo mobile com o padrão adotado com sucesso no Editor Aresta (`aresta_db`), introduzindo seleção via menu de incremento semântico (`patch`, `minor`, `major` e `custom` como fallback) e corrigindo o ciclo de desenvolvimento pós-lançamento para apontar sempre para o patch imediatamente posterior (ex: se `0.1.3` foi lançado, o próximo ciclo em `main` passa a ser `0.1.4-dev`).

## What Changes

- **Seleção Semântica de Versão no Workflow (`release_new_app_version.yml`)**:
  - Substituição do input obrigatório de texto livre `new_version` por um campo de escolha `bump_type` com as opções `patch` (padrão), `minor`, `major` e `custom`.
  - Adição do campo opcional `custom_version`, utilizado e validado apenas quando `bump_type` for `custom`.
- **Cálculo Preciso da Versão de Release**:
  - No modo `patch`: se a versão atual em `pubspec.yaml` estiver em ciclo de desenvolvimento (`-dev`), converte diretamente para a versão estável de mesmo número (ex: `0.1.4-dev` -> `0.1.4`). Se a versão atual não for `-dev`, incrementa o patch.
  - No modo `minor`: incrementa o minor e zera o patch (ex: `0.1.4-dev` -> `0.2.0`).
  - No modo `major`: incrementa o major e zera minor e patch (ex: `0.1.4-dev` -> `1.0.0`).
  - No modo `custom`: valida o formato SemVer e assegura que a nova versão seja estritamente maior que a versão atual.
- **Ciclo de Desenvolvimento Posterior Correto (`calculate_next_dev`)**:
  - Imediatamente após a geração da tag de release estável (ex: `0.1.3`), o pipeline calcula a próxima versão de desenvolvimento incrementando o patch e adicionando o sufixo `-dev` (ex: `0.1.4-dev`), commitando em `main`.
- **Ferramental em Dart com 100% de Cobertura de Testes**:
  - Criação de utilitário em Dart em `frontend/tool/release_tools/` para execução limpa e testável localmente e no CI (`dart run tool/release_tools/...`), com testes unitários em `frontend/test/tool/release_tools/`.
- **Transição de Versão Atual**:
  - Atualização do `frontend/pubspec.yaml` de `0.2.4-dev+67` para `0.2.5-dev+67`, refletindo que `v0.2.4+66` já foi lançada e que o próximo lançamento `patch` será `0.2.5`.

## Capabilities

### New Capabilities
- `automacao-release-semver`: Regras de incremento semântico (`patch`, `minor`, `major`, `custom`), validações e cálculo da versão estável e do ciclo `-dev` posterior do aplicativo.

### Modified Capabilities
<!-- Nenhuma especificação anterior sofre alteração comportamental de requisitos -->

## Impact

- **Código e Ferramentas**:
  - Novo módulo de ferramentas em Dart: `frontend/tool/release_tools/` e testes em `frontend/test/tool/release_tools/`.
  - Atualização da versão base no arquivo `frontend/pubspec.yaml`.
- **CI/CD**:
  - Workflow `.github/workflows/release_new_app_version.yml`: atualização de inputs e substituição dos scripts inline de bash pelas invocações do utilitário Dart.
- **Documentação**:
  - Atualização do `frontend/README.md` documentando os novos parâmetros de execução manual do release no GitHub Actions.
