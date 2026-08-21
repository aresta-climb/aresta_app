## ADDED Requirements

### Requirement: Checagem de Versão Não-Bloqueante
O sistema MUST (DEVE) renderizar a interface gráfica imediatamente na inicialização da aplicação, sem bloquear o primeiro frame por requisições de rede do Firebase Remote Config.

#### Scenario: Abertura do app em rede lenta ou instável
- **WHEN** o usuário abre o aplicativo com conexão de rede instável, captive portal ou ausente sem modo avião
- **THEN** a interface da aplicação (Home ou Termos de Uso) é renderizada imediatamente sem exibir uma tela preta/cinza bloqueante

#### Scenario: Atualização de versão em segundo plano
- **WHEN** uma nova versão mínima (hard block) ou recomendada (soft banner) for recebida pelo Firebase Remote Config em segundo plano
- **THEN** o widget AppVersionChecker atualiza o estado reativamente para apresentar o banner ou tela de bloqueio correspondente
