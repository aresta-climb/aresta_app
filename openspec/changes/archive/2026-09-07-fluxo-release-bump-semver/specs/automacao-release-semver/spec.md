## Purpose

Padroniza o cálculo de versões semânticas, a seleção do tipo de incremento no workflow de lançamento unificado e a inicialização automática do próximo ciclo de desenvolvimento (-dev) no aplicativo Aresta.

## ADDED Requirements

### Requirement: Seleção de Tipo de Incremento Semântico no Workflow
O workflow de release unificado (`release_new_app_version.yml`) DEVE permitir o acionamento manual selecionando o tipo de incremento de versão semântica através de opções predefinidas (`patch`, `minor`, `major`, `custom`), com `patch` definido como opção padrão.

#### Scenario: Disparo padrão com incremento patch
- **WHEN** o operador acionar o workflow sem alterar o tipo de incremento
- **THEN** o pipeline seleciona `patch` como o modo de cálculo da versão

#### Scenario: Disparo com incremento minor ou major
- **WHEN** o operador selecionar `minor` ou `major` no menu de opções
- **THEN** o pipeline calcula a nova versão incrementando a respectiva posição semântica e zerando as posições inferiores

#### Scenario: Disparo com versão customizada válida
- **WHEN** o operador selecionar `custom` e informar um valor válido em `custom_version` maior que a versão atual
- **THEN** o pipeline utiliza a versão informada como a versão de release

#### Scenario: Disparo com versão customizada omitida ou inválida
- **WHEN** o operador selecionar `custom` e deixar `custom_version` em branco ou informar um formato inválido
- **THEN** o pipeline interrompe a execução com erro explicativo antes de realizar commits ou tags

### Requirement: Cálculo da Versão Estável de Release
A ferramenta de cálculo DEVE processar a versão declarada no `frontend/pubspec.yaml` e calcular a versão oficial de lançamento de acordo com o tipo de incremento solicitado e o estado do ciclo de desenvolvimento.

#### Scenario: Resolução de patch em ciclo de desenvolvimento ativo
- **WHEN** a versão atual contiver o sufixo `-dev` (ex: `0.1.4-dev+10`) e o tipo de incremento for `patch`
- **THEN** a versão de release calculada DEVE ser a versão semântica sem o sufixo `-dev` (ex: `0.1.4`), preservando o patch já planejado

#### Scenario: Resolução de patch a partir de versão estável
- **WHEN** a versão atual não contiver o sufixo `-dev` (ex: `0.1.3+10`) e o tipo de incremento for `patch`
- **THEN** a versão de release calculada DEVE incrementar o número do patch (ex: `0.1.4`)

#### Scenario: Incremento do número de build no release
- **WHEN** a versão oficial de release for calculada
- **THEN** o número de build (`+build`) DEVE ser incrementado em exatamente 1 unidade em relação ao build atual de desenvolvimento

### Requirement: Avanço Automático do Ciclo de Desenvolvimento Pós-Release
Imediatamente após a marcação da tag de release e commit da versão estável, o sistema DEVE avançar a versão do repositório para o ciclo de desenvolvimento do patch imediatamente posterior com sufixo `-dev`.

#### Scenario: Abertura de próximo ciclo dev pós-lançamento de patch
- **WHEN** uma versão estável `0.1.4` com build `11` for lançada
- **THEN** o sistema DEVE gravar no `frontend/pubspec.yaml` a versão `0.1.5-dev+12` e enviar o commit para a branch `main`

#### Scenario: Abertura de próximo ciclo dev pós-lançamento de minor ou major
- **WHEN** uma versão estável `0.2.0` (minor) ou `1.0.0` (major) for lançada
- **THEN** o sistema DEVE gravar no `frontend/pubspec.yaml` a versão `0.2.1-dev` ou `1.0.1-dev` respectivamente, com build incrementado

### Requirement: Validação Semântica Estrita e Prevenção de Retrocessos
O sistema DEVE validar estritamente o formato SemVer de versões de entrada e impedir que versões iguais ou inferiores à versão atual sejam lançadas.

#### Scenario: Tentativa de versão custom menor ou igual à versão atual
- **WHEN** o operador fornecer em `custom_version` uma versão semântica menor ou igual à versão base em desenvolvimento
- **THEN** o utilitário DEVE falhar com mensagem de erro informativa rejeitando o retrocesso

#### Scenario: Formato SemVer inválido
- **WHEN** qualquer entrada de versão violar a expressão regular SemVer `MAJOR.MINOR.PATCH`
- **THEN** o utilitário DEVE recusar o processamento e retornar código de saída diferente de zero
