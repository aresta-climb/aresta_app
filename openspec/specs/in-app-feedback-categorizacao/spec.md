# In-App Feedback Categorization Specification

## Purpose
Padroniza a interface de coleta de feedback no aplicativo móvel Aresta, fornecendo categorização contextual explícita (Croqui vs App), identificação visual por ícone de alerta triangular e comunicação transparente de publicação pública no GitHub.

## Requirements

### Requirement: Ícone de Alerta Triangular na Barra de Ações
O botão de acionamento do feedback in-app DEVE (MUST) utilizar o ícone Material `Icons.warning_amber_rounded` (alerta com moldura triangular e cantos arredondados) em substituição ao ícone de inseto (`Icons.bug_report`).

#### Scenario: Visualização do botão de feedback na barra superior
- **WHEN** o usuário visualiza qualquer tela ou modal que contenha o botão de feedback (`buildFeedbackButton`)
- **THEN** o botão é renderizado com o ícone `Icons.warning_amber_rounded` e tooltip descritivo.

### Requirement: Categorização Contextual com SegmentedButton
Quando o usuário acionar o envio de feedback a partir de uma tela vinculada a um croqui, setor ou via ativo, o formulário DEVE (MUST) exibir um seletor visual em formato de `SegmentedButton` com as opções "Sobre o Croqui" e "Sobre o App", sem pré-seleção inicial. O botão primário "Enviar" DEVE (MUST) permanecer desabilitado até que uma das categorias seja selecionada E o campo descritivo seja preenchido.

#### Scenario: Abertura do feedback com croqui em exibição
- **WHEN** o usuário abre a folha de feedback estando em uma tela com `cragId` ativo
- **THEN** o título exibe "Sobre o que é a sugestão?"
- **AND** o `SegmentedButton` exibe as opções "Sobre o Croqui" e "Sobre o App" desmarcadas
- **AND** o botão "Enviar" permanece desabilitado até que o usuário selecione uma opção e insira texto no campo descritivo.

#### Scenario: Envio de feedback categorizado como croqui
- **WHEN** o usuário seleciona "Sobre o Croqui", preenche a descrição e toca em "Enviar"
- **THEN** o payload despachado inclui o metadado `tipoFeedback: "croqui"`.

#### Scenario: Envio de feedback categorizado como app
- **WHEN** o usuário seleciona "Sobre o App", preenche a descrição e toca em "Enviar"
- **THEN** o payload despachado inclui o metadado `tipoFeedback: "app"`.

### Requirement: Omissão do Seletor em Telas Neutras
Quando o usuário acionar o envio de feedback a partir de uma tela neutra (sem nenhum croqui associado, como tela inicial, configurações, termos de uso ou comunidade), o formulário DEVE (MUST) ocultar completamente o seletor `SegmentedButton` e atribuir automaticamente a categoria "app" aos metadados de envio.

#### Scenario: Abertura do feedback em tela neutra
- **WHEN** o usuário abre a folha de feedback a partir da tela inicial (Home) ou de configurações
- **THEN** o título "Sobre o que é a sugestão?" é exibido
- **AND** o `SegmentedButton` não é renderizado na tela
- **AND** o botão "Enviar" é habilitado assim que o campo descritivo for preenchido
- **AND** ao enviar, o metadado `tipoFeedback` é automaticamente preenchido como `"app"`.

### Requirement: Aviso de Transparência e Consentimento de Publicação
O formulário de feedback DEVE (MUST) apresentar uma mensagem informativa de rodapé esclarecendo que a descrição e a captura de tela serão disponibilizadas publicamente no GitHub comunitário do projeto para atuação dos mantenedores, garantindo que nenhum dado pessoal ou identificador do aparelho é exposto.

#### Scenario: Exibição da mensagem de transparência
- **WHEN** a folha de feedback in-app é renderizada para o usuário
- **THEN** uma mensagem de rodapé explicativa é visível abaixo do campo de texto antes do botão de envio.
