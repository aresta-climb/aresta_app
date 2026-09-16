## Purpose

Padronizar e gerenciar a identificação visual e a comunicação interativa do estágio de "Beta Aberto" no aplicativo Aresta Climb, alinhando expectativas dos usuários e incentivando o envio de feedbacks construtivos.

## ADDED Requirements

### Requirement: Identificação Visual do Beta na Splash Screen
A tela de inicialização nativa (Splash Screen) DEVE (MUST) exibir o logotipo oficial contendo a inscrição `CLIMB • BETA` centralizada, mantendo suporte nativo completo para Android e iOS através do `flutter_native_splash`.

#### Scenario: Visualização do logotipo com marcação de beta na inicialização
- **WHEN** o aplicativo é inicializado no dispositivo pelo usuário
- **THEN** a tela de abertura nativa apresenta o logotipo central com a inscrição `CLIMB • BETA` antes da renderização do primeiro frame do Flutter

### Requirement: Micro-Badge Interativo de Beta no Cabeçalho da Home
A página inicial (Home) DEVE (MUST) exibir um micro-badge compacto com o texto `BETA` posicionado adjacente ao identificador de marca `ARESTA`, utilizando dimensões reduzidas para garantir que nenhum erro de transbordamento visual (`RenderFlex overflow`) ocorra em telas de largura estreita (360dp ou superior).

#### Scenario: Renderização responsiva do micro-badge na Home
- **WHEN** a tela inicial é carregada em qualquer dispositivo móvel suportado
- **THEN** o micro-badge `BETA` é renderizado ao lado do bloco `ARESTA` com padding compacto e estilo em verde musgo (`dryMoss`), sem causar transbordamento horizontal

#### Scenario: Abertura do modal informativo ao tocar no badge
- **WHEN** o usuário toca sobre o micro-badge `BETA` no cabeçalho da Home
- **THEN** o aplicativo abre um BottomSheet com as informações detalhadas sobre a fase de Beta Aberto

### Requirement: Modal Informativo de Beta com Ação Direta de Feedback
O modal informativo de Beta Aberto DEVE (MUST) explicar que o aplicativo é uma iniciativa independente em desenvolvimento ativo com a comunidade, destacar que novos recursos estão sendo adicionados continuamente e fornecer um botão de ação primário para envio de feedback.

#### Scenario: Toque no botão de envio de feedback no modal de beta
- **WHEN** o usuário visualiza o modal de Beta Aberto e clica no botão "Enviar Sugestão"
- **THEN** o modal é fechado e o fluxo de captura e envio do `BetterFeedback` é imediatamente acionado na tela

### Requirement: Sinalização de Versão Beta em Configurações e Comunidade
As telas de apoio (Configurações e Comunidade) DEVEM (MUST) explicitar o status de "Beta Aberto" junto ao número de versão oficial da compilação do aplicativo obtido de `PackageInfo`.

#### Scenario: Visualização de versão na página de Configurações
- **WHEN** o usuário navega até a página de Configurações
- **THEN** o rodapé da lista apresenta o texto `Aresta Climb v<versão> (Beta Aberto)` com ação interativa para abrir o modal informativo

#### Scenario: Visualização de versão na página da Comunidade
- **WHEN** o usuário navega até a página de Comunidade
- **THEN** o card de rodapé exibe o título `Aresta Climb v<versão> • Beta Aberto`
