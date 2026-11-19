# Spec Delta: autenticacao-escalador

## Purpose

Provê autenticação opcional e estritamente sem senha para o escalador (protegida atrás da feature flag `ConfiguracaoRecursos.perfilHabilitado`), integrando código OTP numérico de 6 dígitos por e-mail via Supabase/Resend e login social in-app específico por plataforma (Google em Android e iOS; Apple exclusivamente em iOS), preservando integralmente os dados locais offline da caderneta sem recorrer a contas sintéticas de fallback.

## ADDED Requirements

### Requirement: Proteção de Acesso por Feature Flag
O acesso à tela de login e aos pontos de entrada do perfil e da caderneta MUST permanecer integralmente protegido pela flag de recursos `ConfiguracaoRecursos.perfilHabilitado`, mantendo-se oculto por padrão em compilações convencionais de produção sem chave ou flag explícita.

#### Scenario: Aplicativo em compilação padrão com flag desabilitada
- **WHEN** `ConfiguracaoRecursos.perfilHabilitado` avalia como `false`
- **THEN** a barra superior da tela inicial MUST exibir o atalho direto de Configurações em vez do botão de Perfil/Login, mantendo o fluxo de autenticação inacessível ao usuário final

#### Scenario: Aplicativo com flag habilitada e escalador desautenticado
- **WHEN** `ConfiguracaoRecursos.perfilHabilitado` avalia como `true` e o escalador toca no botão de Perfil na tela inicial estando desautenticado
- **THEN** o sistema MUST navegar para a tela de autenticação sem senha

### Requirement: Autenticação Exclusivamente Sem Senha com Código OTP de 6 Dígitos por E-mail
O sistema MUST NOT exibir campos de senha, confirmação de senha ou alternância entre "Entrar" e "Criar conta" por senha, nem trafegar ou armazenar senhas. Para autenticação por e-mail, o sistema MUST operar em duas etapas via código numérico de 6 dígitos (Magic Code OTP): envio para `/auth/v1/otp` (`create_user: true`) e verificação em `/auth/v1/verify` (`type: "email"`), aplicando controle de frequência por janela deslizante de até 6 solicitações a cada 60 segundos.

#### Scenario: Solicitação de código OTP para e-mail válido
- **WHEN** o escalador informa um endereço de e-mail válido e solicita o código de acesso
- **THEN** o sistema MUST disparar `POST /auth/v1/otp` com `create_user: true` e transicionar o cartão de e-mail para a etapa de digitação do código de 6 dígitos

#### Scenario: Confirmação de código OTP válido vincula sessão preservando dados locais
- **WHEN** o escalador informa o código numérico válido de 6 dígitos e confirma
- **THEN** o sistema MUST validar via `POST /auth/v1/verify` (`type: "email"`), sincronizar o perfil com o servidor e persistir a sessão autenticada mantendo intactos as cadenas locais e o identificador público NanoID

#### Scenario: Limite da janela deslizante de 6 envios por minuto atingido
- **WHEN** o escalador realiza 6 solicitações de código OTP dentro de uma janela móvel de 60 segundos
- **THEN** o sistema MUST bloquear novos envios temporariamente e exibir contagem regressiva em segundos até a liberação do próximo disparo

#### Scenario: Código OTP inválido ou expirado exibe erro amigável sem alertar Sentry
- **WHEN** o escalador submete um código OTP incorreto, incompleto ou expirado
- **THEN** o sistema MUST exibir mensagem amigável em português permitindo nova tentativa ou alteração de e-mail, sem registrar erro não-fatal no Sentry

### Requirement: Login Social In-App Específico por Plataforma
O sistema MUST apresentar provedores sociais de acordo com a plataforma de execução — exibindo **Continuar com o Google** no Android e **Continuar com o Google** + **Continuar com a Apple** no iOS — e concluir toda a autenticação dentro do aplicativo (via `CredentialManager` no Android, `ASWebAuthenticationSession` com PKCE para Google no iOS e `ASAuthorizationAppleIDProvider` com capability nativa para Apple no iOS), sem abrir navegador externo nem aguardar redirecionamento fora do app.

#### Scenario: Tela de login no Android oculta botão da Apple
- **WHEN** a tela de login é renderizada na plataforma Android
- **THEN** o sistema MUST exibir o botão **Continuar com o Google**, o cartão de código por e-mail e o botão **Continuar sem conta / Offline**, ocultando o botão **Continuar com a Apple**

#### Scenario: Tela de login no iOS exibe Google e Apple
- **WHEN** a tela de login é renderizada na plataforma iOS
- **THEN** o sistema MUST exibir os botões **Continuar com o Google** e **Continuar com a Apple**, além do cartão de código por e-mail e do botão **Continuar sem conta / Offline**

### Requirement: Tratamento Silencioso de Cancelamento Voluntário
Quando o escalador cancelar ou fechar voluntariamente o seletor nativo do Google, a folha `ASWebAuthenticationSession` ou o modal do Face ID/Touch ID da Apple (`cancelado == true`), o sistema MUST encerrar imediatamente o estado de carregamento sem abrir navegador de fallback, sem exibir banner de erro na interface e sem registrar exceção na observabilidade.

#### Scenario: Escalador cancela o modal de autenticação social
- **WHEN** o escalador fecha ou cancela voluntariamente o modal de login do Google ou da Apple
- **THEN** a tela de login MUST restaurar os botões ao estado interativo imediatamente, sem renderizar `BannerAvisoLogin` de erro e sem enviar evento de erro ao Sentry ou Crashlytics

#### Scenario: Descarte da tela de login durante autenticação assíncrona pendente
- **WHEN** a tela de login e seu `LoginViewModel` são descartados (`dispose`) antes da conclusão de uma chamada assíncrona de autenticação
- **THEN** o `LoginViewModel` MUST ignorar notificações subsequentes sem lançar `FlutterError` de uso após `dispose`

### Requirement: Proibição de Contas Sintéticas de Fallback em Produção
O sistema MUST NOT gerar contas locais fictícias (`usr_*`) quando a chave pública do servidor estiver ausente ou quando um provedor de autenticação falhar. O uso offline desautenticado MUST ocorrer exclusivamente por escolha explícita do escalador na opção **Continuar sem conta / Offline**.

#### Scenario: Ausência de configuração do servidor falha explicitamente
- **WHEN** uma tentativa de login social ou por código OTP ocorre sem chave pública do servidor configurada ou com retorno nulo do canal nativo
- **THEN** o sistema MUST falhar explicitamente sem criar sessão local sintética, registrar a falha operacional no Sentry/Crashlytics e exibir mensagem amigável na interface
