# Spec Delta: in-app-feedback-categorizacao

## MODIFIED Requirements

### Requirement: Aviso de Transparência e Consentimento de Publicação
O formulário de feedback DEVE (MUST) apresentar uma mensagem informativa direta e em linha única ("Feedback público. Nenhum dado pessoal é exposto.") antes do botão de envio, garantindo transparência sobre a visibilidade comunitária sem uso de termos técnicos e sem quebras de linha em telas estreitas.

#### Scenario: Exibição da mensagem de transparência
- **WHEN** a folha de feedback in-app é renderizada para o usuário
- **THEN** o texto "Feedback público. Nenhum dado pessoal é exposto." é visível em linha única imediatamente acima do botão de envio.

#### Scenario: Adaptação visual em telas compactas
- **WHEN** a folha de feedback é renderizada em telas de largura reduzida (320 a 360 dp)
- **THEN** o texto do aviso é redimensionado proporcionalmente via `FittedBox` mantendo-se estritamente em uma única linha e legível.

## ADDED Requirements

### Requirement: Dimensionamento Adaptativo do Bottom Sheet sem Rolagem
O formulário de feedback DEVE (MUST) calcular dinamicamente a fração de altura da folha (`feedbackSheetHeight`) proporcionalmente à altura da janela do dispositivo, assegurando altura fixa suficiente (~210 a 220 dp) para acomodar todos os elementos visuais (seletor, campo descritivo, aviso e botão) sem acionar barra de rolagem vertical, mantendo a maior parte da tela (~75%) desobstruída para marcações na captura de tela.

#### Scenario: Abertura do formulário em dispositivo padrão
- **WHEN** o usuário aciona a ferramenta de feedback em um dispositivo de tamanho padrão
- **THEN** o formulário é exibido ocupando aproximadamente 220 dp de altura vertical
- **AND** nenhum componente requer rolagem vertical para visualização ou interação
- **AND** a área de anotação sobre a captura de tela preserva pelo menos 70% do espaço vertical da tela.

#### Scenario: Abertura do formulário em dispositivo compacto
- **WHEN** o usuário aciona o feedback em um dispositivo compacto com altura de tela reduzida (ex.: ~640 dp)
- **THEN** a fração calculada se ajusta respeitando os limites estabelecidos (clamp entre 0.22 e 0.45)
- **AND** todos os elementos permanecem acessíveis e interativos.

### Requirement: Conformidade e Transparência na Política de Privacidade
A Política de Privacidade do aplicativo DEVE (MUST) detalhar explicitamente o fluxo de feedback dos usuários, informando a disponibilização pública no GitHub dos relatos e capturas de tela desenhadas, a guarda restrita de diagnósticos técnicos no Supabase e a inclusão desses provedores na lista de serviços de terceiros, com integridade versionada em `legal_version.g.dart`.

#### Scenario: Documentação da coleta e destinação de feedbacks
- **WHEN** os termos da Política de Privacidade são consultados
- **THEN** há uma seção dedicada esclarecendo a publicação comunitária dos feedbacks e a não exposição de dados pessoais
- **AND** o hash dos documentos legais em `legal_version.g.dart` reflete com precisão o conteúdo atualizado.
