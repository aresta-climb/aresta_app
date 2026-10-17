# Spec Delta

## MODIFIED Requirements

### Requirement: Carregamento Sob Demanda do Protobuf `.binarypb`
O sistema DEVE (MUST) permitir a recuperação e desserialização direta do arquivo `.binarypb` de um croqui via HTTP a partir do servidor remoto (`NetworkConstants.officialServerUrl`) quando o croqui não estiver salvo localmente em `/downloads`. O buffer obtido DEVE ser mantido em memória e opcionalmente em cache temporário volátil (`getTemporaryDirectory()`), permitindo renderização imediata da hierarquia de setores e vias, e seus arquivos externos (`arquivosExternos`) DEVEM ser indexados imediatamente na tabela de dispersão de SHA-256 do `DatasetRepository`. O cliente de transporte HTTP e o serviço de croqui online compartilhados DEVEM permanecer operacionais e reutilizáveis através de múltiplas navegações consecutivas de abertura e fechamento de guias. Falhas ao carregar ou recarregar o croqui online decorrentes de ausência de conectividade, falha de DNS (`SocketException`), `ClientException` ou timeout DEVEM ser registradas exclusivamente como breadcrumbs (`logAviso`) via `AppLogger.instance.logFalhaSyncOuDownload` na camada de transporte (`ServicoCroquiOnline`), abstendo-se de abrir issues não-fatais (`logError`) ou crashes fatais (`logCrash`) no Firebase Crashlytics. Erros de integridade (HTTP 404/500, corrupção de protobuf ou croqui marcado como salvo offline que retorne nulo/vazio) DEVEM ser reportados ao Firebase Crashlytics com `StackTrace`.

#### Scenario: Acesso a croqui não baixado
- **WHEN** o usuário seleciona um pico disponível que não possui arquivos na pasta `/downloads`
- **THEN** o sistema requisita o `.binarypb` correspondente ao caminho relativo do resumo via HTTP
- **AND** desserializa o protobuf `Croqui` instantaneamente sem bloquear a UI com telas de download obrigatório
- **AND** indexa imediatamente os hashes SHA-256 de todas as mídias externas no repositório.

#### Scenario: Fallback de falha de rede ao tentar carregar croqui online
- **WHEN** o usuário tenta abrir um croqui não salvo offline (`isPicoDownloaded == false`) e o dispositivo está sem conectividade com a internet (`SocketException`, `ClientException` ou `TimeoutException`)
- **THEN** o `ServicoCroquiOnline` DEVE registrar a falha como aviso/breadcrumb no Firebase Crashlytics via `AppLogger.instance.logFalhaSyncOuDownload` passando a exceção original
- **AND** o orquestrador de navegação (`handlePicoSelection`) NÃO DEVE emitir `logCrash` ou `logError` com exceção sintética para o mesmo evento
- **AND** a interface DEVE exibir uma `SnackBar` contextual informando que o croqui ainda não está salvo offline e requer conexão com a internet, oferecendo a ação `"Tentar novamente"`
- **AND** não insere o croqui no estado ativo de navegação.

#### Scenario: Acionamento da ação Tentar novamente na SnackBar de falha offline
- **WHEN** a `SnackBar` de croqui não disponível offline é exibida após falha de conexão
- **AND** o usuário toca na ação `"Tentar novamente"`
- **THEN** o sistema DEVE reexecutar `handlePicoSelection` para o mesmo pico e origem.

#### Scenario: Falha de integridade ao abrir croqui marcado como salvo offline
- **WHEN** o usuário seleciona um croqui que consta como salvo offline (`isPicoDownloaded == true`) mas o repositório retorna nulo ou sem picos
- **THEN** o sistema DEVE registrar o erro de integridade no Firebase Crashlytics com `StackTrace`
- **AND** DEVE exibir mensagem na interface informando o erro ao abrir o guia salvo.

#### Scenario: Acesso consecutivo a múltiplos croquis online após navegação de retorno
- **WHEN** o usuário abre um primeiro croqui online, retorna para a tela inicial ou de exploração e subsequentemente seleciona outro croqui online
- **THEN** o sistema DEVE manter o cliente de transporte de rede operacional
- **AND** DEVE carregar e abrir com sucesso o segundo croqui online sem lançar exceções de conexão encerrada.
