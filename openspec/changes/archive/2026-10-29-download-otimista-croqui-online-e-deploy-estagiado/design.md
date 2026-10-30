# Design

## Context

Conforme descrito em `proposal.md`, a abertura de um croqui não salvo offline (`DatasetRepository.getCroqui`, etapa 4) atualmente executa um `await syncAtivo.syncIndex()` bloqueante antes de requisitar o `compilado.binarypb`. Em conexões móveis degradadas (3G/Edge em regiões de escalada), isso impõe dois *round-trips* HTTP sequenciais no caminho crítico.

Além disso:
1. O cache da Cloudflare CDN (mesmo com *Smart Tiered Cache* ativo e `Cache-Control` de 1 ano) está sujeito a *LRU eviction* (despejo por inatividade em ~24h–72h para arquivos frios), enquanto o bucket Cloudflare R2 armazena apenas a versão mais recente de cada arquivo sob o caminho fixo `v1/<picoId>/compilado.binarypb` (ignorando a query string `?v=<hash>`). Assim, quando uma requisição com `?v=<hash_antigo>` sofre *MISS* na CDN, o R2 retorna o binário da versão mais recente (`<hash_novo>`).
2. No `SyncService.syncIndex()`, a Fase 1 chama `datasetRepository.loadIndiceToMemory(newIndice)` antes de a Fase 2 (`_executarAtualizacaoMidiasEmSegundoPlano`) baixar os arquivos atualizados dos croquis salvos offline. Como `loadIndiceToMemory` atualmente descarta a instância `existente.croqui` em memória quando `existente.checksum != picoItem.checksum`, um croqui baixado offline que esteja aberto na tela perde sua referência em memória durante a Fase 1, piscando um indicador de carregamento antes de a Fase 2 concluir o download e o *hot-reload*.
3. No repositório `../aresta_db`, o script `serving/update_serving.py` envia `indice.binarypb`, `compilado.binarypb` e imagens simultaneamente no mesmo `ThreadPoolExecutor`. Como `indice.binarypb` (~9 KB) e `compilado.binarypb` (~40 KB) terminam o upload antes de imagens maiores (~1–2 MB), clientes que requisitarem as novas URLs `?v=<hash_novo>` durante essa janela de segundos podem sofrer *cache poisoning* na CDN com a imagem antiga ainda presente no R2.

## Goals / Non-Goals

**Goals:**
- Reduzir para **1 RTT** o caminho crítico de abertura de croquis online (`DatasetRepository.getCroqui`) quando o `caminhoRelativo` já consta no índice local, disparando `syncIndex()` silenciosamente em segundo plano (`unawaited`).
- Calcular em memória RAM o SHA-256 real (`sha256.convert(response.bodyBytes)`) na chegada do HTTP em `ServicoCroquiOnline.carregarCroquiRemoto` (~0,3 ms para ~40 KB), gravando atomicamente (`.tmp` ➔ rename) como `compilado.binarypb.<sha256_real>` e documentando explicitamente no código o motivo arquitetural (*LRU eviction* na CDN + sobrescrita no R2).
- Garantir fallback de emergência em `ServicoCroquiOnline.carregarCroquiRemoto`: se a requisição de rede falhar (offline/timeout) e existir qualquer `compilado.binarypb.*` prévio em `temp_cache/<picoId>/`, carregá-lo para não deixar o escalador na mão.
- Garantir *hot-reload* contínuo e sem piscada para croquis salvos offline abertos na tela, preservando `existente.croqui` em `loadIndiceToMemory` durante a Fase 1 até que a Fase 2 conclua o commit atômico e invoque `_updatePicoMetadata`.
- Estruturar o upload em `../aresta_db/serving/update_serving.py` em 3 estágios sequenciais (mídias ➔ `compilado.binarypb` ➔ manifestos + purge).

**Non-Goals:**
- Calcular SHA-256 em memória na thread de UI para imagens (`ProvedorImagemAresta`), visto que imagens de 1–2 MB custariam 6–12 ms por arquivo na UI thread e o `SyncIsolate` já valida o SHA-256 em *Background Isolate* ao promover arquivos do `temp_cache` para `/downloads`.
- Disparar `syncIndex()` adicional ao abrir croquis que já estão em `/downloads` (Etapa 2) ou `/temp_cache` (Etapa 3), pois o aplicativo já executa `syncIndex()` na inicialização.
- Armazenar múltiplas versões históricas de imagens ou `.binarypb` com hash no nome da chave dentro do bucket R2.

## Decisions

### 1. Download Otimista em 1 RTT + `syncIndex` Silencioso em Background (`DatasetRepository.getCroqui`)
- **Decisão**:
  Na etapa 4 de `DatasetRepository.getCroqui(id, {bool indiceJaSincronizado = false})`:
  1. Se `caminhoRelativo` for nulo ou vazio no índice local em memória (ex: um pico recém-criado que ainda não existia no índice local do dispositivo), mantém-se o fallback `await syncAtivo.syncIndex()` para descobrir o `caminhoRelativo` antes de baixar o croqui.
  2. Se `caminhoRelativo` já existir no índice local (99,9% dos casos), o sistema **não** aguarda `syncIndex()`: monta imediatamente `$baseUrl/$caminhoRelativo?v=$checksum` e chama `await servicoCroquiOnline.carregarCroquiRemoto(...)`.
  3. Assim que a chamada remota é disparada/concluída na etapa 4 (quando `!indiceJaSincronizado`), dispara `unawaited(syncAtivo.syncIndex())` em segundo plano.
  4. Caso o `syncIndex()` em segundo plano detecte um novo `indice.binarypb` com `novoChecksum != sha256Real`, a rotina já existente `_atualizarCroquiSessaoOnlineAtivaSeNecessario` baixa o novo `.binarypb` em segundo plano, atualiza a sessão online e reconstrói a página reativamente (*hot-reload*). Caso o R2 já tenha entregado os bytes novos no *MISS* da CDN (`sha256Real == novoChecksum`), `_atualizarCroquiSessaoOnlineAtivaSeNecessario` identifica que o hash em memória já coincide com o novo índice e evita um segundo download redundante.
- **Alternativas consideradas**:
  - *Manter `await syncIndex()` antes de todo download de croqui*: Rejeitada por dobrar o tempo de abertura em conexões móveis ruins (2 RTTs em série).

### 2. Cálculo de SHA-256 em Memória na Chegada do HTTP, Escrita Atômica `.tmp` e Fallback Offline (`ServicoCroquiOnline`)
- **Decisão**:
  Em `ServicoCroquiOnline.carregarCroquiRemoto`:
  1. Ao receber `response.statusCode == 200`, calcula `final hashReal = sha256.convert(bytes).toString()` diretamente sobre `response.bodyBytes` em memória RAM (sem releitura de disco).
  2. Persiste em `temp_cache/<picoId>/` escrevendo primeiro em `compilado.binarypb.$hashReal.tmp` (`flush: true`), renomeando atomicamente para `compilado.binarypb.$hashReal`, e **somente após o rename** executando `_expurgarVersoesAntigas` para deletar outros `compilado.binarypb.*` naquele diretório.
  3. Registra o croqui em `_sessaoOnline.registrarCroquiOnline(picoId, croqui, etag: etag, checksumSha256: hashReal)`.
  4. Inclui comentário explicativo detalhado no código documentando o efeito combinado de *LRU eviction* na Cloudflare CDN (mesmo com TTL de 1 ano e *Smart Tiered Cache*) e sobrescrita de objetos no R2 (onde `?v=hash_antigo` em *cache miss* retorna o binário novo do R2).
  5. Se a requisição HTTP falhar (exceção de rede/timeout ou status != 200), chama um método auxiliar `_carregarQualquerVersaoDoCacheVolatil(picoId)` que procura qualquer arquivo `compilado.binarypb*` (ignorando `.tmp`) dentro de `temp_cache/<picoId>/`, desserializa-o, extrai seu hash do sufixo do nome (ou calcula em memória) e o registra na sessão online como fallback de emergência.

```
Fluxo em ServicoCroquiOnline.carregarCroquiRemoto
═══════════════════════════════════════════════════════════════════════════════
1. Verifica temp_cache/<picoId>/compilado.binarypb.<hashEsperado>
   └── Se existir e for válido ──► Retorna em 0ms!
2. Requisita HTTP GET <url>?v=<hashEsperado>
   ├── Sucesso (200 OK):
   │     ├─► Calcula hashReal = sha256.convert(response.bodyBytes) na RAM
   │     ├─► Grava compilado.binarypb.<hashReal>.tmp ──► rename atômico
   │     ├─► Expurga versões antigas compilado.binarypb.* da pasta do pico
   │     └─► Registra sessão online com checksumSha256: hashReal e retorna!
   └── Falha de Rede / Offline:
         └─► Procura qualquer compilado.binarypb.* anterior na pasta do pico
               ├── Achou? Desserializa, registra na sessão online e retorna! 🛟
               └── Não achou? Retorna null (fluxo padrão de aviso offline).
```

### 3. Hot-Reload sem Piscada para Croquis Baixados Offline (`DatasetRepository.loadIndiceToMemory`)
- **Decisão**:
  Em `DatasetRepository.loadIndiceToMemory`:
  Ao construir `ordenadosCarregados` a partir de `mapaBaixadosAtuais`, reaproveitar `existente.croqui` sempre que `existente != null && existente.croqui != null` (mesmo que `existente.checksum != picoItem.checksum` naquele instante da Fase 1 do `syncIndex`), mantendo a instância anterior visível na UI enquanto a Fase 2 (`_checkForUpdates`) baixa a nova versão em segundo plano no `DownloadIsolate`. Assim que a Fase 2 conclui o rename atômico em `/downloads` e chama `_updatePicoMetadata(id, newPicoData)`, o `activeDataset.value` é atualizado com o novo `Croqui` e o `PageListenableBuilder` reconstrói a página aberta instantaneamente (*hot-reload*).
- **Alternativas consideradas**:
  - *Zerar `croqui` para `null` na Fase 1 quando o checksum mudar*: Causa um estado intermediário em que `estaMarcadoBaixado == true` e `croqui == null` no `PageListenableBuilder`, exibindo `CircularProgressIndicator` e disparando releitura do arquivo antigo em disco antes de a Fase 2 terminar.

### 4. Upload Estagiado em 3 Fases no Deploy (`../aresta_db/serving/update_serving.py`)
- **Decisão**:
  No `Deployer.execute()` de `serving/update_serving.py` (tanto no *Full Deploy* quanto no *Delta Deploy*), substituir a chamada única de `_upload_files_parallel` por um método `_upload_files_staged(files)` que particiona a lista de arquivos em três estágios sequenciais (cada um enviado em paralelo via `_upload_files_parallel`):
  1. **Estágio 1 (Mídias e Imagens)**: Todos os arquivos que não são `compilado.binarypb` nem manifestos raiz (`indice.binarypb`, `indice.yaml`, `catalogo.db`, `arquivos_serving.yaml`).
  2. **Estágio 2 (Croquis Compilados)**: Todos os arquivos cujo caminho termina com `compilado.binarypb`.
  3. **Estágio 3 (Manifestos Globais)**: `indice.binarypb`, `indice.yaml`, `catalogo.db` e `arquivos_serving.yaml`, seguidos imediatamente por `self.purger.purge_manifests(self.db_version)`.

## Risks / Trade-offs

- **[Risco] Na abertura online (1 RTT), o usuário ver por 1–2 segundos a versão cacheada na CDN antes do *hot-reload* em background** → **Mitigação**: Quando o `syncIndex()` silencioso em background termina segundos depois, `_atualizarCroquiSessaoOnlineAtivaSeNecessario` atualiza a tela reativamente e exibe o aviso amigável *"O guia de `<Pico>` foi atualizado!"*, sem bloquear quem está com conexão ruim na rocha.
- **[Risco] Arquivo `.tmp` órfão em `temp_cache` se o app fechar durante a escrita** → **Mitigação**: A escrita usa `.tmp` seguido de `rename`, e tanto o expurgo quanto o fallback de emergência ignoram arquivos terminados em `.tmp`.
