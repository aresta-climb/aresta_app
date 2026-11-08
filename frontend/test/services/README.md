# Testes de Serviços

Esta pasta contém os testes unitários dos serviços principais da aplicação. Os serviços testados aqui são responsáveis por lógica de negócio central, autenticação com o Supabase, seleção nativa de mídia, gerenciamento de configuração e sincronização de dados.

## Arquivos

| Arquivo | Serviço testado | Descrição |
|---|---|---|
| `autenticacao/autenticador_nativo_test.dart` | `AutenticadorNativoCanal` | Testa o canal nativo `app.escalada.croquis/autenticacao_nativa` para obtenção de `id_token` do Google e da Apple, tratamento de cancelamento pelo usuário e fallback silencioso em `PlatformException` |
| `autenticacao/cliente_supabase_autenticacao_test.dart` | `ClienteSupabaseAutenticacao` | Testa os fluxos HTTP, `grant_type=id_token` nativo e OAuth 2.0 com o Supabase GoTrue (`/auth/v1/token`, `/auth/v1/signup`), Google e Apple OAuth PKCE (`S256`) e `Implicit` e delegação para sincronização de perfil |
| `autenticacao/sincronizador_perfil_supabase_test.dart` | `SincronizadorPerfilSupabase` | Testa consulta e upsert em `public.perfis` (`/rest/v1/perfis`), upload de fotos WebP no bucket `avatars` do Supabase Storage e atualização de metadados no GoTrue (`PUT /auth/v1/user`) |
| `autenticacao/tradutor_erros_autenticacao_test.dart` | `tradutor_erros_autenticacao.dart` | Testa tradução de códigos de erro HTTP/GoTrue para português, geração de desafio PKCE (`S256`) e extração de parâmetros de callback OAuth |
| `autenticacao/servico_autenticacao_test.dart` | `ServicoAutenticacaoLocal` | Testa validação de e-mail/senha/nome, preservação do `autorIdPublico` (NanoID 14c) e cadenas locais, integração com `ClienteSupabaseAutenticacao`, atualização remota de perfil/foto e encerramento de sessão |
| `midia/seletor_foto_perfil_test.dart` | `SeletorFotoPerfilNativo` | Testa a invocação do canal nativo `app.escalada.croquis/seletor_midia`, retorno e conversão para o Data URI `data:image/webp;base64,...`, cancelamento pelo usuário e resiliência a `PlatformException` |
| `caderneta/repositorio_caderneta_test.dart` | `RepositorioCadernetaLocal` | Testa persistência e reatividade de cadenas e perfil do escalador |
| `caderneta/armazenamento_local_caderneta_test.dart` | `ArmazenamentoLocalCaderneta` | Testa serialização em `SharedPreferences` e recuperação contra payloads corrompidos |
| `caderneta/compilador_estatisticas_test.dart` | `CompiladorEstatisticasCaderneta` | Testa cálculo de pirâmides de graus (vias e boulders), recordes pessoais e fallback por `grauSugerido` |
| `caderneta/catalogo_vias_caderneta_test.dart` | `CatalogoViasCaderneta` | Testa hidratação reativa de nomes, graus e contagem de picos a partir de `catalogo.db` e croquis em memória |
| `editor_croqui_test.dart` | `EditorDeCroqui` | Testa lógica de modos (oficial, editor, experimental), cálculo de caminhos (`downloadsPath`, `indicePath`) e notificadores de estado |
| `experimental_mode_test.dart` | `EditorDeCroqui` | Testa o comportamento do Modo Experimental: persistência de URL na desconexão e limpeza total (Nuke) |
| `repositorio_dataset_test.dart` | `DatasetRepository` | Testa estado público do repositório, mapeamento de propriedades (ex: descrição) e inicializações tipadas |
| `sync_rede_test.dart` | `SyncNetwork` | Testa a leitura HTTP com retentativas, ETags (304 Not Modified) e timeouts |
| `sync_armazenamento_test.dart` | `SyncStorage` | Testa a persistência atômica usando arquivos `.tmp` e a extração do `indice.binarypb` |
| `sync_status_timer_test.dart` | `SyncStatusTimer` | Testa o debouncer do status de sync que previne *flickering* rápido na UI |
| `sync_service_test.dart` | `SyncService` | Testes de sincronização atômica, checagem de hashes SHA-256 e extração de imagens Markdown |
| `configuracao_recursos_test.dart` | `ConfiguracaoRecursos` | Testa leitura de variáveis de compilação (`--dart-define`), validação de chaves de acesso secretas e controle de ativação de recursos |
| `firebase/remote_config_test.dart` | `RemoteConfigService` | Testa fallbacks de configuração remota (incluindo `supabaseUrl` e `supabaseAnonKey`), cache e resiliência offline |
| `feedback/feedback_queue_service_test.dart` | `FeedbackQueueService` | Testa o enfileiramento na fila local e a integração com o repositório de persistência |
| `feedback/feedback_metadata_collector_test.dart` | `FeedbackMetadataCollector` | Testa a coleta correta dos metadados de telemetria do dispositivo e auditoria de hashes |
| `feedback/feedback_network_service_test.dart` | `FeedbackNetworkService` | Testa envio multipart protegido por App Check para o backend Supabase |
| `feedback/gatilho_feedback_rede_test.dart` | `NetworkFeedbackTrigger` | Testa disparo automático de envio quando a conectividade é restabelecida |
| `feedback/tarefa_feedback_test.dart` | `TarefaFeedback` | Testa modelo de tarefas da fila de persistência atômica em disco |
| `dataset/gerenciador_arquivos_locais_test.dart` | `GerenciadorArquivosLocais` | Testa operações diretas de arquivos e diretórios de croquis no disco local |
| `dataset/gerenciador_sessao_online_test.dart` | `GerenciadorSessaoOnline` | Testa gestão de croquis em memória RAM e cache volátil sob demanda |
| `dataset/metadados/extrator_metadados_croqui_test.dart` | `ExtratorMetadadosCroqui` | Testa vinculação de entidades `Croqui`/`Pico` ao `ResumoPico` sem I/O antecipado de capas e extração de caminhos de capa em Markdown |

## Como executar

```bash
# Todos os testes desta pasta
flutter test test/services/

# Testes de autenticação e Supabase
flutter test test/services/autenticacao/

# Um arquivo específico
flutter test test/services/editor_croqui_test.dart
```

## Notas

- Os testes criam arquivos temporários em `Directory.systemTemp` e os removem após cada teste.
- Testes que dependem de `getApplicationDocumentsDirectory()` utilizam diretórios temporários injetados ou binding explícito do Flutter.
