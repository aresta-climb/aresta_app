## MODIFIED Requirements

### Requirement: Carregamento Sob Demanda do Protobuf `.binarypb`
O sistema DEVE (MUST) permitir a recuperação e desserialização direta do arquivo `.binarypb` de um croqui via HTTP a partir do servidor remoto (`NetworkConstants.officialServerUrl`) quando o croqui não estiver salvo localmente em `/downloads`. O buffer obtido DEVE ser mantido em memória e opcionalmente em cache temporário volátil (`getTemporaryDirectory()`), permitindo renderização imediata da hierarquia de setores e vias, e seus arquivos externos (`arquivosExternos`) DEVEM ser indexados imediatamente na tabela de dispersão de SHA-256 do `DatasetRepository`.

#### Scenario: Acesso a croqui não baixado
- **WHEN** o usuário seleciona um pico disponível que não possui arquivos na pasta `/downloads`
- **THEN** o sistema requisita o `.binarypb` correspondente ao caminho relativo do resumo via HTTP
- **AND** desserializa o protobuf `Croqui` instantaneamente sem bloquear a UI com telas de download obrigatório
- **AND** indexa imediatamente os hashes SHA-256 de todas as mídias externas no repositório.

#### Scenario: Fallback de falha de rede ao tentar carregar croqui online
- **WHEN** o usuário tenta abrir um croqui não baixado e o dispositivo está sem conectividade com a internet
- **THEN** o sistema exibe uma mensagem de erro amigável informando a ausência de conexão
- **AND** não insere o croqui no estado ativo de navegação.

### Requirement: Resolução Híbrida de Imagens e Mídias com Cache Volátil
O provedor de imagens do sistema DEVE (MUST) resolver requisições de mídias externas seguindo a ordem de precedência:
1. Arquivo permanente na pasta `/downloads/<cragId>/` (se baixado);
2. Arquivo em cache temporário volátil do sistema operacional (`getTemporaryDirectory()`);
3. Requisição de streaming à CDN via HTTP utilizando o parâmetro de query para cache-busting `?v=<checksumSha256>`.

As imagens carregadas online DEVEM ser transmitidas com o parâmetro `?v=<checksumSha256>` obtido do `DatasetRepository` para que qualquer alteração do croqui na sessão online force a invalidação imediata do cache de rede.

#### Scenario: Imagem encontrada no diretório permanente
- **WHEN** uma imagem de setor ou mapa é solicitada para um croqui salvo offline
- **THEN** o provedor entrega o `FileImage` do diretório `/downloads` sem realizar requisições de rede.

#### Scenario: Imagem requisitada em modo online
- **WHEN** uma imagem é solicitada para um croqui em modo online e não existe no cache temporário
- **THEN** o sistema requisita a imagem via HTTP com o hash SHA-256 no query string (`?v=<checksumSha256>`)
- **AND** caso uma nova versão com hash alterado seja recebida, o Flutter substitui a imagem na tela em tempo de execução.
