# offline-first-initialization Specification Delta

## MODIFIED Requirements

### Requirement: Exibição de Splash Screen com Logo em Aberturas Normais e por Deep Link
O sistema DEVE (MUST) apresentar a splash screen com a logo da marca desde a abertura nativa da atividade (incluindo intents `ACTION_VIEW` no Android 13+ via `windowSplashScreenBehavior="icon_preferred"`) e transicionar imediatamente no `runApp` para uma tela de splash reativa do Flutter (`#ffffff` com a logo centralizada nas mesmas dimensões de `288x288 dp` da splash nativa) enquanto o bootstrap local e a resolução de deep links iniciais são processados, encerrando a splash screen com uma transição suave de opacidade (*fade*) para a árvore de navegação principal.

#### Scenario: Abertura a frio via Deep Link no Android 13+
- **WHEN** o usuário toca em um link externo com o aplicativo fechado em um dispositivo Android 13+
- **THEN** a janela nativa exibe o ícone da splash screen sobre fundo `#ffffff` e transiciona sem tela em branco nem mudança de escala do ícone para a splash do Flutter até o destino estar pronto

#### Scenario: Indicador de progresso durante resolução de link online na splash
- **WHEN** a abertura a frio ocorre a partir de um deep link cujo croqui precisa ser sincronizado ou baixado da rede
- **THEN** a tela de splash mantém a logo centralizada na posição exata e exibe um indicador discreto de carregamento abaixo dela até a transição para a tela de destino

#### Scenario: Transição suave de saída da splash screen no Cold Start
- **WHEN** o bootstrap inicial e a resolução da rota inicial terminam e `exibindoSplashInicial` muda para `false`
- **THEN** o aplicativo realiza uma transição suave de fade (~250ms) entre a `TelaSplashInicial` e a tela de destino sem corte visual abrupto

#### Scenario: Preservação do bloqueio de migração estrutural após a splash
- **WHEN** o bootstrap inicial concluir e detectar que a versão estrutural de dados exige migração (`needsMigration == true`) e os termos legais já foram aceitos
- **THEN** o sistema DEVE apresentar a tela bloqueante de migração de banco de dados antes de liberar a navegação principal

## ADDED Requirements

### Requirement: Prevenção de Flash Branco em Retomadas de Segundo Plano (Warm Start)
O sistema DEVE (MUST) manter o fundo branco (`#FFFFFF`) na janela nativa exclusivamente durante a primeira abertura a frio (*Cold Start*) e alterar o fundo da janela nativa da atividade para a cor escura do tema (`#181312` `deepBasalt`) assim que a atividade for enviada para segundo plano (`onStop`), garantindo que qualquer retomada subsequente (*Warm Start* ou *Hot Start*) ocorra sobre fundo escuro sem exibir piscadas brancas durante a restauração da superfície gráfica do Flutter.

#### Scenario: Primeira abertura a frio preserva fundo branco da splash
- **WHEN** o aplicativo é iniciado do zero (*Cold Start*) antes de qualquer ida para segundo plano
- **THEN** a janela nativa mantém o fundo `#FFFFFF` alinhado à splash screen até a renderização do Flutter

#### Scenario: Retomada do aplicativo em segundo plano sem piscada branca
- **WHEN** o aplicativo já foi aberto, vai para segundo plano (`onStop`) e posteriormente é retomado pelo usuário ou por um link externo (*Warm Start*)
- **THEN** a janela nativa possui fundo `#181312` (`deepBasalt`) e a superfície do Flutter é restaurada sem qualquer flash branco na tela
