## ADDED Requirements

### Requirement: Carregamento Sob Demanda do Protobuf `.binarypb`
O sistema DEVE (MUST) permitir a recuperação e desserialização direta do arquivo `.binarypb` de um croqui via HTTP a partir do servidor remoto (`NetworkConstants.officialServerUrl`) quando o croqui não estiver salvo localmente em `/downloads`. O buffer obtido DEVE ser mantido em memória e opcionalmente em cache temporário volátil (`getTemporaryDirectory()`), permitindo renderização imediata da hierarquia de setores e vias.

#### Scenario: Acesso a croqui não baixado
- **WHEN** o usuário seleciona um pico disponível que não possui arquivos na pasta `/downloads`
- **THEN** o sistema requisita o `.binarypb` correspondente ao caminho relativo do resumo via HTTP
- **AND** desserializa o protobuf `Croqui` instantaneamente sem bloquear a UI com telas de download obrigatório.

#### Scenario: Fallback de falha de rede ao tentar carregar croqui online
- **WHEN** o usuário tenta abrir um croqui não baixado e o dispositivo está sem conectividade com a internet
- **THEN** o sistema exibe uma mensagem de erro amigável informando a ausência de conexão
- **AND** não insere o croqui no estado ativo de navegação.

### Requirement: Polling Periódico com ETag para Atualizações Online
Enquanto o usuário estiver ativamente navegando nas telas de um croqui em modo online (não baixado), o sistema DEVE (MUST) executar verificações periódicas leves (a cada 30 a 60 segundos) enviando o cabeçalho `If-None-Match: <etag>` para a URL do `.binarypb`. Caso o servidor retorne status `304 Not Modified`, nenhum dado de corpo deve ser trafegado. Caso o servidor retorne status `200 OK`, o sistema DEVE atualizar o buffer local e emitir uma notificação na interface sinalizando a existência de uma nova versão. O timer de polling DEVE ser cancelado assim que o usuário sair das telas do referido pico.

#### Scenario: Nenhuma modificação no servidor remoto (304)
- **WHEN** o timer de polling dispara enquanto o croqui online está aberto
- **AND** o arquivo no servidor remoto não sofreu alterações
- **THEN** a requisição HTTP retorna `304 Not Modified`
- **AND** a UI permanece inalterada sem re-renderizações ou consumo de banda.

#### Scenario: Atualização detectada no servidor remoto (200)
- **WHEN** o timer de polling dispara e uma nova versão do `.binarypb` foi publicada no servidor
- **THEN** a requisição HTTP retorna status `200 OK` com os novos bytes e novo ETag
- **AND** a interface exibe um aviso de atualização disponível com ação de recarregar a visualização.

### Requirement: Resolução Híbrida de Imagens e Mídias com Cache Volátil
O provedor de imagens do sistema DEVE (MUST) resolver requisições de mídias externas seguindo a ordem de precedência:
1. Arquivo permanente na pasta `/downloads/<cragId>/` (se baixado);
2. Arquivo em cache temporário volátil do sistema operacional (`getTemporaryDirectory()`);
3. Requisição de streaming à CDN via HTTP utilizando o parâmetro de query para cache-busting `?v=<checksumSha256>`.

As imagens carregadas online DEVEM ser armazenadas no cache temporário volátil de forma que o sistema operacional possa expurgá-las sob pressão de armazenamento sem afetar a pasta `/downloads` permanente.

#### Scenario: Imagem encontrada no diretório permanente
- **WHEN** uma imagem de setor ou mapa é solicitada para um croqui salvo offline
- **THEN** o provedor entrega o `FileImage` do diretório `/downloads` sem realizar requisições de rede.

#### Scenario: Imagem requisitada em modo online
- **WHEN** uma imagem é solicitada para um croqui em modo online e não existe no cache temporário
- **THEN** o sistema requisita a imagem via HTTP com o hash SHA-256 no query string
- **AND** armazena os bytes recebidos no diretório temporário antes de exibi-la.

### Requirement: Tamanho Pré-Computado de Download no Índice
O protobuf `Indice` e seus resumos (`ResumoCroqui` ou `PrecomputadosResumoCroqui`) DEVEM (MUST) conter o campo `tamanho_download_bytes` previamente computado pelo backend/pipeline de build somando o tamanho do `.binarypb` e de todos os `arquivosExternos`. A camada de visualização DEVE consumir diretamente este valor para exibir tamanhos formatados (ex: "18.4 MB") na interface sem disparar requisições HTTP adicionais (como `HEAD`).

#### Scenario: Exibição do tamanho do download
- **WHEN** a UI renderiza o card de um pico ou o botão de download
- **THEN** o sistema lê `tamanho_download_bytes` do resumo e formata em string legível (B, KB, MB) imediatamente.
