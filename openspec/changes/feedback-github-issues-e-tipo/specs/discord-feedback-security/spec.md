## MODIFIED Requirements

### Requirement: Resiliência e Retentativa no Webhook de Destino
A Edge Function `app-feedback` do Supabase DEVE (MUST) tratar respostas de limitação de taxa e indisponibilidade temporária da API do GitHub ao criar a issue no repositório `aresta_db`, realizando retentativas automáticas antes de propagar falhas para a fila do aplicativo.

#### Scenario: Resposta HTTP 429 do webhook do Discord
- **QUANDO** a API do GitHub responder com `HTTP 429` ou indicar limitação de taxa no cabeçalho `Retry-After`
- **ENTÃO** a Edge Function aguarda o período indicado (limitado a 3 segundos) e repete a chamada uma única vez.

#### Scenario: Propagação de falha do webhook do Discord para a fila local
- **QUANDO** a API do GitHub permanecer indisponível ou rejeitar a requisição após a retentativa
- **ENTÃO** a Edge Function responde com `HTTP 503 Service Unavailable`, permitindo que a fila persistente local do aplicativo execute retentativas posteriores com backoff exponencial.

### Requirement: Anexação e Repasse de Binários de Diagnóstico para Download no Discord
O aplicativo DEVE (MUST) anexar ao formulário multipart do feedback os arquivos binários locais `indice.binarypb` e o `compilado.binarypb` do pico em visualização (quando disponível). A Edge Function `app-feedback` do Supabase DEVE (MUST) aceitar esses arquivos multipart adicionais e disponibilizá-los para download direto na issue do GitHub criada no repositório `aresta_db`.

#### Scenario: Anexo e transmissão dos binários pelo aplicativo
- **WHEN** o formulário de feedback é despachado pelo aplicativo com um croqui aberto
- **THEN** a requisição multipart inclui os campos de arquivo `indice_file` (contendo o `indice.binarypb`) e `croqui_file` (contendo o `compilado.binarypb`).

#### Scenario: Disponibilização dos binários no canal do Discord
- **WHEN** a Edge Function `app-feedback` processa a requisição contendo os binários adicionais
- **THEN** realiza o upload dos binários para armazenamento acessível e anexa os links de download direto no corpo da issue do GitHub criada no repositório `aresta_db`.

## ADDED Requirements

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
