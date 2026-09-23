# Discord Feedback Security Specification

## Purpose
Define os padrões de segurança, integridade criptográfica e transporte de diagnósticos para submissão de feedback do usuário a partir do aplicativo para o backend e canal do Discord.

## Requirements

### Requirement: Geração e Envio do Token do App Check
O aplicativo móvel DEVE obter um token válido do Firebase App Check antes de despachar qualquer feedback e anexá-lo no cabeçalho HTTP `X-Firebase-AppCheck`.

#### Scenario: Anexo do token do App Check em compilações de release
- **QUANDO** o aplicativo processa o envio de um feedback pendente em modo de release
- **ENTÃO** o aplicativo solicita o token do App Check via Play Integrity (Android) ou App Attest (iOS) e o inclui no cabeçalho `X-Firebase-AppCheck` da requisição multipart POST para a rota `app-feedback`.

#### Scenario: Transmissão sem chaves estáticas de API
- **QUANDO** o serviço de rede de feedback executa a requisição HTTP POST
- **ENTÃO** a requisição NÃO DEVE incluir o cabeçalho `x-api-key` ou qualquer segredo estático injetado em tempo de compilação.

### Requirement: Resolução Dinâmica de Endpoint com Fallback Offline
O aplicativo DEVE resolver a URL da Edge Function `app-feedback` do Supabase e a URL base do servidor de dados (`serving_base_url`) através do Firebase Remote Config, mantendo constantes compiladas locais como fallback seguro.

#### Scenario: Remote Config disponível e atualizado
- **QUANDO** o aplicativo obtém as configurações remotas do Firebase
- **ENTÃO** o orquestrador de feedback DEVE utilizar a URL definida em `feedback_edge_function_url` e a camada de rede de dados DEVE utilizar a URL definida em `serving_base_url`.

#### Scenario: Remote Config inacessível ou em modo offline
- **QUANDO** o aplicativo estiver sem conexão de rede ou a busca do Remote Config ainda não tiver concluído
- **ENTÃO** o sistema DEVE utilizar os valores padrão seguros configurados em `RemoteConfigService`.

### Requirement: Execução Graciosa de Mock em Ambiente de Desenvolvimento
Em compilações de depuração (`kDebugMode`), caso a geração do token do App Check falhe ou não haja token de depuração cadastrado no Firebase Console, o sistema de feedback DEVE registrar o payload no console sem lançar exceções impeditivas para a interface.

#### Scenario: Ambiente de depuração não registrado no console
- **QUANDO** um desenvolvedor executa o aplicativo em modo de depuração sem um token de depuração cadastrado no Firebase Console e submete um feedback
- **ENTÃO** o aplicativo exibe a descrição e os metadados do feedback no console de depuração e conclui a tarefa local sem travar a interface do usuário.

#### Scenario: Ambiente de depuração com token cadastrado
- **QUANDO** um mantenedor executa o aplicativo em modo de depuração com o UUID devidamente registrado no Firebase Console
- **ENTÃO** o aplicativo obtém um token JWT válido de depuração do Firebase e envia o feedback para a Edge Function normalmente.

### Requirement: Validação Criptográfica de JWT do App Check no Servidor
A Edge Function `app-feedback` do Supabase DEVE validar criptograficamente o JWT recebido no cabeçalho `X-Firebase-AppCheck` contra as chaves públicas (JWKS) do Google/Firebase antes de autorizar o processamento do feedback.

#### Scenario: Token do App Check válido
- **QUANDO** a requisição chega à Edge Function `app-feedback` com um JWT válido e não expirado correspondente ao pacote oficial do aplicativo
- **ENTÃO** a Edge Function valida o token com sucesso e prossegue para a verificação de taxa de envio e despacho ao webhook.

#### Scenario: Token do App Check ausente ou adulterado
- **QUANDO** a requisição chega sem o cabeçalho `X-Firebase-AppCheck` ou com um token inválido/forjado
- **ENTÃO** a Edge Function rejeita a requisição imediatamente com status `HTTP 403 Forbidden`.

### Requirement: Limitação de Taxa de Requisições por Endereço IP no Servidor
A Edge Function `app-feedback` do Supabase DEVE aplicar um limite de no máximo 5 requisições de feedback por minuto para cada endereço IP de origem.

#### Scenario: Requisições dentro do limite permitido
- **QUANDO** um endereço IP realiza 5 ou menos requisições dentro de uma janela de 60 segundos
- **ENTÃO** a Edge Function processa cada uma das requisições normalmente.

#### Scenario: Requisições excedendo o limite de taxa
- **QUANDO** um endereço IP tenta realizar a 6ª requisição dentro da mesma janela de 60 segundos
- **ENTÃO** a Edge Function rejeita a requisição com `HTTP 429 Too Many Requests` e inclui o cabeçalho `Retry-After`.

### Requirement: Resiliência e Retentativa no Webhook de Destino
A Edge Function `app-feedback` do Supabase DEVE tratar respostas de limitação de taxa do webhook do Discord e realizar retentativas automáticas antes de propagar falhas.

#### Scenario: Resposta HTTP 429 do webhook do Discord
- **QUANDO** o servidor do Discord responder com `HTTP 429` e informar um tempo de espera no cabeçalho `Retry-After`
- **ENTÃO** a Edge Function aguarda o período indicado (limitado a 3 segundos) e repete a chamada ao webhook uma única vez.

#### Scenario: Propagação de falha do webhook do Discord para a fila local
- **QUANDO** o webhook do Discord permanecer indisponível ou rejeitar a mensagem após retentativa
- **ENTÃO** a Edge Function responde com `HTTP 503 Service Unavailable`, permitindo que a fila persistente local do aplicativo execute retentativas posteriores com backoff exponencial.

### Requirement: Auditoria Criptográfica de Integridade nos Metadados de Feedback
Ao coletar os metadados de contexto para envio de feedback, o sistema DEVE (MUST) calcular e incluir os hashes SHA-256 do arquivo `indice.binarypb` local, do `compilado.binarypb` e da `thumbnail.webp` referentes ao croqui ativo no momento da submissão. Os metadados DEVEM indicar se cada item está `INTEGRO`, `DIVERGENTE` ou `NAO_BAIXADO` quando comparados com os valores oficiais do índice mestre.

#### Scenario: Coleta de hashes com croqui ativo íntegro
- **WHEN** o usuário aciona o envio de feedback enquanto visualiza um croqui com arquivos consistentes
- **THEN** o JSON de metadados inclui os campos `indice_sha256`, `croqui_sha256_esperado`, `croqui_sha256_real`, `croqui_status: "INTEGRO"`, `thumbnail_sha256_esperado`, `thumbnail_sha256_real` e `thumbnail_status: "INTEGRO"`.

#### Scenario: Coleta de hashes com thumbnail divergente
- **WHEN** a miniatura presente no armazenamento local do dispositivo difere do hash apontado pelo índice mestre
- **THEN** o campo `thumbnail_status` é preenchido como `"DIVERGENTE"` nos metadados enviados.

### Requirement: Anexação e Repasse de Binários de Diagnóstico para Download no Discord
O aplicativo DEVE (MUST) anexar ao formulário multipart do feedback os arquivos binários locais `indice.binarypb` e o `compilado.binarypb` do pico em visualização (quando disponível). A Edge Function `app-feedback` do Supabase DEVE aceitar esses arquivos multipart adicionais e repassá-los na carga do webhook do Discord como anexos autônomos para permitir download direto pelos desenvolvedores.

#### Scenario: Anexo e transmissão dos binários pelo aplicativo
- **WHEN** o formulário de feedback é despachado pelo aplicativo com um croqui aberto
- **THEN** a requisição multipart inclui os campos de arquivo `indice_file` (contendo o `indice.binarypb`) e `croqui_file` (contendo o `compilado.binarypb`).

#### Scenario: Disponibilização dos binários no canal do Discord
- **WHEN** a Edge Function `app-feedback` processa a requisição contendo os binários adicionais
- **THEN** anexa esses arquivos ao `discordFormData`
- **AND** a mensagem final no Discord exibe os arquivos disponíveis para download imediato na thread de feedback.
