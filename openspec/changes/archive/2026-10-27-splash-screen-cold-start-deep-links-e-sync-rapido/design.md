# Design

## Context

Conforme detalhado em `proposal.md`, a inicialização a frio (*Cold Start*) a partir de Deep Links (`https://aresta.cc/...`) apresenta uma janela em branco por vários segundos seguida de um "pulo" visual pela tela Home antes de abrir a entidade alvo.

Atualmente:
1. No Android 12+ (`values-v31/styles.xml`), a API nativa de `SplashScreen` suprime o `windowSplashScreenAnimatedIcon` quando a Activity é iniciada por uma intent `ACTION_VIEW` (Deep Link), exibindo apenas o fundo `#ffffff` sem a logo até o primeiro frame do Flutter.
2. O `main()` aguarda sequencialmente (`await`) todas as inicializações de plugins nativos e I/O de disco (`GerenciadorNotificacaoDownload`, `initFirebase`, `SharedPreferences`, `EditorDeCroqui`, `setupAppServices` e `DatasetRepository.init()`) antes de invocar `runApp()`.
3. O `GerenciadorDeepLinks.inicializar()` é disparado de forma assíncrona dentro do `TreeNavigationWrapperState.initState()`, após o primeiro frame já ter montado a `HomePage`.
4. O `SyncService.syncIndex()` bloqueia seu retorno até concluir o download de todas as thumbnails (`_syncThumbnails`) e a atualização de todos os croquis salvos offline (`_checkForUpdates`), enquanto `DatasetRepository.getCroqui(id)` na etapa 4 (rede remota) não garante que o `indice.binarypb` e o `catalogo.db` estejam atualizados antes de baixar o `compilado.binarypb`.

## Goals / Non-Goals

**Goals:**
- Garantir que a logo da splash screen seja exibida desde o instante zero em aberturas por Deep Link no Android 13+ (`windowSplashScreenBehavior="icon_preferred"`) e que o Flutter assuma em ~200–300ms com uma `TelaSplashInicial` idêntica (`#ffffff` + `assets/logo_splash.png`).
- Paralelizar o bootstrap de serviços e resolver qualquer Deep Link de *Cold Start* ainda durante a `TelaSplashInicial`, abrindo a navegação diretamente no nó de destino (`ViaNode`, `SetorNode`, `PicoNode`, `MapasCarrosselNode`) sem piscar a `HomePage`.
- Resolver instantaneamente (`0ms` de rede) links cujos croquis já estejam em `/downloads` (offline) ou em `/temp_cache` (cache volátil), mantendo o app 100% funcional offline na rocha.
- Fazer `syncService.syncIndex()` aguardar apenas o sync rápido de metadados (`indice.binarypb` + delta de `catalogo.db` com HTTP Keep-Alive) e retornar imediatamente, executando a atualização de thumbnails, croquis offline e eventual recarga do croqui aberto em sessão online (`picoAbertoId`) em segundo plano.
- Preservar integralmente o bloqueio de `DatabaseMigrationScreen` quando `needsMigration == true`.

**Non-Goals:**
- Alterar a cor de fundo atual da splash screen (`#ffffff`) ou substituir o asset `assets/logo_splash.png`.
- Criar etapas de *cache warming* na CDN durante o `deploy.yml` (visto que o cache da Cloudflare é isolado por PoP regional e sujeito a *LRU eviction*).

## Decisions

### 1. Splash Nativa no Android 13+ (`windowSplashScreenBehavior`) + `TelaSplashInicial` no Flutter
- **Decisão**:
  1. Adicionar `android:windowSplashScreenBehavior="icon_preferred"` em `android/app/src/main/res/values-v33/styles.xml` e `values-night-v33/styles.xml` (e na `MainActivity` no `AndroidManifest.xml`), instruindo o Android 13+ (API 33+) a exibir o ícone da splash mesmo em intents `ACTION_VIEW`.
  2. Criar o widget modular `TelaSplashInicial` (`lib/pages/tela_splash_inicial.dart`) que renderiza o mesmo fundo `#ffffff` e `assets/logo_splash.png` centralizada (exibindo um `CircularProgressIndicator` discreto quando estiver aguardando resolução de link/rede).
  3. Permitir que `MyApp` exiba `TelaSplashInicial` enquanto o bootstrap assíncrono (ou a resolução do deep link inicial de *Cold Start*) estiver em andamento, transicionando diretamente para `TermsOfUsePage`, `DatabaseMigrationScreen` ou `TreeNavigationWrapper` já posicionado no nó inicial.
- **Alternativas consideradas**:
  - *Usar apenas `FlutterNativeSplash.preserve()`*: No Android 12 (API 31/32), `FlutterNativeSplash.preserve()` mantém a janela nativa do sistema, que em intents `ACTION_VIEW` não exibe o ícone. Renderizar `TelaSplashInicial` no Flutter assim que a engine sobe (~250ms) garante que a logo apareça imediatamente mesmo no Android 12 e permite mostrar um indicador de progresso caso um croqui online esteja sendo baixado.

### 2. Resolução de Deep Link no *Cold Start* Antes da Montagem da `HomePage`
- **Decisão**:
  Durante a inicialização, `getInitialLink()` do `AppLinks` é consultado em paralelo com `datasetRepo.init()`. Se houver um `initialUri` (e não houver bloqueio de `needsMigration` ou `TermsOfUsePage`), o `DeepLinkNavigatorService.processarLink(initialUri, tipoStart: 'cold_start')` é aguardado enquanto a `TelaSplashInicial` permanece visível, populando o `TreeNavigationController` com o `NavNode` de destino antes de exibir o `TreeNavigationWrapper`.
  Se `needsMigration == true` ou se os termos ainda não tiverem sido aceitos, o link inicial é processado logo após a conclusão da migração/aceite dos termos.
  Para evitar reprocessamento duplicado quando o `GerenciadorDeepLinks` iniciar a escuta no `TreeNavigationWrapper`, o `GerenciadorDeepLinks` registra o `initialUri` já tratado em `_ultimoLinkProcessado` (ou recebe a flag/URI inicial já resolvida).

### 3. `syncService.syncIndex()` Rápido com Atualização de Mídias em Segundo Plano
- **Decisão**:
  Em vez de expor um novo método público, o próprio `syncService.syncIndex()` será estruturado em duas fases internas:
  1. **Fase 1 (Aguardada pelo `await syncIndex()`)**:
     - Reutiliza `_activeSyncFuture` se já houver uma sincronização de índice em andamento (coalescência).
     - Se uma sincronização automática bem-sucedida já tiver acabado de ocorrer nos últimos segundos (ex: durante o mesmo fluxo de abertura de link) e `forceBypassCache == false`, evita repetir a requisição HTTP desnecessariamente.
     - Requisita `GET /indice.binarypb` com `If-None-Match: <localEtag>` reusando a conexão Keep-Alive de `ClienteHttpAresta.instancia`.
     - Em caso de `304 Not Modified` (`IndiceUnchanged`), garante `await sincronizarCatalogoSeNecessario(...)` (< 1ms se a versão coincidir) e retorna imediatamente.
     - Em caso de `200 OK` (`IndiceUpdated`), atualiza `datasetRepository.indiceData.value = newIndice`, executa `await sincronizarCatalogoSeNecessario(newIndice, baseUrl)` (aplicando o delta JSON no `catalogo.db`), dispara a **Fase 2** em segundo plano e retorna imediatamente (expondo um `Future<List<String>>? tarefaMidiasEmSegundoPlano` no `SyncService` para aguardo opcional em testes ou no botão manual de "Verificar atualizações" quando desejado).
  2. **Fase 2 (Assíncrona em Segundo Plano)**:
     - Executa `_syncThumbnails(oldIndice, newIndice, baseUrl)` e `_checkForUpdates(oldIndice, newIndice)`.
     - Efetiva o commit atômico dos arquivos `.tmp` (`applyAtomicFileUpdates`), persiste o novo `indice.binarypb` e `.etag` no disco, e **somente então** atualiza os metadados e o `activeDataset` na UI (`loadIndiceToMemory`), evitando que cartões tentem ler thumbnails `.tmp` antes do renomeio.
     - **Recarga de Sessão Online Ativa**: Verifica se o `picoAbertoId.value` está em sessão online (`gerenciadorSessaoOnline`) e se seu `checksumSha256Croqui` mudou entre `oldIndice` e `newIndice` (ou em relação ao hash da sessão). Caso positivo, baixa o novo `.binarypb` em segundo plano via `servicoCroquiOnline.carregarCroquiRemoto`, atualiza a sessão online, chama `datasetRepository.notificarAtualizacaoSessaoOnline(picoId)` e `datasetRepository.notificarCroquiOnlineAtualizadoNaUI(nome)`, reconstruindo a tela via `PageListenableBuilder` e exibindo o SnackBar *"O guia de `<Nome>` foi atualizado!"*.

### 4. Resolução Local Imediata (`/downloads` e `/temp_cache`) vs. Sync Antes da Rede Remota
- **Decisão**:
  - Em `DatasetRepository.getCroqui(id)`:
    - As etapas **1 (RAM)**, **2 (`/downloads`)** e **3 (`/temp_cache` com o hash atual)** permanecem 100% locais e imediatas (`0ms` de rede).
    - Na **etapa 4 (Rede remota — CDN)**, antes de montar a URL `?v=<checksum>` e baixar o `compilado.binarypb`, `getCroqui(id)` chama `await SyncService.instance?.syncIndex()` (caso haja instância ativa e não esteja em modo offline/desabilitado) e relê o `caminhoRelativo` e `checksumSha256Croqui` atualizados de `indiceData.value`. Isso corrige tanto a abertura de links online quanto o clique manual em picos online na Home/Explorar (`handlePicoSelection`).
  - Em `LocalizadorDestinoUid.localizar(uid)`:
    - Tenta localizar o `uid` imediatamente nos croquis baixados (`/downloads`), nas sessões em memória e no `catalogo.db` local (`obterIdSlugPorUid(uid)`).
    - Se `idSlug == null` (ex: via ou croqui recém-lançado ainda ausente no `catalogo.db` local), aciona o fallback `await SyncService.instance?.syncIndex()` (que atualiza o `indice.binarypb` e aplica o delta no `catalogo.db` em ~150–300ms) e consulta `obterIdSlugPorUid(uid)` novamente antes de chamar `getCroqui(idSlug)`.
    - Se o croqui já estava em `/downloads` ou `/temp_cache` e abriu instantaneamente na 1ª tentativa durante o *Cold Start*, o bootstrap dispara `syncService.syncIndex()` em segundo plano após liberar a tela.

```
Fluxo Unificado de Resolução de Deep Link (Cold Start e Warm Start)
═══════════════════════════════════════════════════════════════════════════════
localizadorUid.localizar(uid)
 │
 ├─► 1. Procura em /downloads, RAM e catalogo.db local
 │      │
 │      ├── Achou idSlug E croqui está em /downloads ou /temp_cache?
 │      │     └─► Retorna Destino em ~0ms! (Abre tela na hora + syncIndex em bg)
 │      │
 │      ├── Achou idSlug MAS croqui NÃO está em /downloads nem /temp_cache?
 │      │     └─► getCroqui(idSlug) Etapa 4:
 │      │           ├─► await syncService.syncIndex() (rápido: ETag + delta catalogo.db)
 │      │           └─► Baixa compilado.binarypb?v=<hash_atual> (Keep-Alive) e abre!
 │      │
 │      └── NÃO achou idSlug no catalogo.db local (null)?
 │            └─► Fallback para via/croqui novo:
 │                  ├─► await syncService.syncIndex() (atualiza indice + delta catalogo.db)
 │                  ├─► Repete busca no catalogo.db atualizado
 │                  └─► getCroqui(idSlug) (reaproveita sync recém-feito) e abre!
```

## Risks / Trade-offs

- **[Risco] Dispositivo sem internet (offline na rocha) ao tentar abrir um croqui que NÃO está em `/downloads` nem em `/temp_cache`** → **Mitigação**: Se o croqui já estiver em `/downloads` ou `/temp_cache`, as etapas 1–3 resolvem antes de qualquer chamada de rede (`0ms`). Só quando o arquivo realmente não existe no aparelho (etapa 4 ou UID desconhecido) é que a rede é consultada, exibindo o aviso amigável de falta de conexão caso esteja offline.
- **[Risco] Dupla chamada ao `syncIndex()` quando o fallback de `LocalizadorDestinoUid` sincroniza o índice e em seguida `getCroqui(idSlug)` entra na etapa 4** → **Mitigação**: Coalescência via `_activeSyncFuture` somada a uma janela de *cooldown* curta (ex: 5 segundos) para chamadas automáticas quando `forceBypassCache == false`, fazendo com que a chamada subsequente em `getCroqui` retorne instantaneamente sem nova requisição HTTP.
- **[Risco] Quebra de testes existentes de `SyncService` que verificam efeitos colaterais de `_syncThumbnails` e `_checkForUpdates` logo após `await syncService.syncIndex()`** → **Mitigação**: Expor a `Future` da etapa em segundo plano (`tarefaMidiasEmSegundoPlano`) ou aguardar a conclusão quando invocado em fluxos explícitos de manutenção/teste, garantindo 100% de determinismo e cobertura nos testes.
