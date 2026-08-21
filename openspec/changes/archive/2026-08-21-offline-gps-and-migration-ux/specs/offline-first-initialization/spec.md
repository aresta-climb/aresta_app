## ADDED Requirements

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
