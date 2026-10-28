# Spec Delta

## ADDED Requirements

### Requirement: Exibição de Splash Screen com Logo em Aberturas Normais e por Deep Link
O sistema DEVE (MUST) apresentar a splash screen com a logo da marca desde a abertura nativa da atividade (incluindo intents `ACTION_VIEW` no Android 13+ via `windowSplashScreenBehavior="icon_preferred"`) e transicionar imediatamente no `runApp` para uma tela de splash reativa do Flutter (`#ffffff` com a logo centralizada) enquanto o bootstrap local e a resolução de deep links iniciais são processados.

#### Scenario: Abertura a frio via Deep Link no Android 13+
- **WHEN** o usuário toca em um link externo com o aplicativo fechado em um dispositivo Android 13+
- **THEN** a janela nativa exibe o ícone da splash screen sobre fundo `#ffffff` e transiciona sem tela em branco para a splash do Flutter até o destino estar pronto

#### Scenario: Indicador de progresso durante resolução de link online na splash
- **WHEN** a abertura a frio ocorre a partir de um deep link cujo croqui precisa ser sincronizado ou baixado da rede
- **THEN** a tela de splash mantém a logo visível e exibe um indicador discreto de carregamento até a transição direta para a tela de destino

#### Scenario: Preservação do bloqueio de migração estrutural após a splash
- **WHEN** o bootstrap inicial concluir e detectar que a versão estrutural de dados exige migração (`needsMigration == true`) e os termos legais já foram aceitos
- **THEN** o sistema DEVE apresentar a tela bloqueante de migração de banco de dados antes de liberar a navegação principal
