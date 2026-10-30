## ADDED Requirements

### Requirement: Curto-Circuito de Rede Após Falha de Sincronização Offline
Quando o carregamento sob demanda de um croqui (`DatasetRepository.getCroqui` ou `LocalizadorDestinoUid`) executar uma sincronização prévia do índice (`syncIndex`) e esta falhar por ausência de conectividade (`SyncStatus.offline`), o sistema DEVE (MUST) interromper imediatamente a resolução retornando nulo sem disparar uma segunda requisição HTTP para baixar o `.binarypb` remoto.

#### Scenario: Falha de conexão na sincronização prévia do índice ao abrir croqui online
- **WHEN** o usuário tenta abrir um croqui não presente em memória, `/downloads` ou `/temp_cache` e a chamada a `syncIndex()` resulta em `SyncStatus.offline`
- **THEN** o repositório aborta imediatamente retornando `null` sem invocar `carregarCroquiRemoto` na camada HTTP.

#### Scenario: Falha de conexão na sincronização do catálogo para UID ausente localmente
- **WHEN** `LocalizadorDestinoUid` tenta sincronizar o índice para localizar um `uid` ausente localmente e `syncIndex()` resulta em `SyncStatus.offline`
- **THEN** o localizador encerra imediatamente a busca sem repetir consultas locais ou disparar download de croqui.
