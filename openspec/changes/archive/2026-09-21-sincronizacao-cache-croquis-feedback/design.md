## Context

Atualmente, o carregamento sob demanda de croquis no modo online utiliza a URL sem query string, gerando respostas defasadas do cache de borda da CDN (Cloudflare). Ao mesmo tempo, o download offline utiliza `?v=<sha256>`, gravando o arquivo com o nome legado `<picoId>.binarypb` em `/downloads`, enquanto o `temp_cache` gravava como `<picoId>.binarypb`. Além disso, o sistema de feedback para o Discord não audita a integridade dos binários locais contra o índice nem anexa os arquivos `.binarypb` para depuração.

Para a motivação detalhada, consulte `proposal.md`.

## Goals / Non-Goals

**Goals:**
- Garantir que a navegação online sempre consuma a versão mais recente do `compilado.binarypb` através de cache-busting mandatório (`?v=<sha256>`).
- Endereçar arquivos voláteis em `temp_cache` por conteúdo (`compilado.binarypb.<sha256>`), reutilizando-os sem custo de rede e expurgando versões antigas com hashes divergentes.
- Padronizar o arquivo de download permanente em `/downloads/<picoId>/compilado.binarypb`, oferecendo migração transparente sob demanda e expurgo de arquivos legados durante o sync.
- Eliminar o custo de cálculo de hashes SHA-256 no fluxo normal de execução do app para poupar bateria e processamento.
- Auditar criptograficamente a integridade de índice, croqui e thumbnail no envio de feedback, anexando os binários no formulário multipart e repassando-os pela Edge Function do Supabase para download no Discord.

**Non-Goals:**
- Não calcular checksums SHA-256 durante a inicialização do app ou navegação comum em modo offline.
- Não alterar a estrutura dos arquivos Protobuf (`.proto`) nem quebrar o formato de dados serializados.
- Não modificar o fluxo de autenticação do Firebase App Check na Edge Function `app-feedback`.

## Decisions

### 1. Cache-Busting Mandatório com Premissa de Hash Inegociável
- **Decisão**: A URL do croqui é sempre construída incluindo `?v=${resumo.checksumSha256Croqui}`. Assumimos como premissa mandatória que todo registro no índice mestre possui checksum válido.
- **Alternativas consideradas**:
  - *Checar se o checksum existe antes de concatenar `?v=`*: Rejeitada, pois um checksum vazio no índice é um erro grave de compilação/publicação do catálogo e mascarar isso enfraquece a garantia de integridade.

### 2. Endereçamento por Conteúdo no `temp_cache` com Expurgo Automático
- **Decisão**: Ao baixar o binário em modo online, ele é persistido como `$tempCache/$picoId/compilado.binarypb.$sha256`. Antes de baixar, o app verifica se esse arquivo exato já existe. Ao salvar um novo arquivo, expurga versões irmãs que iniciem com `compilado.binarypb.` mas possuam hash divergente (mesmo padrão adotado com sucesso em `provedor_imagem_aresta.dart`).
- **Alternativas consideradas**:
  - *Salvar sem hash e manter controle em banco SQLite*: Rejeitada por introduzir dependências desnecessárias e complexidade de estado; o próprio sistema de arquivos funciona como tabela de dispersão O(1).

### 3. Padronização para `compilado.binarypb` e Migração Transparente (*Lazy Migration*)
- **Decisão**: O caminho canônico no armazenamento permanente passa a ser `<downloads>/<picoId>/compilado.binarypb`. Na leitura, se o arquivo canônico não existir mas `<picoId>.binarypb` existir, o sistema executa um `rename` instantâneo no mesmo diretório. Durante a sincronização atômica (`_checkForUpdates` e commit de pendências), o arquivo legado é explicitamente removido se ainda existir.
- **Alternativas consideradas**:
  - *Exigir que o usuário baixe novamente os croquis*: Rejeitada, pois causaria desperdício de dados móveis e frustração aos escaladores.
  - *Manter a nomenclatura legada `<picoId>.binarypb`*: Rejeitada por perpetuar divergência entre o nome do arquivo no servidor (`compilado.binarypb`), no cache e no disco local.

### 4. Hierarquia Estrita de Resolução de Croquis (4 Etapas)
- **Decisão**: A função de busca de croqui (`getCroqui`) orquestra quatro etapas sequenciais:
  1. **RAM (`GerenciadorSessaoOnline`)**: Retorno imediato em memória se o pico estiver aberto.
  2. **Disco Permanente (`/downloads/<picoId>/compilado.binarypb`)**: Leitura direta do armazenamento offline sem cálculo de hash.
  3. **Cache Volátil (`/temp_cache/<picoId>/compilado.binarypb.<sha256>`)**: Leitura direta do cache temporário se o arquivo com o hash atual existir.
  4. **Rede (CDN com `?v=<sha256>`)**: Download HTTP sob demanda, salvamento com sufixo do hash em `temp_cache`, expurgo de versões antigas e registro na RAM.
- **Alternativas consideradas**:
  - *Validar SHA-256 no carregamento de `/downloads`*: Rejeitada para economizar bateria; o sistema de sincronização e o isolate já garantem atomicidade e integridade prévia na gravação.

### 5. Auditoria de Integridade e Múltiplos Anexos no User Feedback
- **Decisão**: O cálculo de SHA-256 é restrito ao momento do feedback (evento esporádico). O `FeedbackMetadataCollector` calcula o hash real do `indice.binarypb`, do `compilado.binarypb` e da `thumbnail.webp` do pico ativo, comparando com o índice mestre (`INTEGRO` vs `DIVERGENTE`). O `FeedbackNetworkService` adiciona os binários como `indice_file` e `croqui_file` no multipart. A Edge Function `app-feedback` repassa esses arquivos ao Discord Webhook via FormData.
- **Alternativas consideradas**:
  - *Enviar apenas os hashes em texto sem os arquivos*: Rejeitada, pois ter o binário real do usuário disponível para download no Discord permite reproduzir bugs de parsing e anomalias de compilação imediatamente.

## Risks / Trade-offs

- **[Risco]** Arquivos temporários acumulados em `temp_cache` ocupando armazenamento.
  - **Mitigação**: O expurgo automático de versões irmãs deleta binários antigos a cada nova versão, e o diretório de cache volátil é sujeito à limpeza automática pelo próprio sistema operacional (Android/iOS) sob pressão de memória.
- **[Risco]** Falha de permissão no `rename` de migração transparente em `/downloads`.
  - **Mitigação**: O helper captura exceções e faz fallback de leitura para o arquivo legado caso a renomeação falhe, garantindo que o usuário nunca fique sem acesso ao croqui.
- **[Risco]** Limite de tamanho de upload no Discord Webhook (25 MB).
  - **Mitigação**: O `indice.binarypb` (~9 KB) e o `compilado.binarypb` (~40 KB) somam menos de 100 KB; juntamente com a captura de tela PNG (~1-2 MB), o payload total permanece muito abaixo do teto de 25 MB.

## Migration Plan

1. A migração dos arquivos em disco é 100% retrocompatível via lazy rename no primeiro acesso ou no próximo ciclo de sync.
2. A nova Edge Function no Supabase é retrocompatível: continua aceitando requisições de versões anteriores do app que enviam apenas a screenshot, e passa a anexar os arquivos adicionais apenas quando presentes no multipart.
