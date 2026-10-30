## MODIFIED Requirements

### Requirement: Curto-Circuito de Rede Após Falha de Sincronização Offline
Quando o carregamento sob demanda de um croqui (`DatasetRepository.getCroqui` ou `LocalizadorDestinoUid`) executar uma sincronização prévia do índice (`syncIndex`) e esta falhar por ausência de conectividade (`SyncStatus.offline`), o sistema DEVE (MUST) interromper imediatamente a resolução retornando nulo sem disparar uma segunda requisição HTTP para baixar o `.binarypb` remoto. Adicionalmente, quando `DatasetRepository.getCroqui` realizar o download direto de um croqui já presente no índice local (`carregarCroquiRemoto`), a sincronização assíncrona em segundo plano (`unawaited(syncIndex())`) SÓ DEVE (MUST) ser disparada se o carregamento remoto do croqui obtiver sucesso, evitando retentativas em segundo plano e reemissões de estado quando o dispositivo estiver offline.

#### Scenario: Falha de conexão na sincronização prévia do índice ao abrir croqui online
- **WHEN** o usuário tenta abrir um croqui não presente em memória, `/downloads` ou `/temp_cache` e a chamada prévia a `syncIndex()` resulta em `SyncStatus.offline`
- **THEN** o repositório aborta imediatamente retornando `null` sem invocar `carregarCroquiRemoto` na camada HTTP.

#### Scenario: Supressão de syncIndex em segundo plano quando carregarCroquiRemoto falha offline
- **WHEN** `DatasetRepository.getCroqui` tenta baixar diretamente o `.binarypb` de um croqui listado no índice local e `carregarCroquiRemoto` retorna `null` por falta de conexão
- **THEN** o repositório retorna `null` sem disparar `unawaited(syncIndex())` em segundo plano.

#### Scenario: Falha de conexão na sincronização do catálogo para UID ausente localmente
- **WHEN** `LocalizadorDestinoUid` tenta sincronizar o índice para localizar um `uid` ausente localmente e `syncIndex()` resulta em `SyncStatus.offline`
- **THEN** o localizador encerra imediatamente a busca sem repetir consultas locais ou disparar download de croqui.
