## ADDED Requirements

### Requirement: Garantia de Saída da Splash Reativa com Timeout e Fallback Seguro
O sistema DEVE (MUST) impor um limite de tempo (*timeout*) e tratamento de exceções na resolução do destino inicial de *Cold Start*, garantindo que a tela de splash reativa seja sempre encerrada com transição para a tela inicial (`HomeNode`) caso ocorra erro inesperado ou lentidão excessiva de rede, sem interferir no bloqueio obrigatório da tela de migração estrutural de dados (`needsMigration == true`) nem dos Termos de Uso.

#### Scenario: Expiração de tempo limite ou falha ao resolver link inicial no Cold Start
- **WHEN** a resolução do destino inicial no *Cold Start* exceder o tempo limite configurado ou lançar uma exceção não tratada
- **THEN** o aplicativo registra o aviso no logger, encerra a exibição da splash screen reativa (`_aguardandoColdStart = false`) e abre a navegação principal posicionada na tela inicial (`HomeNode`)

#### Scenario: Invariância do bloqueio da tela de migração de versão de dados
- **WHEN** o aplicativo iniciar com `needsMigration == true` (atualização estrutural de `kDataVersion` pendente) e os termos legais já estiverem aceitos
- **THEN** a garantia de saída da splash screen NÃO libera o acesso à `HomeNode`, mantendo a `DatabaseMigrationScreen` bloqueante em tela até que a migração estrutural seja concluída com sucesso

### Requirement: Timeouts Defensivos nas Inicializações Assíncronas de Pré-Boot
O sistema DEVE (MUST) aplicar limites de tempo (*timeouts*) defensivos às inicializações de serviços nativos e de segundo plano executadas antes da montagem da árvore de widgets (`runApp`), degradando graciosamente sem bloquear a saída da splash nativa do sistema operacional caso algum canal nativo demore a responder.

#### Scenario: Lentidão ou bloqueio em canal nativo antes do runApp
- **WHEN** a inicialização de notificações locais, serviços Firebase ou o cancelamento preventivo de tarefas do `WorkManager` exceder o limite de tempo defensivo durante o pré-boot
- **THEN** o sistema registra o evento de lentidão/falha sem interromper o fluxo e prossegue imediatamente para o `runApp`
