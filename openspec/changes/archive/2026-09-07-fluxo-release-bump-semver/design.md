# Design Técnico: Automação SemVer e Ciclo de Release do App

## Context

O workflow atual (`.github/workflows/release_new_app_version.yml`) orquestra o lançamento manual das versões do aplicativo Flutter para Android e iOS. Atualmente, ele depende de um campo de texto livre (`new_version`) e de trechos de script Bash em linha que usam `grep`, `awk` e `sort -V` para manipular o `frontend/pubspec.yaml`. 

Além de suscetível a erros de digitação, o workflow atual possui uma inversão conceitual no ciclo dev pós-lançamento: ao lançar `0.1.3+11`, ele gravava `0.1.3-dev+12` na branch `main`.

No repositório irmão `aresta_db`, o Editor Aresta já adota com sucesso um fluxo semântico baseado em menus de escolha (`patch`, `minor`, `major`, `custom`) e cálculo automatizado do próximo ciclo `-dev`. Este design adapta esse modelo comprovado para o ecossistema Dart/Flutter do `aresta_app`.

## Goals / Non-Goals

**Goals:**
- Criar utilitários modulares e testáveis em Dart puro (`frontend/tool/release_tools/`) para cálculo de versão de release, cálculo de próximo ciclo `-dev` e atualização segura do `pubspec.yaml`.
- Garantir 100% de cobertura de testes unitários com `dart test`/`flutter test` para todos os cenários semânticos (patch com/sem `-dev`, minor, major, custom válido/inválido/regressivo).
- Atualizar o workflow `.github/workflows/release_new_app_version.yml` para utilizar seleção via menu `choice` (`patch`, `minor`, `major`, `custom`) com fallback em `custom_version`.
- Corrigir a versão atual no repositório de `0.2.4-dev+67` para `0.2.5-dev+67`, alinhando a branch `main` com a tag mais recente (`v0.2.4+66`).
- Atualizar a documentação técnica pertinente em `frontend/README.md`.

**Non-Goals:**
- Não alterar os pipelines de compilação ou regras de publicação de lojas dos sub-workflows `build_android.yml` e `build_ios.yml`.
- Não alterar o mecanismo de sincronização de termos legais (`update_legal_version.dart`) ou download de preloads (`sync_preload.dart`).

## Decisions

### Decisão 1: Utilitários em Dart Puro vs. Scripts em Bash ou Python
- **Escolha:** Implementar as ferramentas de versionamento em Dart puro sob `frontend/tool/release_tools/`.
- **Racional:** O `aresta_app` é um projeto 100% Flutter/Dart. O pipeline do GitHub Actions já executa `subosito/flutter-action@v2` antes da etapa de versionamento. Usar Dart permite escrever testes unitários declarativos com o pacote padrão `test`, executáveis localmente e no CI sem requerer ambiente Python ou scripts Bash frágeis entre sistemas operacionais.
- **Alternativas consideradas:**
  - *Scripts Python (como em aresta_db):* Exigiria introduzir Python e uv em um repositório móvel puramente Flutter.
  - *Bash puro em linha no GitHub Actions:* Frágil para manipulação e validação matemática de SemVer, difícil de testar localmente.

### Decisão 2: Arquitetura e Divisão dos Utilitários
- **Escolha:** Seguir a separação clara de responsabilidades:
  1. `gerenciador_semver.dart`: Biblioteca central com funções puras de parsing de SemVer, comparação, cálculo de release (`calcularVersaoRelease`) e cálculo do próximo ciclo dev (`calcularProximoDev`).
  2. `calcular_versao_release.dart`: Ponto de entrada CLI que consome argumentos (`--tipo`, `--custom`, `--pubspec`), emite a versão final no stdout ou salva em variáveis de ambiente do GitHub Actions.
  3. `calcular_proximo_dev.dart`: Ponto de entrada CLI que recebe a versão de release e calcula o próximo ciclo `-dev` e novo build.
  4. `atualizar_versao_pubspec.dart`: Utilitário para substituir com segurança a linha `version:` no `pubspec.yaml` preservando todo o restante do arquivo.
- **Racional:** Permite testar a lógica semântica como funções puras e utilizar os executáveis CLI diretamente nos steps do GitHub Actions.

### Decisão 3: Regra de Incremento Semântico e Ciclo de Vida
- **Regras:**
  - **`patch`:**
    - Se a versão atual possui sufixo `-dev` (ex: `0.1.4-dev`): a versão estável de release é `0.1.4`.
    - Se a versão atual não possui `-dev` (ex: `0.1.3`): a versão estável de release é `0.1.4`.
  - **`minor`:** Versão vira `MAJOR.(MINOR+1).0` (ex: `0.1.4-dev` -> `0.2.0`).
  - **`major`:** Versão vira `(MAJOR+1).0.0` (ex: `0.1.4-dev` -> `1.0.0`).
  - **`custom`:** Requer string SemVer válida e estritamente superior à versão base atual.
  - **Próximo `-dev` pós-release:** Seja `R` a versão estável recém-lançada, o próximo ciclo em `main` será sempre `(R.patch + 1)-dev` (ex: após release `0.2.0`, abre `0.2.1-dev`; após release `1.0.0`, abre `1.0.1-dev`).
  - **Número de build:** Sequencial estrito (`CURRENT_BUILD + 1` no release, e `RELEASE_BUILD + 1` no ciclo dev).

## Risks / Trade-offs

- **[Risco] O repositório atual possui `pubspec.yaml` em `0.2.4-dev+67`, enquanto `v0.2.4+66` já foi lançada:**
  - *Mitigação:* Como parte imediata desta mudança, o `pubspec.yaml` será atualizado para `0.2.5-dev+67`. Dessa forma, o próximo acionamento com `patch` gerará corretamente a versão `0.2.5+68`.
- **[Risco] Operador selecionar `custom` mas não fornecer `custom_version`:**
  - *Mitigação:* O utilitário valida as entradas no primeiro step e encerra a execução com código de saída 1 e mensagem de erro clara antes de criar qualquer commit ou tag no Git.

## Migration Plan

1. Criar o utilitário semântico e CLI em `frontend/tool/release_tools/`.
2. Criar os testes unitários completos em `frontend/test/tool/release_tools/` e validar 100% de sucesso.
3. Atualizar o arquivo `.github/workflows/release_new_app_version.yml` com os novos inputs (`bump_type`, `custom_version`) e chamadas aos scripts Dart.
4. Atualizar a versão no `frontend/pubspec.yaml` para `0.2.5-dev+67`.
5. Atualizar a documentação em `frontend/README.md`.
