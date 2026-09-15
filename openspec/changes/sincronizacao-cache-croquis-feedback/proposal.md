## Why

Atualmente, a navegação de croquis em modo online recupera versões desatualizadas do arquivo `compilado.binarypb` devido à ausência de parâmetro de *cache-busting* (`?v=<sha256>`) na requisição HTTP, fazendo com que a CDN (Cloudflare) sirva binários congelados no cache de borda. Em contrapartida, o download offline utiliza o hash no isolate, criando uma divergência onde a versão offline fica atualizada e a online permanece obsoleta. 

Além disso, o arquivo baixado offline é gravado com o nome legado `<picoId>.binarypb` em vez do canônico `compilado.binarypb`, e o relatório de feedback do usuário carece de informações criptográficas sobre a integridade dos binários e miniaturas em uso, bem como da capacidade de anexar os arquivos `.binarypb` para download e inspeção no Discord.

## What Changes

- **Cache-Busting Mandatório na Navegação Online**: Garantir que toda requisição de `compilado.binarypb` para sessões online inclua explicitamente a query string `?v=<sha256>` baseada no `checksumSha256Croqui` do índice, assumindo como premissa mandatória a existência do checksum.
- **Endereçamento por Conteúdo no Cache Volátil (`temp_cache`)**: Salvar binários temporários como `compilado.binarypb.<sha256>` no diretório temporário do pico, reutilizando-os sem custo de rede se o hash bater e expurgando versões antigas do mesmo arquivo com hashes divergentes.
- **Padronização do Armazenamento Permanente (`downloads`)**: Padronizar o nome do arquivo baixado offline como `compilado.binarypb` (em vez de `<picoId>.binarypb`), aplicando migração transparente sob demanda (*lazy migration* via renomeação atômica) e expurgando arquivos residuais legados durante o ciclo de sincronização atômica.
- **Hierarquia Estrita de Resolução de Croquis**: Formalizar a ordem de leitura em 4 etapas: (1) Memória RAM (`GerenciadorSessaoOnline`), (2) Armazenamento Permanente (`/downloads`), (3) Cache Volátil (`/temp_cache`), (4) Download Remoto com gravação no cache volátil.
- **Zero Custo de Hashing em Runtime Normal**: Preservar a bateria e CPU do dispositivo, eliminando cálculos redundantes de SHA-256 no fluxo normal de navegação e leitura local.
- **Diagnóstico Criptográfico no User Feedback**: Calcular e anexar aos metadados do feedback os hashes SHA-256 do `indice.binarypb`, do `compilado.binarypb` e da `thumbnail.webp` do pico visualizado, marcando o status como `INTEGRO`, `DIVERGENTE` ou `NAO_BAIXADO`.
- **Anexação de Binários para Download no Discord**: Anexar o `indice.binarypb` e o `compilado.binarypb` no formulário multipart de feedback e repassá-los através da Edge Function `app-feedback` do Supabase como anexos reais para download na mensagem do Discord.

## Capabilities

### New Capabilities
- `sincronizacao-cache-croquis`: Cobre a resolução hierárquica unificada de croquis (RAM ➔ Downloads ➔ Temp Cache ➔ Rede), padronização para `compilado.binarypb`, cache-busting mandatório por SHA-256 na CDN e expurgo automático de versões antigas no cache volátil.

### Modified Capabilities
- `discord-feedback-security`: Adiciona aos metadados de feedback a auditoria de hashes criptográficos (índice, croqui e miniatura) e o suporte a múltiplos anexos binários (`indice.binarypb` e `compilado.binarypb`) na Edge Function `app-feedback` para download no Discord.

## Impact

- **Frontend (`lib/services/`)**:
  - `dataset_repository.dart`: Construção de URLs com `?v=<sha256>` e integração da hierarquia de leitura de croquis.
  - `services/dataset/armazenamento/gerenciador_arquivos_locais.dart`: Suporte ao arquivo canônico `compilado.binarypb` com migração transparente de `<picoId>.binarypb`.
  - `services/http/servico_croqui_online.dart`: Persistência e leitura em `temp_cache` endereçado por hash (`compilado.binarypb.<sha256>`) com expurgo de versões antigas.
  - `services/http/sync_isolate.dart` e `sync_service.dart`: Gravação de `compilado.binarypb` e limpeza de sobras legadas `<picoId>.binarypb`.
  - `services/feedback/`: Coleta de hashes no momento do report e envio dos arquivos `.binarypb` no formulário multipart.
- **Backend Supabase (`supabase/functions/app-feedback/handler.ts`)**:
  - Recepção de múltiplos arquivos multipart (`indice_file`, `croqui_file`) além da screenshot e repasse para o webhook do Discord como anexos para download.
