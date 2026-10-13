# Spec Delta

## MODIFIED Requirements

### Requirement: Carregamento Sob Demanda do Protobuf `.binarypb`
O sistema DEVE (MUST) permitir a recuperação e desserialização direta do arquivo `.binarypb` de um croqui via HTTP a partir do servidor remoto (`NetworkConstants.officialServerUrl`) quando o croqui não estiver salvo localmente em `/downloads`. O buffer obtido DEVE ser mantido em memória e opcionalmente em cache temporário volátil (`getTemporaryDirectory()`), permitindo renderização imediata da hierarquia de setores e vias, e seus arquivos externos (`arquivosExternos`) DEVEM ser indexados imediatamente na tabela de dispersão de SHA-256 do `DatasetRepository`. O cliente de transporte HTTP e o serviço de croqui online compartilhados DEVEM permanecer operacionais e reutilizáveis através de múltiplas navegações consecutivas de abertura e fechamento de guias. Qualquer falha que impeça o carregamento do croqui DEVE ser registrada no Firebase Crashlytics com diagnóstico detalhado via `AppLogger`.

#### Scenario: Acesso a croqui não baixado
- **WHEN** o usuário seleciona um pico disponível que não possui arquivos na pasta `/downloads`
- **THEN** o sistema requisita o `.binarypb` correspondente ao caminho relativo do resumo via HTTP
- **AND** desserializa o protobuf `Croqui` instantaneamente sem bloquear a UI com telas de download obrigatório
- **AND** indexa imediatamente os hashes SHA-256 de todas as mídias externas no repositório.

#### Scenario: Fallback de falha de rede ao tentar carregar croqui online
- **WHEN** o usuário tenta abrir um croqui não baixado e o dispositivo está sem conectividade com a internet ou o carregamento falha
- **THEN** o sistema DEVE registrar o diagnóstico da falha no Firebase Crashlytics via `AppLogger.instance.logFalhaSyncOuDownload`
- **AND** DEVE exibir uma mensagem de erro amigável na interface informando o ocorrido
- **AND** não insere o croqui no estado ativo de navegação.

#### Scenario: Acesso consecutivo a múltiplos croquis online após navegação de retorno
- **WHEN** o usuário abre um primeiro croqui online, retorna para a tela inicial ou de exploração e subsequentemente seleciona outro croqui online
- **THEN** o sistema DEVE manter o cliente de transporte de rede operacional
- **AND** DEVE carregar e abrir com sucesso o segundo croqui online sem lançar exceções de conexão encerrada.
