## ADDED Requirements

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
