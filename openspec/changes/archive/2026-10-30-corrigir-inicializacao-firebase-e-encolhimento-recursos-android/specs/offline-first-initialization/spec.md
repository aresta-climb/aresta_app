# Spec Delta

## ADDED Requirements

### Requirement: Inicialização Determinística e Paralelizada de Serviços Locais no Pré-Boot
O sistema DEVE (MUST) aguardar até a conclusão todas as inicializações de plugins nativos locais e cancelamento preventivo de tarefas em segundo plano antes de iniciar os serviços de aplicação e o `runApp`, sem aplicar limites de tempo artificiais em operações 100% locais. Adicionalmente, após a conclusão da inicialização do núcleo do Firebase, o sistema DEVE (MUST) executar em paralelo as ativações independentes de App Check, Crashlytics, Analytics e Performance.

#### Scenario: Conclusão garantida da inicialização do Firebase antes do runApp em dispositivo sob carga de I/O
- **WHEN** o aplicativo inicia a frio (*Cold Start*) em um dispositivo ou emulador cujo canal nativo local leva vários segundos para responder
- **THEN** o pré-boot aguarda a conclusão integral da inicialização do Firebase, das notificações locais e do cancelamento de tarefas em segundo plano antes de prosseguir para a sincronização inicial e montagem da interface gráfica

#### Scenario: Ativação paralela dos módulos locais do Firebase após o núcleo
- **WHEN** a inicialização do núcleo do Firebase (`Firebase.initializeApp`) é concluída com sucesso durante o pré-boot
- **THEN** os módulos locais de App Check, Crashlytics, Analytics e Performance são ativados concorrentemente em paralelo antes da liberação do pré-boot

### Requirement: Guarda Defensiva contra Ausência de Inicialização nos Serviços Firebase
Os serviços de configuração remota, telemetria de uso e telemetria de performance DEVEM (MUST) verificar se o núcleo do Firebase está inicializado antes de acessar instâncias globais do SDK quando nenhuma instância de teste tiver sido injetada, degradando silenciosamente sem lançar exceções de ausência de aplicativo padrão (`[core/no-app]`) nem reportar falsos erros ao monitoramento.

#### Scenario: Tentativa de uso de serviços Firebase quando o núcleo não está inicializado
- **WHEN** os serviços de configuração remota, performance ou telemetria de eventos forem acionados em um ambiente onde o núcleo do Firebase não foi inicializado e nenhuma instância de teste foi fornecida
- **THEN** os serviços retornam de forma segura mantendo valores padrão locais sem lançar `[core/no-app]` e sem emitir eventos de erro não-fatal para o Sentry ou Crashlytics

### Requirement: Garantia de Saída da Splash Reativa com Tratamento de Erros e Diagnóstico Contextual
O sistema DEVE (MUST) garantir a saída da tela de splash reativa através do tratamento de exceções no ciclo de vida de inicialização, preservando o diagnóstico enriquecido de entidades sem conexão (`itemSemConexaoInicial`) para apresentação do diálogo contextual na interface principal sem abortar prematuramente a resolução de rede por limites de tempo redundantes, mantendo inalterado o bloqueio obrigatório da tela de migração estrutural de dados (`needsMigration == true`) e dos Termos de Uso.

#### Scenario: Falha de rede ao resolver Deep Link no Cold Start preserva diagnóstico para o modal
- **WHEN** a abertura a frio via Deep Link falha por ausência de conexão ou timeout da camada HTTP ao obter o croqui
- **THEN** o sistema encerra a splash screen reativa (`_aguardandoColdStart = false`) preservando o `itemSemConexaoInicial` para que o diálogo contextual de croqui sem conexão seja apresentado sobre a navegação principal

#### Scenario: Invariância do bloqueio da tela de migração de versão de dados
- **WHEN** o aplicativo iniciar com `needsMigration == true` (atualização estrutural de `kDataVersion` pendente) e os termos legais já estiverem aceitos
- **THEN** a garantia de saída da splash screen NÃO libera o acesso à `HomeNode`, mantendo a `DatabaseMigrationScreen` bloqueante em tela até que a migração estrutural seja concluída com sucesso

## REMOVED Requirements

### Requirement: Timeouts Defensivos nas Inicializações Assíncronas de Pré-Boot
**Reason**: As inicializações de pré-boot (`initFirebase`, `GerenciadorNotificacaoDownload.inicializar` e `MigracaoBackgroundOrchestrator.cancelarMigracaoSegundoPlano`) são operações 100% locais e *offline-first* (sem uso de rede). Cortar sua espera com timeouts curtos (2s a 4s) cria condições de corrida quando o dispositivo está sob carga de I/O, fazendo o `runApp` iniciar antes do registro do app `[DEFAULT]` do Firebase e causando falsos erros `[core/no-app]`.
**Migration**: Aguardar deterministicamente a conclusão das inicializações locais no pré-boot, paralelizar as sub-etapas de `initFirebase` com `Future.wait` e confiar nos timeouts dedicados da camada HTTP (`ClienteHttpAresta` e `ServicoCroquiOnline`) para gerenciar requisições remotas.

### Requirement: Garantia de Saída da Splash Reativa com Timeout e Fallback Seguro
**Reason**: O timeout arbitrário de 8s sobre `resolverDestinoInicialColdStart` abortava a resolução prematuramente antes que os timeouts dedicados da camada HTTP (`ClienteHttpAresta` e `ServicoCroquiOnline`) concluíssem o diagnóstico, descartando `itemSemConexaoInicial` e forçando um fallback silencioso para a Home em vez de apresentar `ModalCroquiSemConexao`.
**Migration**: Substituído pelo requisito `Garantia de Saída da Splash Reativa com Tratamento de Erros e Diagnóstico Contextual`, que confia nos timeouts reais da camada HTTP e preserva o `itemSemConexaoInicial`.
