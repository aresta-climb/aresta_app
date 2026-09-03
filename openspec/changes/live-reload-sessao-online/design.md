## Context

O aplicativo Aresta Climb suporta dois modos de consumo de dados:
1. **Modo Offline Permanente**: Croquis completos são baixados para `<docs>/downloads/<picoId>/` (ou `<docs>/editor/experimental/downloads/<picoId>/`).
2. **Modo Online Sob Demanda (Sessão Online)**: O arquivo `.binarypb` é transmitido sob demanda para memória RAM (`GerenciadorSessaoOnline`) e mídias são resolvidas em streaming ou cache volátil (`/temp_cache/`).

O mecanismo de Hot Reload / Live Reload foi historicamente construído sob a premissa de arquivos salvos em disco: quando o Editor Desktop emite um evento via WebSocket, o `SyncService._checkForUpdates()` varre apenas a pasta de downloads física. Croquis abertos em sessão online são ignorados, deixando objetos `Croqui` obsoletos em memória e impedindo o `PageListenableBuilder` de atualizar a interface.

Simultaneamente, o serviço de polling periódico de ETag (`ServicoCroquiOnline.verificarAtualizacaoEtag`) recebe o corpo binário completo do croqui atualizado ao obter resposta HTTP `200 OK`, porém descarta os bytes e não atualiza o modelo em memória nem a interface.

Este design unifica a atualização reativa de sessões online tanto para eventos push de Live Reload quanto para verificações pull de ETag, respeitando integralmente os **Princípios de Engenharia do Aresta App** (`PRINCIPIOS.md`).

## Goals / Non-Goals

**Goals:**
- Permitir que eventos de Live Reload do Editor Desktop atualizem instantaneamente croquis abertos em sessão online (streaming), sem exigir que o usuário tenha feito o download prévio para o armazenamento permanente.
- Consumir diretamente os bytes recebidos em respostas HTTP `200 OK` durante o polling de ETag, eliminando o descarte de dados e atualizando o `GerenciadorSessaoOnline`.
- Re-indexar a tabela SHA-256 de arquivos externos no `DatasetRepository` para que o `ProvedorImagemAresta` invalide reativamente o cache de imagens (`?v=<novo_sha256>`).
- Manter a consistência de UX com os croquis baixados:
  - **Modo Experimental / Live Reload**: pulso luminoso no `BannerModoExperimental` e recarga silenciosa imediata da tela.
  - **Fora do Modo Experimental**: recarga da sessão e exibição de aviso/popup não intrusivo ("O guia de [Pico] foi atualizado!").
- Preservar TDD estrito com 100% de cobertura nos componentes alterados e nomenclatura estritamente em português brasileiro.

**Non-Goals:**
- Forçar o download permanente para disco de croquis em modo online durante o live reload.
- Alterar o comportamento de sincronização de croquis que já estejam baixados offline.
- Modificar o protocolo WebSocket existente entre o Editor Desktop e o aplicativo.

## Decisions

### Decisão 1: Re-fetch Reativo com Cache-Busting para Sessões Online no Live Reload
- **Abordagem**: Em `registrarOuvintesLiveReload` (em `main.dart`), após executar `syncService.syncIndex()` e `datasetRepo.init()`, o sistema itera sobre os picos ativos em `datasetRepo.gerenciadorSessaoOnline.croquisEmMemoria`. Para cada pico aberto, aciona um método de recarga em `ServicoCroquiOnline` passando a URL com parâmetro de quebra de cache `?t=${DateTime.now().millisecondsSinceEpoch}`.
- **Justificativa**: Garante que proxys intermediários (como Cloudflare Relay em `previa.arestaclimb.com`) não sirvam respostas HTTP cacheadas obsoletas.
- **Alternativas consideradas**:
  - *Auto-download compulsório para disco no modo experimental*: Rejeitada porque quebra o isolamento de sessões sob demanda e consome armazenamento local sem intenção do usuário.

### Decisão 2: Consumo Integral do Buffer no Polling de ETag (HTTP 200 OK)
- **Abordagem**: No método `verificarAtualizacaoEtag` de `ServicoCroquiOnline`, quando o servidor responder `200 OK`, o buffer `response.bodyBytes` é desserializado imediatamente via `Croqui.fromBuffer(bytes)`. A nova instância é registrada em `GerenciadorSessaoOnline`, gravada no cache volátil (`/temp_cache`) e suas mídias são reindexadas no repositório.
- **Justificativa**: Evita descartar um payload que já consumiu banda de rede e elimina a necessidade de um segundo `GET` subsequente.
- **Alternativas consideradas**:
  - *Manter o descarte e disparar um `carregarCroquiRemoto` separado*: Rejeitada por gerar tráfego de rede duplicado e atrasar a atualização visual.

### Decisão 3: Notificação Reativa Simétrica entre Modo Experimental e Modo Normal
- **Abordagem**:
  - Quando a atualização ocorrer em **Modo Experimental** (seja via WebSocket Live Reload ou ETag): o sistema aciona `editorDeCroqui.dispararPulsoRecarregamento()` e atualiza a tela de forma 100% silenciosa e imediata via `PageListenableBuilder`.
  - Quando a atualização ocorrer **Fora do Modo Experimental**: o sistema atualiza a sessão online e dispara um aviso amigável via SnackBar/popup na tela (ex: "O guia de [Pico] foi atualizado!"), em perfeita simetria com a notificação existente para picos baixados em `main.dart`.
- **Justificativa**: Garante previsibilidade e padrão de experiência em todo o ecossistema do app.

### Decisão 4: Re-indexação O(1) de Hashes SHA-256 e Invalidação de Texturas
- **Abordagem**: Sempre que um novo `Croqui` for registrado em `GerenciadorSessaoOnline`, o método `datasetRepo.indexarMidiasDoCroqui(picoId, novoCroqui)` é invocado imediatamente. Em seguida, uma emissão em `activeDataset` (ou notificador de sessão online) sinaliza ao `PageListenableBuilder` que deve reconstruir a árvore de widgets.
- **Justificativa**: O `ProvedorImagemAresta` depende do hash consultado em tempo constante para gerar `NetworkImage(url?v=<hash>)`. Se o hash mudar, a chave de cache muda e o Flutter decodifica a nova imagem imediatamente sem reter texturas velhas.

## Alinhamento com os Princípios de Engenharia (PRINCIPIOS.md)

- **I. Tudo em Português**: Nomes de métodos (`recarregarCroquiOnline`, `verificarAtualizacaoEtag`, `notificadorCroquiAtualizado`), classes, testes e comentários exclusivamente em português brasileiro.
- **II. Componentes Independentes (Feature-First)**: Fronteiras bem delimitadas entre o serviço HTTP (`ServicoCroquiOnline`), gerenciamento de estado (`GerenciadorSessaoOnline`), repositório (`DatasetRepository`) e apresentação (`PageListenableBuilder`).
- **III. 100% de Test Coverage**: Todo código novo ou alterado deve alcançar e manter 100% de cobertura com testes automatizados.
- **IV. Imperativo do Teste em Primeiro Lugar (TDD)**: Adoção rigorosa do ciclo Red-Green-Refactor: testes unitários e de widget são escritos e validados em falha antes de qualquer código de produção.
- **V. Testes de Widget em Primeiro Lugar**: Validação da reatividade da UI (`PageListenableBuilder`, `BannerModoExperimental`, `PicoDetailsPage`) com testes de widget cobrindo fluxos reais do usuário de ponta a ponta.
- **VI. Simplicidade e Anti-Abstração**: Extensão natural e direta das estruturas existentes sem camadas de indireção desnecessárias.
- **VII. Documentação Contínua e Abrangente**: Inclusão de docstrings `///` em português explicando a intenção de cada método e classe, além de atualização do guia `HOT_RELOAD.md` e dos arquivos `README.md`.

## Risks / Trade-offs

- **[Risco] Sobrecarga de rede caso múltiplos picos online estejam em memória** $\rightarrow$ **Mitigação**: O usuário normalmente visualiza apenas um pico por vez; o re-fetch é direcionado prioritariamente ao pico atualmente em exibição na árvore de navegação (`treeController.currentNode.cragId`).
- **[Risco] Condição de corrida entre WebSocket push e ETag polling simultâneos** $\rightarrow$ **Mitigação**: O `ServicoCroquiOnline` serializa a atualização do `GerenciadorSessaoOnline` de forma idempotente baseando-se no ETag / SHA-256 do croqui.
- **[Risco] Cache HTTP agressivo em conexões via Cloudflare Relay** $\rightarrow$ **Mitigação**: Uso de timestamp explícito `?t=` na URL em requisições de live reload forçado.
