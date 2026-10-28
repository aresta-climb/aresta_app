## Purpose

Garantir o funcionamento offline instantâneo do aplicativo desde o primeiro acesso.

## Requirements

### Requirement: Inicialização Local Instantânea
O sistema MUST (DEVE) inicializar o app usando o `indice.binarypb` cacheado localmente ou pré-embutido antes de iniciar qualquer requisição de rede.

#### Scenario: App aberto com rede lenta
- **WHEN** o usuário abre o aplicativo em uma conexão lenta
- **THEN** a tela inicial renderiza instantaneamente com os dados locais enquanto a sincronização de rede roda silenciosamente em background

### Requirement: Descompactação de Primeiro Acesso
O sistema MUST (DEVE) empacotar no script de preload (`tool/sync_preload.dart`) e descompactar no primeiro acesso (`ExtratorAssetsPreload`) o banco SQLite `catalogo.db` juntamente com o `indice.binarypb` e as thumbnails pré-baixadas para o diretório de documentos local do dispositivo.

#### Scenario: Instalação nova sem internet
- **WHEN** o usuário instala e abre o app pela primeira vez sem internet
- **THEN** o app copia `assets/preload/indice.binarypb`, `assets/preload/catalogo.db` e `assets/preload/thumbnails/*.webp` para o diretório de documentos local, permitindo tanto a visualização do mapa inicial quanto a Busca Global em todo o catálogo offline imediatamente.

### Requirement: Checagem de Versão Não-Bloqueante
O sistema MUST (DEVE) renderizar a interface gráfica imediatamente na inicialização da aplicação, sem bloquear o primeiro frame por requisições de rede do Firebase Remote Config, degradando silenciosamente para os padrões locais (`defaults`) e cache quando o dispositivo estiver sem conectividade.

#### Scenario: Abertura do app em rede lenta ou instável
- **WHEN** o usuário abre o aplicativo com conexão de rede instável, captive portal ou ausente sem modo avião
- **THEN** a interface da aplicação (Home ou Termos de Uso) é renderizada imediatamente sem exibir uma tela preta/cinza bloqueante

#### Scenario: Atualização de versão em segundo plano
- **WHEN** uma nova versão mínima (hard block) ou recomendada (soft banner) for recebida pelo Firebase Remote Config em segundo plano
- **THEN** o widget AppVersionChecker atualiza o estado reativamente para apresentar o banner ou tela de bloqueio correspondente

#### Scenario: Falha do Firebase Remote Config ou Installations sem internet na inicialização
- **WHEN** `RemoteConfigService.instance.initialize()` executar `fetchAndActivate()` sem conexão com a internet e o SDK nativo lançar erro de obtenção de token do Firebase Installations ou falha de comunicação com o backend
- **THEN** o `RemoteConfigService` DEVE manter os valores padrão configurados em `setDefaults`, registrar apenas um aviso contextual (`logAviso`) sem enviar erro não-fatal ao Crashlytics e limpar a referência da tentativa falha (`_initFuture`) para permitir nova sincronização futura na sessão.

### Requirement: Geolocalização de Picos 100% Local e Offline
O sistema MUST (DEVE) obter coordenadas geográficas exclusivamente através do GPS local e cache persistido em disco (`SharedPreferences`), sem realizar requisições HTTP externas para resolução de localização por IP.

#### Scenario: Falha de GPS em área sem cobertura
- **WHEN** o sinal de satélite GPS demorar para responder ou estiver indisponível
- **THEN** o carrossel de picos próximos utiliza a última coordenada conhecida persistida em disco sem realizar chamadas de rede externas

#### Scenario: Coordenadas salvas em disco
- **WHEN** uma nova leitura de GPS for obtida com sucesso
- **THEN** as coordenadas de latitude e longitude são salvas no armazenamento local para uso futuro imediato

### Requirement: Migração Estrutural de Dados com Auto-Retry e Fases Claras
O sistema MUST (DEVE) exibir etapas visuais de progresso e diagnóstico contextual na tela de migração de banco de dados, retomando automaticamente a sincronização quando a conectividade com a internet for restabelecida.

#### Scenario: Exibição de etapas de progresso e diagnóstico
- **WHEN** a tela de migração de dados for exibida
- **THEN** o usuário visualiza mensagem contextual explicando a atualização e a indicação da etapa atual de download/processamento

#### Scenario: Retomada automática ao restabelecer conectividade
- **WHEN** o dispositivo estiver sem internet na tela de migração e a conectividade de rede for restabelecida
- **THEN** o processo de sincronização é iniciado automaticamente via listener reativo sem exigir clique manual no botão de repetição

### Requirement: Migração em Segundo Plano Pós-Atualização de Pacote no Android
O sistema MUST (DEVE) escutar o evento de atualização de pacote no Android (`ACTION_MY_PACKAGE_REPLACED`) e enfileirar uma tarefa em segundo plano via `WorkManager` para sincronizar o catálogo de dados e migrar os croquis salvos de forma silenciosa.

#### Scenario: Atualização automática da Google Play com Wi-Fi
- **WHEN** a Google Play Store atualizar o aplicativo e o dispositivo possuir conexão com a internet
- **THEN** o `WorkManager` executa a tarefa `tarefa_migracao_pos_atualizacao` em segundo plano, baixando o novo índice e os croquis salvos antes do primeiro acesso do usuário

### Requirement: Prioridade de Primeiro Plano (Foreground Takeover)
O sistema MUST (DEVE) cancelar qualquer execução em andamento da tarefa de migração em segundo plano ao iniciar a aplicação em primeiro plano, assumindo o controle do processo e aproveitando os arquivos temporários já baixados.

#### Scenario: Abertura do app durante a migração em segundo plano
- **WHEN** o usuário abrir o aplicativo enquanto a tarefa de migração do `WorkManager` estiver em execução
- **THEN** o aplicativo cancela a tarefa em segundo plano, retoma o download a partir dos arquivos `.tmp` existentes e conclui a migração na interface com o usuário

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
