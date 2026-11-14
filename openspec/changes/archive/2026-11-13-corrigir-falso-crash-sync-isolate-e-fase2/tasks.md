# Tasks: Corrigir Falso Crash no Download de Binarypb no Isolate e Falso Erro no Resumo da Fase 2

- [x] 1.1 Escrever testes em `frontend/test/services/http/sync_isolate_test.dart` e `frontend/test/services/http/sync_service_test.dart` cobrindo a preservação do detalhe de exceção de rede na falha do `compilado.binarypb` e a ausência de `recordedErrors` quando a Fase 2 (`_executarAtualizacaoMidiasEmSegundoPlano`) ou `_downloadFileAtomic` falha por queda de conexão (*Red*).
- [x] 1.2 Atualizar `frontend/lib/services/http/sync_isolate.dart` e `frontend/lib/services/http/sync_service.dart` para preservar os detalhes de `errosDownloads` na falha de `binarypb` e utilizar `logAviso` / `logFalhaSyncOuDownload` nos resumos da Fase 2 e no download atômico (*Green*).
- [x] 1.3 Executar a suíte de testes e `flutter analyze --fatal-infos --fatal-warnings` garantindo 100% de aprovação e conformidade (*Refactor*).
