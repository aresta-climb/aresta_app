# Discord Feedback Security Specification

## Purpose
Define os padrões de segurança, integridade criptográfica e transporte de diagnósticos para submissão de feedback do usuário a partir do aplicativo para o backend e criação de issues no repositório GitHub `aresta_db`.

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
A Edge Function `app-feedback` do Supabase DEVE (MUST) tratar respostas de limitação de taxa e indisponibilidade temporária da API do GitHub ao criar a issue no repositório `aresta_db`, realizando retentativas automáticas antes de propagar falhas para a fila do aplicativo.

#### Scenario: Resposta HTTP 429 do webhook do Discord
- **QUANDO** a API do GitHub responder com `HTTP 429` ou indicar limitação de taxa no cabeçalho `Retry-After`
- **ENTÃO** a Edge Function aguarda o período indicado (limitado a 3 segundos) e repete a chamada uma única vez.

#### Scenario: Propagação de falha do webhook do Discord para a fila local
- **QUANDO** a API do GitHub permanecer indisponível ou rejeitar a requisição após a retentativa
- **ENTÃO** a Edge Function responde com `HTTP 503 Service Unavailable`, permitindo que a fila persistente local do aplicativo execute retentativas posteriores com backoff exponencial.

### Requirement: Auditoria Criptográfica de Integridade nos Metadados de Feedback
Ao coletar os metadados de contexto para envio de feedback, o sistema DEVE (MUST) calcular e incluir os hashes SHA-256 do arquivo `indice.binarypb` local, do `compilado.binarypb` e da `thumbnail.webp` referentes ao croqui ativo no momento da submissão. Os metadados DEVEM indicar se cada item está `INTEGRO`, `DIVERGENTE` ou `NAO_BAIXADO` quando comparados com os valores oficiais do índice mestre.

#### Scenario: Coleta de hashes com croqui ativo íntegro
- **WHEN** o usuário aciona o envio de feedback enquanto visualiza um croqui com arquivos consistentes
- **THEN** o JSON de metadados inclui os campos `indice_sha256`, `croqui_sha256_esperado`, `croqui_sha256_real`, `croqui_status: "INTEGRO"`, `thumbnail_sha256_esperado`, `thumbnail_sha256_real` e `thumbnail_status: "INTEGRO"`.

#### Scenario: Coleta de hashes com thumbnail divergente
- **WHEN** a miniatura presente no armazenamento local do dispositivo difere do hash apontado pelo índice mestre
- **THEN** o campo `thumbnail_status` é preenchido como `"DIVERGENTE"` nos metadados enviados.

### Requirement: Anexação de Captura de Tela e Repasse de Binários de Diagnóstico para Download na Issue do GitHub
O aplicativo DEVE (MUST) anexar ao formulário multipart do feedback a captura de tela `screenshot` (PNG), os arquivos binários locais `indice.binarypb` e o `compilado.binarypb` do pico em visualização (quando disponível). A Edge Function `app-feedback` do Supabase DEVE (MUST) aceitar esses arquivos multipart adicionais, realizar o upload seguro para o bucket público `feedback_anexos` no Supabase Storage e disponibilizá-los diretamente como imagem embutida e links de download direto no corpo da issue do GitHub criada no repositório `aresta_db`.

#### Scenario: Anexo e transmissão da captura e dos binários pelo aplicativo
- **WHEN** o formulário de feedback é despachado pelo aplicativo com um croqui aberto
- **THEN** a requisição multipart inclui os campos de arquivo `screenshot` (contendo a captura anotada), `indice_file` (contendo o `indice.binarypb`) e `croqui_file` (contendo o `compilado.binarypb`).

#### Scenario: Disponibilização da imagem e dos binários na Issue do GitHub
- **WHEN** a Edge Function `app-feedback` processa a requisição contendo os arquivos adicionais
- **THEN** realiza o upload dos binários para o bucket `feedback_anexos` no Supabase Storage e anexa a imagem da captura de tela e os links de download direto no corpo da issue do GitHub criada no repositório `aresta_db`.

### Requirement: Segregação e Proteção de Dados Sensíveis com Link Restrito do Supabase Dashboard
A Edge Function `app-feedback` DEVE (MUST) persistir a totalidade dos metadados recebidos (incluindo identificadores de instância `app_instance_id`, modelo de dispositivo `device_model`, versão detalhada do SO, resolução de tela, IP de origem e conectividade) exclusivamente na tabela restrita `feedback_diagnosticos` do banco de dados PostgreSQL do Supabase, protegida por Row Level Security (RLS). A issue pública criada no GitHub DEVE (MUST) conter exclusivamente dados não sensíveis e exibir um link direto restrito para o Supabase Dashboard acessível apenas por membros autorizados da equipe que assinaram acordo de confidencialidade (NDA).

#### Scenario: Persistência isolada de dados sensíveis e geração de link restrito
- **WHEN** uma requisição válida de feedback é processada pela Edge Function `app-feedback`
- **THEN** os metadados completos de diagnóstico do aparelho são salvos na tabela privada `feedback_diagnosticos`
- **AND** a issue pública no GitHub não inclui identificadores do dispositivo nem IP
- **AND** o corpo da issue no GitHub inclui o link formatado: `https://supabase.com/dashboard/project/{project_ref}/editor/{table_id}?filter=id%3Deq%3D{feedback_id}`.

### Requirement: Etiquetagem Automática por Labels no Repositório aresta_db
Ao criar uma issue no repositório `aresta_db`, a Edge Function `app-feedback` DEVE (MUST) associar automaticamente labels de categorização conforme o tipo de relato, o sistema operacional e o pico ativo.

#### Scenario: Criação de issue para relato de croqui com pico ativo
- **WHEN** o feedback recebido possui categoria `tipoFeedback: "croqui"` e `croquiId: "br_mg_igarape_pedra_grande"` a partir de um aparelho Android
- **THEN** a issue no repositório `aresta_db` é criada com as labels `feedback:croqui`, `so:android` e `pico:br_mg_igarape_pedra_grande`.

#### Scenario: Criação de issue para relato do aplicativo em tela neutra
- **WHEN** o feedback recebido possui categoria `tipoFeedback: "app"` sem croqui ativo a partir de um aparelho iOS
- **THEN** a issue no repositório `aresta_db` é criada com as labels `feedback:app` e `so:ios`.
