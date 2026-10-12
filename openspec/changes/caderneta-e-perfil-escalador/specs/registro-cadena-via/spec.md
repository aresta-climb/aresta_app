# Spec Delta: registro-cadena-via

## Purpose

Fornece o fluxo e a interface de registro de cadenas e tentativas diretamente na tela de detalhes da via (`via.dart`), incluindo o modal tátil `ModalRegistroCadena` com validação de entradas, notas privadas limitadas a 200 caracteres e o selo esportivo visual da melhor ascensão alcançada.

## ADDED Requirements

### Requirement: Selo Visual de Conquista na Tela da Via
A tela de detalhes da via MUST exibir um indicador visual de realização esportiva quando o usuário possuir cadenas registradas para a respectiva via (`escalada.uid`).

#### Scenario: Exibição do melhor estilo alcançado
- **WHEN** o usuário abre uma via que já possui ascensões registradas na caderneta
- **THEN** a tela exibe um selo com ícone e texto informando a data e o melhor estilo (ex: *"✓ Encadenada em 14/09 (Flash)"*)
- **AND** a cor e destaque respeitam a prioridade esportiva do estilo

#### Scenario: Via sem ascensões registradas
- **WHEN** o usuário abre uma via sem nenhum registro prévio na caderneta
- **THEN** nenhum selo de cadena conquistada é renderizado, mantendo a interface limpa

### Requirement: Botão de Ação de Registro de Cadena
A tela de detalhes da via MUST fornecer um botão de ação destacado permitindo ao usuário registrar uma ascensão ou tentativa para a via corrente.

#### Scenario: Abertura do modal de registro
- **WHEN** o usuário toca no botão de registrar cadena
- **THEN** o `ModalRegistroCadena` é aberto como uma folha inferior (*bottom sheet*) contendo os dados pré-preenchidos da via

### Requirement: Modal de Registro de Cadena (ModalRegistroCadena)
O sistema MUST fornecer o componente `ModalRegistroCadena` para coleta estruturada dos dados da ascensão.

#### Scenario: Seleção de estilo esportivo
- **WHEN** o modal é exibido
- **THEN** são apresentados chips selecionáveis para `À Vista`, `Flash`, `Trabalhado` e `Tentativa`
- **AND** apenas um estilo pode estar ativo simultaneamente

#### Scenario: Ajuste de tentativas
- **WHEN** o usuário altera o contador de tentativas
- **THEN** o valor mínimo permitido é 1 e o valor é incrementado/decrementado via controles táteis

#### Scenario: Seleção de data da ascensão
- **WHEN** o usuário aciona o seletor de data
- **THEN** o seletor nativo de data é aberto com a data de hoje selecionada por padrão e permite datas passadas

#### Scenario: Inserção de notas técnicas privadas
- **WHEN** o usuário digita no campo de notas privadas
- **THEN** o contador de caracteres exibe o progresso até o limite de 200 caracteres
- **AND** caracteres adicionais além de 200 são bloqueados

#### Scenario: Salvamento com sucesso
- **WHEN** o usuário clica em "Salvar na Caderneta"
- **THEN** uma nova instância de `Cadena` é gerada com UUID v4 e salva no `RepositorioCaderneta`
- **AND** o modal é fechado e uma notificação de confirmação (*snackbar*) é exibida
