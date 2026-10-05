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
O formulário de feedback DEVE (MUST) apresentar uma mensagem informativa direta e em linha única ("Feedback público. Nenhum dado pessoal é exposto.") antes do botão de envio, garantindo transparência sobre a visibilidade comunitária sem uso de termos técnicos e sem quebras de linha em telas estreitas.

#### Scenario: Exibição da mensagem de transparência
- **WHEN** a folha de feedback in-app é renderizada para o usuário
- **THEN** o texto "Feedback público. Nenhum dado pessoal é exposto." é visível em linha única imediatamente acima do botão de envio.

#### Scenario: Adaptação visual em telas compactas
- **WHEN** a folha de feedback é renderizada em telas de largura reduzida (320 a 360 dp)
- **THEN** o texto do aviso é redimensionado proporcionalmente via `FittedBox` mantendo-se estritamente em uma única linha e legível.

### Requirement: Dimensionamento Adaptativo e Contextual do Bottom Sheet sem Rolagem
O formulário de feedback DEVE (MUST) calcular dinamicamente a fração de altura da folha (`feedbackSheetHeight`) proporcionalmente à altura da janela do dispositivo e à barra de navegação do SO, adotando uma altura alvo diferenciada para telas com croqui ativo (216 dp, acomodando o seletor `SegmentedButton` e 12 dp de respiro inferior) versus telas neutras (168 dp, sem seletor), preservando a barra do SO independentemente de consumo por `Scaffold` ou `BottomNavigationBar`, eliminando sobras pretas e cortes verticais e mantendo a maior parte da tela desobstruída para anotações.

#### Scenario: Abertura do formulário com croqui ativo
- **WHEN** o usuário aciona o feedback estando dentro de um croqui ou setor
- **THEN** a fração é calculada adotando a altura líquida de 216 dp somada ao padding da barra do SO
- **AND** o botão "Enviar" é exibido com margem de 12 dp de respiro inferior sem ser cortado pelos menus do SO.

#### Scenario: Abertura do formulário em tela neutra sem croqui
- **WHEN** o usuário aciona o feedback fora de croquis (Home, Configurações, Comunidade)
- **THEN** a fração é calculada adotando a altura líquida de 168 dp somada ao padding real da barra do SO (extraído diretamente da janela física)
- **AND** nenhum espaço vazio residual ou faixa preta desnecessária é exibida abaixo do botão
- **AND** o botão "Enviar" permanece inteiramente visível mesmo em telas com `BottomNavigationBar`.

#### Scenario: Adaptação à barra de navegação do SO (3 botões vs gestos vs imersivo)
- **WHEN** o dispositivo possui barra de navegação tradicional de 3 botões (ex.: ~48 dp) ou navegação por gestos (ex.: ~16 dp)
- **THEN** a altura total é expandida exatamente pelo valor do padding inferior da janela física, e o `SafeArea` interno posiciona o formulário imediatamente acima da barra do SO.

#### Scenario: Adaptação em telas compactas e grandes
- **WHEN** a fração de altura é calculada
- **THEN** o resultado é delimitado pelo piso de 0.18 e teto de 0.45 (`clamp(0.18, 0.45)`).

### Requirement: Conformidade e Transparência na Política de Privacidade
A Política de Privacidade do aplicativo DEVE (MUST) detalhar explicitamente o fluxo de feedback dos usuários, informando a disponibilização pública no GitHub dos relatos e capturas de tela desenhadas, a guarda restrita de diagnósticos técnicos no Supabase e a inclusão desses provedores na lista de serviços de terceiros, com integridade versionada em `legal_version.g.dart`.

#### Scenario: Documentação da coleta e destinação de feedbacks
- **WHEN** os termos da Política de Privacidade são consultados
- **THEN** há uma seção dedicada esclarecendo a publicação comunitária dos feedbacks e a não exposição de dados pessoais
- **AND** o hash dos documentos legais em `legal_version.g.dart` reflete com precisão o conteúdo atualizado.

### Requirement: Telemetria Completa do Ciclo de Vida do Feedback
O ciclo de vida do feedback in-app DEVE (MUST) ser mensurado de ponta a ponta via eventos de telemetria no Firebase Analytics (`acao_feedback`), registrando a abertura, a submissão com métricas de engajamento, o cancelamento/descarte e o despacho em segundo plano.

#### Scenario: Registro de abertura de feedback
- **WHEN** o usuário aciona o botão de feedback na barra superior (`app_bar`) ou pelo diálogo de Beta Aberto (`modal_beta`)
- **THEN** o evento `acao_feedback` é emitido com `acao: 'abrir_feedback'`, `origem` correspondente, `tem_croqui: 'true'/'false'` e `id_croqui` quando presente.

#### Scenario: Registro de submissão de feedback
- **WHEN** o usuário confirma o envio de um feedback
- **THEN** o evento `acao_feedback` é emitido com `acao: 'enviar_feedback'`, `tipo_feedback` ('croqui' ou 'app'), `id_croqui`, `tem_croqui` e `qtd_caracteres` com a contagem de caracteres digitados.

#### Scenario: Registro de descarte ou desistência do feedback
- **WHEN** o usuário abre a folha de feedback e a fecha sem confirmar o envio (via botão de fechar, gesto de arrastar para baixo ou botão voltar do sistema)
- **THEN** o evento `acao_feedback` é emitido com `acao: 'cancelar_feedback'` e `origem: 'descarte_usuario'`.
- **AND** caso o envio tenha sido concluído com sucesso, o evento de cancelamento NÃO é emitido.

#### Scenario: Registro do despacho em segundo plano
- **WHEN** o `FeedbackOrchestrator` executa o envio de um feedback enfileirado localmente
- **THEN** o evento `acao_feedback` é emitido com `acao: 'despacho_feedback'`, `status` ('sucesso' ou 'falha'), `dispatcher` ('workmanager', 'connectivity_plus', etc.), `tipo_feedback`, `id_croqui` e `erro` detalhado em caso de falha.

