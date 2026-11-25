# Serviços (`lib/services/`)

Este diretório concentra os repositórios, clientes de rede, persistência local e integrações nativas do aplicativo.

---

## Estrutura

| Arquivo / Pasta | Responsabilidade |
|---|---|
| `repositorio_dataset.dart` e `dataset/` | Estado dos croquis baixados e online, armazenamento em disco, prioridade de acesso e normalização Protobuf v5 |
| `editor_croqui.dart` e `editor_croqui/` | Alternância entre modo oficial e modo experimental (Editor Desktop via WebSocket) |
| `http/` | `ClienteHttpAresta`, `SyncService`, `SyncIsolate`, `SyncNetwork`, `SyncStorage`, `ServicoCroquiOnline`, `ServicoDownloadSegundoPlano` e `UpdateDownloader` |
| `catalogo/` | Banco SQLite local (`catalogo.db` / `RepositorioCatalogo`) com sincronização incremental e busca textual |
| `autenticacao/` | Autenticação sem senha (`ServicoAutenticacaoLocal`), canal nativo (`AutenticadorNativoCanal`), cliente GoTrue (`ClienteSupabaseAutenticacao`), perfil/Storage (`SincronizadorPerfilSupabase`) e tradução de erros (`tradutor_erros_autenticacao.dart`) |
| `midia/` | Seleção nativa de foto de perfil (`SeletorFotoPerfilNativo`), correção EXIF, corte `256x256` e compressão WebP |
| `caderneta/` | Persistência local de ascensões (`RepositorioCadernetaLocal`), sincronização com `public.cadenas` (`ClienteCadenasSupabase`), estatísticas e hidratação de vias |
| `comunidade/` | Sincronização de votos de grau, comentários e alertas de segurança com `public.fila_interacoes` (`ClienteFilaInteracoesSupabase`, `RepositorioInteracoesViaMemoria`, `ArmazenamentoFilaInteracoes`) |
| `compartilhamento/` | Formatação e compartilhamento de links curtos `aresta.cc` (`ServicoCompartilhamento`) |
| `notificacoes/` | Notificações nativas de progresso e conclusão de download (`GerenciadorNotificacaoDownload`) |
| `feedback/` | Coleta de diagnóstico, auditoria SHA-256 e fila local de envio para a Edge Function `app-feedback` |
| `firebase/` | Isolamento de Firebase e Sentry (`AppLogger`, `TelemetryService`, `ServicoPerformance`, `RemoteConfigService`, `ValidadorApp`) |
| `smoke_ci/` | Utilitários de validação pós-build em emuladores de CI (não importados por `lib/main.dart`) |
| `controlador_interacoes_usuario.dart` | Preferência local (`interacoes_caderneta_ativas`) para exibir ou ocultar recursos de perfil e caderneta |
| `configuracao_recursos.dart` | Leitura de flags `--dart-define` para ativação de recursos em desenvolvimento |
| `gerenciador_filtros_croqui.dart` | Estado compartilhado de filtros e ordenação durante a navegação em um croqui |
| `inicializacao_app.dart` | Configuração de memória, modo edge-to-edge, bootstrap de serviços locais, listeners de Live Reload e migração de termos |

---

## Autenticação Sem Senha e Sincronização de Perfil (`autenticacao/` e `midia/`)

1. **`ServicoAutenticacaoLocal`**:
   - Valida formato de e-mail e código OTP numérico de 6 dígitos.
   - Executa `solicitarCodigoOtpEmail`, `verificarCodigoOtpEmail`, `entrarComGoogle`, `entrarComApple`, `atualizarPerfilRemoto`, `encerrarSessao` e `excluirContaPermanentemente`.
   - Mantém o `autorIdPublico` (NanoID 14c) e as cadenas locais ao autenticar ou encerrar sessão.
2. **`ClienteSupabaseAutenticacao`**:
   - Envia e verifica códigos OTP (`/auth/v1/otp` e `/auth/v1/verify`) e autentica sessões OAuth (`grant_type=id_token` ou `grant_type=pkce`).
   - No Android, usa `CredentialManager` com fallback PKCE em Custom Tabs quando não há credencial Google configurada no aparelho/emulador; no iOS, usa `ASWebAuthenticationSession` (Google) e `ASAuthorizationAppleIDProvider` (Apple).
   - Suporta chaves públicas Supabase nos formatos JWT (`eyJ...`) e opaco (`sb_publishable_...`), omitindo `Authorization: Bearer` quando a chave não é um JWT de sessão.
3. **`SincronizadorPerfilSupabase`**:
   - Lê e grava `public.perfis` (`/rest/v1/perfis?on_conflict=user_id`), envia avatares WebP para `avatars/<userId>/avatar.webp` e atualiza metadados em `/auth/v1/user`.

---

## Interações Comunitárias e Alertas (`comunidade/`)

- **`RepositorioInteracoesViaMemoria`**: Mantém o cache em memória e em `SharedPreferences` dos dados comunitários por `escaladaUid` e dos alertas contribuídos pelo usuário (`obterMeusAlertasContribuidos`).
- **Categorias de Alerta (`CategoriaAlertaSeguranca`)**: `FAUNA` (`🐝`), `ROCHA_AGARRA_INSTAVEL` (`🪨`), `PROTECAO_PRECARIA` (`🔩`) e `EXPOSICAO_E4_MAIS` (`⚠️`).
- **Deduplicação e Recuperação de Sessão**: Impede auto-confirmação pelo criador e múltiplos `+1` do mesmo `autorIdPublico` no mesmo alerta. Em escritas autenticadas, renova o JWT em respostas `HTTP 401` (`refreshToken`) e ressincroniza `public.perfis` antes de repetir em `HTTP 403`.

---

## Modo Experimental e Live Reload (`editor_croqui.dart`)

Permite testar croquis em edição a partir do Editor Desktop sem misturar arquivos com os dados de produção.

| Contexto | URL base | Índice | Catálogo SQLite | Downloads |
|---|---|---|---|---|
| **Oficial** | `https://aresta-climb.github.io/aresta_serving` | `<docs>/indice.binarypb` | `<docs>/catalogo.db` | `<docs>/downloads/` |
| **Experimental** | URL da sessão do Editor Desktop | `<docs>/editor/experimental/indice.binarypb` | `<docs>/editor/experimental/catalogo.db` | `<docs>/editor/experimental/downloads/` |

- **Ativação**: Desbloqueada tocando 7 vezes no ícone de status em Configurações, seguida da leitura do QR Code ou código de 8 caracteres da sessão.
- **Limpeza na Inicialização e na Saída (`nukeExperimentalData`)**: Os dados experimentais não persistem entre reinicializações completas do app. Ao sair ou receber `HTTP 404` da sessão expirada, o serviço fecha o WebSocket e o `catalogo.db` experimental, apaga `editor/experimental/`, recarrega o índice oficial e notifica a UI (`ModalSessaoExperimentalEncerrada`).
- **Controle de Requisições**: Enquanto o WebSocket de Live Reload está conectado, o polling HTTP de ETag em `ServicoCroquiOnline` permanece desativado.

---

## Resolução de Croquis em `DatasetRepository.getCroqui`

1. **Memória RAM**: Consulta `GerenciadorSessaoOnline` e `activeDataset.value?.picosBaixados`.
2. **Downloads Locais**: Lê `<downloads>/<picoId>/compilado.binarypb` (renomeando `<picoId>.binarypb` antigo se encontrado).
3. **Cache Temporário**: Lê `/temp_cache/<picoId>/compilado.binarypb.<sha256>`.
4. **Rede**: Baixa o arquivo via `ServicoCroquiOnline` com `?v=<sha256>`, valida o SHA-256 em memória, grava via `.tmp` em `/temp_cache` e remove versões anteriores divergentes.

---

## Flags de Compilação (`ConfiguracaoRecursos` e `ControladorInteracoesUsuario`)

Por padrão (`flutter run` / builds sem flag), `ConfiguracaoRecursos.perfilHabilitado` é `false`. Para habilitar os recursos de Perfil, Caderneta e Interações durante o desenvolvimento:

```bash
flutter run --dart-define=HABILITAR_PERFIL=true
# ou
flutter run --dart-define=CHAVE_ACESSO_PERFIL=aresta_segredo_perfil_2026
```

Em testes, use `ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true)` e `redefinirParaTestes()`. Quando habilitado na compilação, o usuário ainda pode ocultar ou exibir os controles de perfil e caderneta nas Configurações via `ControladorInteracoesUsuario` sem apagar os dados salvos localmente.
