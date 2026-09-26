## MODIFIED Requirements

### Requirement: Telemetria de Links Externos de Comunidade e Time
O sistema DEVE (MUST) registrar evento de telemetria com a URL e canal correspondente sempre que o usuário acionar um link externo na aba Comunidade ou na tela "Sobre o Time" (WhatsApp, Instagram, LinkedIn, Discord, GitHub). Adicionalmente, o sistema DEVE validar o retorno de sucesso do mecanismo de abertura nativo e registrar falha no log de auditoria sempre que a abertura não for concluída com sucesso pelo sistema operacional.

#### Scenario: Acesso ao grupo de WhatsApp ou Discord a partir da Comunidade
- **WHEN** o usuário toca no card "Grupo do WhatsApp" ou "Discord dos Desenvolvedores" na tela de Comunidade
- **THEN** o sistema registra evento de link externo com a URL no parâmetro `detalhe` e `origem: 'comunidade'` ou `origem: 'sobre_time'` antes de abrir o link externo.

#### Scenario: Falha no lançamento de aplicativo ou navegador nativo
- **WHEN** o sistema operacional retornar `false` ou lançar exceção ao tentar abrir um link externo
- **THEN** o sistema registra imediatamente uma ocorrência no log de erros contextualizando o nome do serviço e a URL que falhou.

## ADDED Requirements

### Requirement: Telemetria de Navegação Interna e Termos na Comunidade
O sistema DEVE (MUST) registrar eventos analíticos ao acionar a navegação para telas institucionais e ao abrir os modais de termos de uso e privacidade a partir da aba Comunidade.

#### Scenario: Toque no card Sobre o Time na Comunidade
- **WHEN** o usuário toca no card "SOBRE O TIME" na página de Comunidade
- **THEN** o sistema despacha evento de telemetria com `acao: 'navegar_sobre_time'` e `origem: 'comunidade'` antes de transicionar a navegação.

#### Scenario: Abertura do modal de Termos de Uso e Privacidade
- **WHEN** o usuário clica no card de Termos de Uso e Privacidade
- **THEN** o sistema despacha evento de telemetria com `acao: 'abrir_termos'` e `origem: 'comunidade'`.
