# Design Técnico: Estabilização do Relay e Live Reload

## Contexto

Consulte `proposal.md` para a motivação completa. A comunicação de prévia em tempo real entre o Editor Desktop e o aplicativo móvel utiliza o Cloudflare Workers com Durable Objects como retransmissor bidirecional. O aplicativo conecta-se à sessão via WebSocket (`/events`) e o editor via `/ws`. 

Requisições HTTP sob `/<codigo>/*` são encaminhadas via proxy reverso ao desktop e contam como requisições no Durable Object. A ausência de cabeçalho `ETag` nas respostas de proxy do desktop, somada à proliferação de timers periódicos de polling na interface do Flutter, causou uma tempestade de requisições que esgotou a cota do serviço.

## Metas e Não-Metas

**Metas:**
- Suportar `ETag` (SHA-256) e `HTTP 304 Not Modified` no retransmissor Python desktop (`aresta_db`).
- Tornar o polling HTTP de 30s dormente em `ServicoCroquiOnline` enquanto o WebSocket de Live Reload estiver conectado.
- Reutilizar a instância central de `ServicoCroquiOnline` do `DatasetRepository` e corrigir o gerenciamento de ciclo de vida em `PicoDetailsPage` e `PicoViewModel` para extinguir o vazamento de timers.
- Aplicar debounce e proteção contra reentrância nas sincronizações do `SyncService`.

**Não-Metas:**
- Não alterar a arquitetura ou o código do Cloudflare Worker / Durable Object (a infraestrutura é robusta e opera de acordo com a especificação original).
- Não desativar permanentemente o polling HTTP fora do modo experimental (ele continua ativo para croquis abertos via CDN oficial sem download local).

## Decisões Técnicas

### 1. Suporte a ETag e HTTP 304 no Túnel Retransmissor Desktop (`tunel_retransmissor.py`)
- **Abordagem:** No método `_ler_arquivo_proxy`, antes de serializar o corpo do arquivo em base64:
  1. Computar o hash SHA-256 do arquivo: `etag = f'"{hashlib.sha256(conteudo_bytes).hexdigest()}"'`.
  2. Verificar o cabeçalho recebido `cabecalhos.get("if-none-match")`.
  3. Se o ETag for compatível, responder imediatamente com `status: 304`, `cabecalhos: {"etag": etag, "access-control-allow-origin": "*"}` e `corpoBase64: ""`.
  4. Caso contrário, responder `status: 200` incluindo o cabeçalho `"etag": etag`.
- **Alternativa Rejeitada:** Usar apenas `Last-Modified` ou timestamp do sistema de arquivos. O SHA-256 é determinístico, evita discrepâncias de fuso horário e alinha-se perfeitamente aos checksums já calculados no compilador de croquis.

### 2. Dormência de Polling com WebSocket Conectado
- **Abordagem:** No método `iniciarPollingEtag` ou no tick periódico de `verificarAtualizacaoEtag` em `ServicoCroquiOnline`:
  - Verificar se `editorDeCroqui.isLiveReloadConectado` (ou `_wsLiveReload != null`) é verdadeiro.
  - Se estiver conectado, o tick de 30s é ignorado (ou o timer nem é agendado/fica em espera).
- **Alternativa Rejeitada:** Remover completamente o `ServicoCroquiOnline`. O serviço é necessário para o modo de exploração online de picos de produção (fora do modo experimental). A dormência condicional preserva a funcionalidade em produção e economiza cota no modo experimental.

### 3. Compartilhamento do `ServicoCroquiOnline` e Ciclo de Vida do `PicoViewModel`
- **Abordagem:**
  1. Em `construtor_view_arvore.dart`, injetar `servicoCroquiOnline: datasetRepo.servicoCroquiOnline` na construção do `PicoViewModel`.
  2. Em `ServicoCroquiOnline`, garantir que `iniciarPollingEtag(picoId, ...)` cancele qualquer timer anterior associado àquele `picoId` no mapa global `_timersPolling`.
  3. Em `_PicoDetailsPageState`, implementar `didUpdateWidget` para cancelar o polling do ViewModel antigo caso o `cragId` ou a instância do `viewModel` mude.
  4. Garantir que `PicoViewModel.dispose()` cancele o polling e remova os listeners do `activeDataset`.

### 4. Proteção contra Reentrância e Coalescência no `SyncService`
- **Abordagem:** Em `SyncService.syncIndex()`, introduzir controle de reentrância com `Completer` ou cancelamento/reaproveitamento da `Future` ativa (`_activeSyncFuture`). Se uma sincronização já estiver em andamento, chamadas subsequentes imediatas aguardam a mesma `Future` em vez de engatilhar múltiplas requisições HTTP paralelas.
- **Alternativa Rejeitada:** Apenas `Future.delayed` (debounce cego). O reaproveitamento da `Future` ativa (in-flight request coalescence) garante que nenhuma requisição duplicada atinja o servidor enquanto o primeiro sync está em trânsito.

## Riscos e Mitigações

- **[Risco]** A conexão WebSocket pode oscilar ou ser interrompida sem que o app perceba imediatamente.
  - *Mitigação:* `EditorDeCroqui` já possui rotina de reconexão automática com backoff (`_agendarReconexaoLiveReload`). Enquanto o socket estiver nulo ou reconectando, o polling de 30s volta a ser elegível como salvaguarda.
- **[Risco]** Cache ETag falso positivo em ambiente de desenvolvimento local.
  - *Mitigação:* Ao editar dados no desktop, o arquivo é regravado e o SHA-256 é alterado imediatamente, garantindo retorno 200 OK na primeira verificação subsequente.
