# Documentação de Serviços — Aresta Climb

Este diretório contém a lógica de negócios e os serviços centrais do aplicativo. A arquitetura foi refatorada para usar um **interceptor HTTP customizado** (`ZipInterceptorClient`) em vez de lógica de extração manual, unificando o fluxo de dados tanto no modo oficial quanto no modo experimental.

---

## Arquivos

| Arquivo / Pasta | Responsabilidade |
|---|---|
| `dataset_repository.dart` | Gerenciador de estado central: downloads, índice, metadados e prioridade |
| `editor_croqui.dart` | Controle de contexto: modo ativo, caminhos de diretório, temporizador experimental |
| `http/` | Módulo de rede e sincronização (interceptor, downloads, atualizações OTA) |

| `firebase/` | Diretório isolado contendo toda integração com Firebase (Analytics, Crashlytics, Remote Config) |
| `feedback/` | Gerenciamento de envio de In-App Feedbacks via fila local (SharedPreferences) e despacho assíncrono em background (Workmanager) para o Supabase |

---

## Ghost Protocol — `aresta-zip://`

O ponto central da arquitetura atual é o **Ghost Protocol**: um esquema de URI customizado que permite ao app tratar arquivos ZIP locais como se fossem servidores HTTP remotos.

```
aresta-zip:///caminho/absoluto/para/arquivo.croqui/compilado/indice.binarypb
   ↑                                                 ↑
   Esquema interceptado pelo ZipInterceptorClient     Caminho interno do ZIP
```

**Como funciona:**
1. Qualquer serviço (DatasetRepository, SyncService) faz uma requisição HTTP normal.
2. O `ZipInterceptorClient` verifica o esquema da URL.
3. Se for `aresta-zip://`, lê o arquivo do disco, aplica de-ofuscação XOR se for `.croqui`, e retorna os bytes como uma resposta HTTP 200.
4. Se for `http://` ou `https://`, repassa ao cliente HTTP padrão sem modificação.

**Vantagem:** O mesmo código que busca dados do servidor remoto funciona identicamente para arquivos locais.

---

## Modo Experimental — Ciclo de Vida

O Modo Experimental permite testar arquivos `.croqui` localmente sem interferir na base de dados oficial.

### Acesso e Segurança

- **Easter Egg**: As opções de desenvolvedor ficam ocultas. O usuário precisa tocar **7 vezes seguidas** no ícone de status da página de Configurações para desbloqueá-las.
- **Temporizador de Auto-Destruição**: Uma vez ativado, o modo experimental tem vida útil de **20 minutos**. Um cronômetro regressivo é exibido no banner global e, ao chegar em zero, executa um "Nuke" completo dos dados de teste.
- **Nuke on Startup**: Todos os dados experimentais são apagados automaticamente quando o app é completamente fechado e reaberto.

### Isolamento de Dados

O `EditorDeCroqui` gerencia três contextos de armazenamento completamente isolados:

| Contexto | URL base | Diretório de índice | Diretório de downloads |
|---|---|---|---|
| **Oficial** | `https://aresta-climb.github.io/aresta_serving` | `<docs>/indice.binarypb` | `<docs>/downloads/` |
| **Editor (URL)** | URL fornecida pelo desenvolvedor | `<docs>/editor/<slug>/indice.binarypb` | `<docs>/editor/<slug>/downloads/` |
| **Experimental** | `aresta-zip:///caminho/arquivo.croqui` | `<docs>/editor/experimental/indice.binarypb` | `<docs>/editor/experimental/downloads/` |

### Fluxo de Importação via File Picker

1. O usuário seleciona um `.croqui` via "Importar Repositório".
2. O arquivo `.croqui` original é copiado para a pasta de trabalho (edited).
3. Uma URL base `aresta-zip://` é construída apontando para o arquivo copiado.
4. O `ZipInterceptorClient` valida ativamente o `.croqui` tentando ler o `indice.binarypb` de dentro dele.
5. O `EditorDeCroqui` salva essa URL como `activeBaseUrl` e entra no modo Experimental.
6. O `SyncService` sincroniza o índice lendo-o via interceptor como se fosse uma rede externa.

### Fluxo de Importação via QR Code / URL

1. O usuário escaneia um QR code ou cola uma URL.
2. Se a URL for remota (`https://`), o `.croqui` é baixado e salvo localmente.
3. Uma URL `aresta-zip://` é construída apontando para o arquivo salvo.
4. O fluxo segue igual ao da importação por file picker a partir do passo 4.

---

## Principais Classes e Responsabilidades

### `ZipInterceptorClient`
- Estende `http.BaseClient`
- Intercepta URIs com esquema `aresta-zip://`
- Realiza desofuscação XOR do primeiro byte para arquivos `.croqui`
- Adiciona prefixo `compilado/` automaticamente ao caminho interno
- Retorna `StreamedResponse` com status 200 ou 404

### `DatasetRepository`
- Singleton acessível via `DatasetRepository.instance`
- Notificadores reativos: `activeDataset`, `syncStatus`, `downloadingCrags`, `homeResetTrigger`
- Usa `ZipInterceptorClient` para todos os downloads (picos + imagens)
- Converte Protobuf em `Map<String, dynamic>` para consumo pela UI
- Gerencia `recent_picos.yaml` para ordenação por prioridade

### `EditorDeCroqui`
- Singleton acessível via `EditorDeCroqui.instance`
- Notificadores: `editorUrl`, `isExperimentalMode`, `isDevModeEnabled`, `timeRemaining`
- `activeBaseUrl` retorna a URL correta para o modo ativo
- `downloadsPath(docsPath)` e `indicePath(docsPath)` retornam os caminhos corretos por modo
- Persiste configuração em `editor_config.json`

### `SyncService` e `SyncIsolate`
- Orquestra toda a checagem Delta via API.
- Executa os processamentos pesados (SHA256, parseamento de arrays binários, escritas de dezenas de imagens no disco local e compactação) em background via Dart Isolates.
- Reflete o progresso percentual diretamente via `DatasetRepository.instance!.downloadingCrags`.
- Expõe `lastSyncWasAuto` e `quantidadeCroquisBaixadosAtualizadosNoUltimoSync` para controle fino de notificações de atualização de dados offline na abertura do aplicativo.


### Módulo de In-App Feedback (`feedback/`)
- **`FeedbackQueueService`**: Gerencia a fila persistente local. Salva imagens no diretório temporário, cria o payload JSON no `SharedPreferences` e agenda as rotinas de disparo em background (via Workmanager).
- **`FeedbackOrchestrator`**: Tarefa executada em background pelo SO (independente se o app estiver aberto ou não). Despacha a fila de requisições pendentes via `multipart/form-data` para o Supabase (Edge Functions).
- **`FeedbackMetadataCollector`**: Coleta dados cruciais do dispositivo no momento do report (bateria, conectividade, versão do app, resolução e tema da UI, e estado atual do NavNode) para facilitar a depuração.



## Manutenção e Debug

- Monitore os logs com o prefixo `[EditorConfig]` para eventos do temporizador e Nuke.
- Logs com `[DatasetRepo]` mostram verificações de download e caminhos de arquivo.
- O banner vermelho global é injetado via `MaterialApp.builder` para persistir em todas as telas.
- O estado de **Developer Mode** persiste no disco; os **Dados Experimentais** não persistem entre sessões.
