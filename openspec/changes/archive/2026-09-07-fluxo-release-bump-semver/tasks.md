## 1. Módulo Central de Gerenciamento SemVer (TDD)

- [x] 1.1 Criar o arquivo de testes unitários `frontend/test/tool/release_tools/gerenciador_semver_test.dart` cobrindo parsing SemVer, comparações, cálculo de release (`patch` com e sem `-dev`, `minor`, `major`, `custom` válido/inválido/regressivo) e cálculo do próximo `-dev`, verificando a falha inicial esperada (Red).
- [x] 1.2 Implementar a biblioteca central `frontend/tool/release_tools/gerenciador_semver.dart` com funções puras e documentadas com docstrings `///` (`validarSemver`, `compararSemver`, `calcularVersaoRelease`, `calcularProximoDev`), verificando aprovação de 100% dos testes via `flutter test test/tool/release_tools/gerenciador_semver_test.dart` (Green).

## 2. Utilitários de Linha de Comando e Manipulação de Pubspec (TDD)

- [x] 2.1 Criar os testes unitários `frontend/test/tool/release_tools/calcular_versao_release_test.dart` cobrindo os argumentos CLI (`--tipo`, `--custom`, `--pubspec`), saídas no stdout e tratamento de erros com códigos de saída, verificando falha inicial (Red).
- [x] 2.2 Implementar o executável CLI `frontend/tool/release_tools/calcular_versao_release.dart` devidamente documentado, garantindo passagem em 100% dos testes via `flutter test test/tool/release_tools/calcular_versao_release_test.dart` (Green).
- [x] 2.3 Criar os testes unitários `frontend/test/tool/release_tools/calcular_proximo_dev_test.dart` cobrindo cálculo da versão `-dev` e incremento de build, verificando falha inicial (Red).
- [x] 2.4 Implementar o executável CLI `frontend/tool/release_tools/calcular_proximo_dev.dart` devidamente documentado, garantindo passagem em 100% dos testes via `flutter test test/tool/release_tools/calcular_proximo_dev_test.dart` (Green).
- [x] 2.5 Criar os testes unitários `frontend/test/tool/release_tools/atualizar_versao_pubspec_test.dart` cobrindo leitura, substituição da linha `version:` e persistência sem alterar o restante do arquivo, verificando falha inicial (Red).
- [x] 2.6 Implementar o utilitário `frontend/tool/release_tools/atualizar_versao_pubspec.dart` devidamente documentado, garantindo passagem em 100% dos testes via `flutter test test/tool/release_tools/atualizar_versao_pubspec_test.dart` (Green).

## 3. Integração com GitHub Actions e Workflow de Release

- [x] 3.1 Atualizar a seção `on.workflow_dispatch.inputs` de `.github/workflows/release_new_app_version.yml` para substituir `new_version` pelo seletor `bump_type` (`patch`, `minor`, `major`, `custom`) e pelo campo opcional `custom_version`, com descrições em português.
- [x] 3.2 Atualizar as etapas de cálculo e injeção de versão do job `prepare_release` em `.github/workflows/release_new_app_version.yml` para utilizar as ferramentas Dart criadas (`calcular_versao_release.dart`, `atualizar_versao_pubspec.dart` e `calcular_proximo_dev.dart`), validando os passos do workflow.

## 4. Transição de Versão e Documentação

- [x] 4.1 Atualizar a versão declarada em `frontend/pubspec.yaml` de `0.2.4-dev+67` para `0.2.5-dev+67` e verificar integridade com `flutter pub get`.
- [x] 4.2 Atualizar a seção de Release no arquivo `frontend/README.md` documentando o funcionamento do workflow manual, opções de bump e a convenção do ciclo `-dev`.
- [x] 4.3 Executar verificação estática e suíte completa de testes (`flutter analyze --fatal-infos --fatal-warnings` e `flutter test`) assegurando 100% de cobertura nos utilitários e zero regressões no projeto.
