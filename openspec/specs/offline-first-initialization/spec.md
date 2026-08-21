## Purpose

Garantir o funcionamento offline instantâneo do aplicativo desde o primeiro acesso.
## Requirements
### Requirement: Inicialização Local Instantânea
O sistema MUST (DEVE) inicializar o app usando o `indice.binarypb` cacheado localmente ou pré-embutido antes de iniciar qualquer requisição de rede.

#### Scenario: App aberto com rede lenta
- **WHEN** o usuário abre o aplicativo em uma conexão lenta
- **THEN** a tela inicial renderiza instantaneamente com os dados locais enquanto a sincronização de rede roda silenciosamente em background

### Requirement: Descompactação de Primeiro Acesso
O sistema MUST (DEVE) descompactar o índice e as thumbnails preloaded embutidos no diretório de documentos local no primeiro acesso.

#### Scenario: Instalação nova sem internet
- **WHEN** o usuário instala e abre o app pela primeira vez sem internet
- **THEN** o app copia os assets embutidos para o diretório de documentos e os carrega com sucesso

### Requirement: Checagem de Versão Não-Bloqueante
O sistema MUST (DEVE) renderizar a interface gráfica imediatamente na inicialização da aplicação, sem bloquear o primeiro frame por requisições de rede do Firebase Remote Config.

#### Scenario: Abertura do app em rede lenta ou instável
- **WHEN** o usuário abre o aplicativo com conexão de rede instável, captive portal ou ausente sem modo avião
- **THEN** a interface da aplicação (Home ou Termos de Uso) é renderizada imediatamente sem exibir uma tela preta/cinza bloqueante

#### Scenario: Atualização de versão em segundo plano
- **WHEN** uma nova versão mínima (hard block) ou recomendada (soft banner) for recebida pelo Firebase Remote Config em segundo plano
- **THEN** o widget AppVersionChecker atualiza o estado reativamente para apresentar o banner ou tela de bloqueio correspondente

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


