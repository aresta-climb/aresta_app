## Purpose

Fornecer resolução dinâmica, resiliente e segura para os links da comunidade oficial (WhatsApp) e canais externos do Aresta Climb, tanto no aplicativo móvel quanto no site institucional.

## ADDED Requirements

### Requirement: Resolução Dinâmica e Fallback do Link da Comunidade no App
O aplicativo DEVE (MUST) resolver o link da comunidade do WhatsApp através do serviço de configuração remota (`RemoteConfigService`), mantendo valor padrão offline seguro e atualizado imediatamente disponível.

#### Scenario: Uso do valor padrão offline inicial
- **QUANDO** o aplicativo é inicializado sem conectividade ou antes do primeiro fetch de rede
- **THEN** o link da comunidade retornado é o padrão oficial `https://chat.whatsapp.com/JmxWeLSmGTT66AREtrKyjA`

#### Scenario: Atualização de link via Remote Config
- **QUANDO** novos parâmetros são sincronizados do servidor remoto contendo a chave `whatsapp_community_url`
- **THEN** o aplicativo passa a fornecer a nova URL configurada para abertura imediata

### Requirement: Abertura Nativa Direta do WhatsApp pelo App
A tela de comunidade do aplicativo DEVE (MUST) acionar o link da comunidade utilizando o modo de aplicação externa (`LaunchMode.externalApplication`), permitindo a interceptação direta pelo app nativo do WhatsApp via Universal Links e App Links.

#### Scenario: Toque no card do Grupo do WhatsApp
- **QUANDO** o usuário clica no card "GRUPO DO WHATSAPP"
- **THEN** o aplicativo dispara o lançamento da URL obtida do serviço de configuração no modo de aplicação externa

### Requirement: Redirecionamento Web Oficial /comunidade
O site oficial `arestaclimb.com` DEVE (MUST) prover a rota `/comunidade` que redireciona de forma temporária (HTTP 302) para o link oficial de convite da comunidade no WhatsApp.

#### Scenario: Acesso web ao atalho /comunidade
- **QUANDO** um usuário ou navegador acessa a rota `/comunidade`
- **THEN** o servidor web redireciona a requisição com status 302 para `https://chat.whatsapp.com/JmxWeLSmGTT66AREtrKyjA`
