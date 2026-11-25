# Testes de Serviços (`test/services/`)

Este diretório contém os testes unitários dos serviços de `lib/services/` e das bibliotecas de Fakes determinísticos (`*_fake.dart`) usadas nos testes de camadas superiores.

## Principais Suítes

| Pasta / Arquivo | Escopo |
|---|---|
| `autenticacao/` | `AutenticadorNativoCanal`, `ClienteSupabaseAutenticacao` (OTP, `id_token`, PKCE e chaves `sb_publishable_...`), `SincronizadorPerfilSupabase`, `tradutor_erros_autenticacao.dart`, `ServicoAutenticacaoLocal` e `ServicoAutenticacaoFake` |
| `midia/` | `SeletorFotoPerfilNativo` e `SeletorFotoPerfilFake` no canal `app.escalada.croquis/seletor_midia` |
| `caderneta/` | `ArmazenamentoLocalCaderneta`, `RepositorioCadernetaLocal`, `ClienteCadenasSupabase`, `CompiladorEstatisticasCaderneta` e `CatalogoViasCaderneta` |
| `comunidade/` | `ArmazenamentoFilaInteracoes`, `ClienteFilaInteracoesSupabase`, `ClienteFilaInteracoesFake`, `RepositorioInteracoesViaMemoria` e `RepositorioInteracoesViaFake` |
| `catalogo/` | `RepositorioCatalogo` (`catalogo.db` em SQLite, sincronização incremental e buscas por texto/UID) |
| `dataset/` e `repositorio_dataset_test.dart` | `DatasetRepository`, `GerenciadorArquivosLocais`, `GerenciadorSessaoOnline`, `NormalizadorCroqui` e `ExtratorMetadadosCroqui` |
| `http/` e `sync_*_test.dart` | `ClienteHttpAresta`, `SyncService`, `SyncIsolate`, `SyncNetwork`, `SyncStorage`, `ServicoCroquiOnline` e `ServicoDownloadSegundoPlano` |
| `editor_croqui_test.dart` e `experimental_mode_test.dart` | Alternância entre modo oficial e experimental, caminhos em disco e limpeza de sessão (`nukeExperimentalData`) |
| `feedback/` | Fila local, coleta de metadados, auditoria de hashes SHA-256 e envio multipart |
| `firebase/` | `AppLogger`, `RemoteConfigService`, `TelemetryService`, `ServicoPerformance`, `ClassificadorDispositivo` e `ValidadorApp` |
| `configuracao_recursos_test.dart` e `controlador_interacoes_usuario_test.dart` | Flags de compilação e preferência local de exibição da caderneta |

## Execução

```bash
flutter test test/services/
flutter test test/services/autenticacao/
flutter test test/services/comunidade/
```

## Notas

- Arquivos temporários usam `Directory.systemTemp` e são removidos em `tearDown`.
- Testes de `SyncService` e `SyncIsolate` que cruzam fronteiras de `Isolate` utilizam `HttpServer.bind(InternetAddress.loopbackIPv4, 0)`.
