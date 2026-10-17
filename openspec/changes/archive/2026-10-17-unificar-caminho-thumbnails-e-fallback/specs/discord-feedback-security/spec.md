# Spec Delta

## MODIFIED Requirements

### Requirement: Auditoria Criptográfica de Integridade nos Metadados de Feedback
Ao coletar os metadados de contexto para envio de feedback, o sistema DEVE (MUST) calcular e incluir os hashes SHA-256 do arquivo `indice.binarypb` local, do `compilado.binarypb` e da miniatura local (`$downloadsRoot/thumbnails/<croquiId>.webp` ou cache volátil correspondente) referentes ao croqui ativo no momento da submissão. Os metadados DEVEM indicar se cada item está `INTEGRO`, `DIVERGENTE` ou `NAO_BAIXADO` quando comparados com os valores oficiais do índice mestre.

#### Scenario: Coleta de hashes com croqui ativo íntegro
- **WHEN** o usuário aciona o envio de feedback enquanto visualiza um croqui com arquivos consistentes em `$downloadsRoot`
- **THEN** o JSON de metadados inclui os campos `indice_sha256`, `croqui_sha256_esperado`, `croqui_sha256_real`, `croqui_status: "INTEGRO"`, `thumbnail_sha256_esperado`, `thumbnail_sha256_real` e `thumbnail_status: "INTEGRO"`.

#### Scenario: Coleta de hashes com thumbnail divergente
- **WHEN** a miniatura presente em `$downloadsRoot/thumbnails/<croquiId>.webp` difere do hash apontado pelo índice mestre
- **THEN** o campo `thumbnail_status` é preenchido como `"DIVERGENTE"` nos metadados enviados.
