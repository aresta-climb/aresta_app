## ADDED Requirements

### Requirement: Minimização Não-Destrutiva ao Acionar Retorno na Raiz da Navegação
Quando o usuário acionar o comando de retorno do sistema operacional estando na raiz da tela inicial (`HomeNode`), o sistema DEVE (MUST) enviar a tarefa do aplicativo para segundo plano preservando a atividade principal e o motor de renderização vivos em memória, evitando a destruição da atividade e forçar um novo *Cold Start* na reabertura subsequente.

#### Scenario: Botão ou gesto Voltar acionado na raiz da Home no Android
- **WHEN** o usuário está na raiz da aba inicial (`HomeNode`) sem diálogos ou painéis de feedback abertos e aciona o gesto ou botão "Voltar" do sistema
- **THEN** o aplicativo move a tarefa para segundo plano (`moveTaskToBack`) mantendo a `MainActivity` e a `FlutterEngine` ativas em memória
- **AND** ao reabrir o aplicativo em seguida, a sessão retoma instantaneamente (*Warm/Hot Start*) sem reinicializar o motor nem travar na splash screen

#### Scenario: Fallback seguro quando o canal nativo não está disponível
- **WHEN** o usuário aciona o comando "Voltar" na raiz da `HomeNode` em ambiente de teste de widget ou plataforma onde o canal nativo de minimização não está registrado
- **THEN** o sistema realiza fallback seguro para `SystemNavigator.pop()` sem lançar exceção não tratada
