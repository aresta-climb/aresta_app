# publicacao-producao-lojas Specification

## Purpose
Padroniza a validação de notas de lançamento e a orquestração unificada de publicação para produção e teste interno no Google Play Console e Apple App Store a partir do pipeline de CI/CD.

## Requirements

### Requirement: Validação Precoce das Notas de Lançamento
O workflow unificado de release DEVE exigir a entrada de notas de lançamento no acionamento manual e validar seu comprimento antes de iniciar compilações ou alterações de código, rejeitando entradas vazias ou com mais de 500 caracteres.

#### Scenario: Notas de lançamento com tamanho válido
- **WHEN** o operador informar um texto com tamanho entre 1 e 500 caracteres no campo `release_notes`
- **THEN** o pipeline prossegue com a preparação da release e compilação dos artefatos

#### Scenario: Notas de lançamento ausentes ou vazias
- **WHEN** o operador acionar o workflow deixando o campo `release_notes` em branco
- **THEN** o pipeline DEVE falhar imediatamente no primeiro job com mensagem de erro informativa em português

#### Scenario: Notas de lançamento excedendo o limite de 500 caracteres
- **WHEN** o operador informar um texto com mais de 500 caracteres no campo `release_notes`
- **THEN** o pipeline DEVE abortar a execução no primeiro job sem realizar commits ou tags, indicando a quantidade de caracteres excedentes

### Requirement: Controle Unificado de Publicação em Produção
O workflow unificado DEVE disponibilizar uma opção booleana `enviar_para_producao` que comande de forma sincronizada o destino de publicação no Google Play e na App Store.

#### Scenario: Disparo com publicação em produção ativada
- **WHEN** o operador acionar o workflow com `enviar_para_producao` definido como `true`
- **THEN** o pipeline de Android envia a release para as faixas `internal,production` e o pipeline de iOS executa o job de submissão para revisão pública na App Store

#### Scenario: Disparo com publicação restrita a testes
- **WHEN** o operador acionar o workflow com `enviar_para_producao` definido como `false`
- **THEN** o pipeline de Android envia a release apenas para a faixa `internal` e o pipeline de iOS envia o binário apenas para o TestFlight sem submeter para revisão na App Store

### Requirement: Injeção de Notas de Versão no Google Play
O pipeline de deploy do Android DEVE gerar a estrutura de arquivos de novidades da versão e anexá-las ao upload da release no Google Play Console.

#### Scenario: Envio de notas de versão em português para a Google Play Store
- **WHEN** o job de deploy do Android for executado
- **THEN** o sistema gera dinamicamente o arquivo `whatsnew-pt-BR` contendo as `release_notes` informadas e o vincula ao envio via action de publicação

### Requirement: Submissão Automatizada para Revisão da Apple App Store
O pipeline de release DEVE fornecer um job desacoplado em ambiente Linux que aguarda o processamento do binário pela Apple e submete a versão para análise pública da App Store quando a publicação em produção for solicitada.

#### Scenario: Execução de submissão pós-upload
- **WHEN** o build e upload do IPA forem concluídos com sucesso e `enviar_para_producao` for `true`
- **THEN** o job em Linux autentica via API REST da Apple, aguarda a conclusão do processamento da build, anexa a build à respectiva versão, preenche as notas de versão em `pt-BR` e submete para revisão do App Store

#### Scenario: Supressão da submissão para revisão
- **WHEN** `enviar_para_producao` for `false` ou o deploy de iOS estiver desativado
- **THEN** o job de submissão para revisão da App Store NÃO é executado

#### Scenario: Configuração de liberação sem fases
- **WHEN** a submissão para revisão na App Store for enviada
- **THEN** a opção de liberação em fases (`phased_release`) DEVE ser explicitamente desativada (`false`) e a liberação automática após aprovação (`automatic_release`) DEVE ser ativada (`true`)

### Requirement: Preservação dos Registros de Versionamento Git
O workflow de release DEVE manter mensagens de commit e anotações de tags estritamente limpas, isolando o conteúdo de `release_notes` apenas nas variáveis de publicação das lojas.

#### Scenario: Criação de commits e tags de release
- **WHEN** o job de preparação de release registrar os commits e a tag da nova versão no repositório
- **THEN** as mensagens de commit e o nome da tag NÃO DEVEM conter o texto de `release_notes`, preservando o padrão esperado por geradores automáticos de notas do repositório
