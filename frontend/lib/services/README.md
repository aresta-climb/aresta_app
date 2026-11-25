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

O usuário pode navegar livremente por qualquer croqui do catálogo sem ser obrigado a baixá-lo previamente para o dispositivo.

### Componentes Chave:
- **`ClienteHttpAresta` (`http/cliente_http_aresta.dart`)**: Cliente HTTP encapsulado e centralizado de todo o aplicativo. Mantém pool de conexões TCP/TLS persistente (*HTTP Keep-Alive* com `idleTimeout` de 120 segundos e `connectionTimeout` de 10 segundos). Possui construtor privado com apenas dois pontos de obtenção (`ClienteHttpAresta.instancia` em produção e `@visibleForTesting ClienteHttpAresta.paraTestes` em testes), omite deliberadamente o método `.close()` para impedir o encerramento acidental do pool compartilhado e isola `package:http/http.dart` do restante do código de produção (fiscalizado por `isolamento_cliente_http_test.dart`).
- **`GerenciadorSessaoOnline` (`dataset/sessao_online/`)**: Mantém instâncias de `Croqui` carregadas sob demanda em memória RAM (e cache volátil `/temp_cache`), atualizando reativamente o estado sem exigir downloads prévios.
- **`ServicoCroquiOnline` (`http/`)**: Baixa arquivos `.binarypb` leves sob demanda diretamente para a sessão volátil utilizando o `ClienteHttpAresta` compartilhado, calcula o SHA-256 real em memória na chegada do HTTP (prevenindo corrupção de nome de arquivo em *cache misses* da CDN por evicção LRU), grava atomicamente via `.tmp` para `compilado.binarypb.<sha256_real>` antes de expurgar versões antigas, oferece fallback offline para versões anteriores salvas em `/temp_cache`, suporta re-fetch com bypass de cache HTTP (`recarregarCroquiOnline`) e processa respostas HTTP 200 OK no polling periódico de ETag.
- **`ProvedorImagemAresta` (`widgets/provedor_imagem_aresta.dart`)**: Resolução de imagens em camadas com persistência em disco sob demanda:
  1. Armazenamento local permanente (`$downloadsRoot/<picoId>/<caminho>` ou thumbnails permanentes em `$downloadsRoot/thumbnails/<picoId>.webp`).
  2. Cache temporário volátil endereçado por conteúdo (`/temp_cache/<picoId>/<caminho>.<hash>` e `/temp_cache/thumbnails/<picoId>.webp.<hash>`).
  3. Download atômico da CDN com streaming, validação de integridade por checksum SHA-256 obrigatório, expurgo de versões antigas do mesmo arquivo com hashes divergentes, deduplicação de downloads concorrentes e persistência imediata em disco no `/temp_cache` (com fallback para `NetworkImage` sem persistência, emitindo `logError` quando o croqui está baixado offline ou `logAviso` durante navegação online caso o hash esteja ausente).
  4. Suporte a downsampling integrado via `ResizeImage.resizeIfNeeded` com `larguraAlvo`/`alturaAlvo` (padronizado em 300px para miniaturas de cartões e carrosséis).
- **Invalidação Reativa de Cache em Live Reload**: Ao receber eventos de recarregamento push via WebSocket, o aplicativo purga o cache de imagens do Flutter (`PaintingBinding.instance.imageCache.clear()` e `clearLiveImages()`), garantindo a substituição visual instantânea de texturas na GPU sem necessidade de desempilhar ou reabrir telas, tanto para croquis baixados quanto para croquis em sessão online.
- **Guardião de Saída & Banner Online**: Componentes de UI (`BannerModoOnline`, `ModalConfirmacaoSaida`) que garantem que o usuário saiba que está online e possa salvar o croqui offline antes de ir para a pedra com recarregamento contínuo em tempo real.
- **Notificações Reativas Simétricas**: No modo experimental, a recarga por WebSocket ou ETag é seamless com animação no `BannerModoExperimental`; fora do modo experimental, a interface exibe um aviso amigável via `SnackBar` informando que o guia do pico foi atualizado.
- **`GerenciadorNotificacaoDownload` (`notificacoes/gerenciador_notificacao_download.dart`)**: Gestão de notificações nativas na barra de status do sistema operacional. No Android, ancora a execução a um Foreground Service nativo ininterrupto com notificação contínua sticky (`ongoing: true`), barra de progresso e ícone principal `@mipmap/ic_launcher` (`anydpi-v26`, garantido no APK base sem depender de recursos de densidade em Split APKs), transitando atomicamente para uma notificação dispensável de sucesso/erro. No iOS, emite a notificação nativa ao concluir o salvamento.
- **`AppLogger` e Crash Reporting (`firebase/app_logger.dart`)**: Falhas graves de integridade no pipeline de download offline e sincronização de índice (como divergência de checksum SHA-256 ou HTTP 404/500 na CDN oficial `serving.arestaclimb.com`) são tratadas no Crashlytics. Já erros HTTP originados de sessões efêmeras do Editor Desktop (`EditorDeCroqui.isUrlExperimental(url) == true`, como `previa.arestaclimb.com` ou LAN local) são registrados apenas como `logAviso` (breadcrumb) em `SyncNetwork`, evitando alertas falsos quando o autor encerra o editor. Para evitar falsos positivos quando o escalador estiver sem conexão na rocha (`SocketException`, `ClientException`, `TimeoutException` ou HTTP `502/503/504/429`), apenas a camada que possui o objeto `error` original (`ServicoCroquiOnline.carregarCroquiRemoto` e `SyncService.tratarErroDownloadIsolate`) invoca `logFalhaSyncOuDownload`, enquanto orquestradores de nível superior (`handlePicoSelection`, `SyncService.downloadCrag` e `ServicoDownloadSegundoPlano.executarDownload`) registram o encerramento sem sucesso como breadcrumb (`logAviso`).
- **`TelemetryService` e Analytics (`firebase/telemetria.dart`)**: Rastreamento de telemetria analítica com taxonomia padronizada em português via GA4:
  - *Deep Links & QR Codes*: `logDeepLinkAberto` captura parâmetros de rota, tipo de inicialização (`cold_start`/`warm_start`), status de sucesso/falha e dimensões UTM (`utm_source`, `utm_medium`, `utm_campaign`, etc.).
  - *Índice de Escaladas*: `logAcaoIndiceEscaladas` instrumenta alternância de abas de modalidade e aplicação de filtros dinâmicos de graduação (`filtrar_grau`), setor (`filtrar_setor`), conquistadores (`filtrar_conquistador`), clássicas (`filtrar_classicas`) e limpeza (`limpar_filtros`) com valores no parâmetro `detalhe`.
  - *Pico Hub e Subpáginas*: `logNavegacaoPicoHub` para os cards centrais (Setores, Explorar Local, Regras, Comunidade, Créditos, Índice) e `logApoioPix` para cópia de chave PIX em Apoie o Pico.
  - *Guardião de Saída e Banner*: `logAcaoGuardiaoSaida` e `logSalvarOfflineBanner` para monitorar a conversão de salvamento offline antes de ir à pedra.
  - *Interações Gerais*: `logAcaoBetaAberto` para o modal de beta, `logLinkExterno` para abertura de redes sociais e referências de desenvolvedores, e `logAlterarOrdenacao` para alternância de ordenação de listas em setores, grupos e catálogo.
  - *Registro de Primeira Visita*: `RegistroPrimeiraVisita` (`registro_primeira_visita.dart`) gerencia a persistência de croquis já visitados pelo usuário para enriquecer o evento `abrir_croqui`.

## Manutenção e Debug

- Falhas no pipeline de download offline ou no Isolate são sinalizadas com `🛑 [SyncIsolate]`, `🛑 [SyncService]` ou `💥 [AppLogger CRASH]`.
- Monitore os logs com o prefixo `[EditorConfig]` para eventos do temporizador e Nuke.
- Logs com `[DatasetRepo]` mostram verificações de download e caminhos de arquivo.
- Logs com `[LiveReload]` mostram conexões e eventos push recebidos pelo servidor de desenvolvimento.
- O banner vermelho global `BannerModoExperimental` é injetado via `MaterialApp.builder` para persistir em todas as telas.
- O estado de **Developer Mode** persiste no disco; os **Dados Experimentais** não persistem entre sessões.

---

## Controle de Recursos em Desenvolvimento (Feature Flags & Chaves de Acesso)

Para garantir que funcionalidades em desenvolvimento (como o **Perfil do Escalador** e a **Caderneta Esportiva**) não fiquem expostas prematuramente em compilações de produção e versões de release, o acesso é protegido por flags de compilação gerenciadas pela classe `ConfiguracaoRecursos` (`configuracao_recursos.dart`).

### Comportamento Padrão (Produção / Release)
Em qualquer compilação ou execução convencional (`flutter build apk --release`, `flutter run`) onde nenhuma chave ou flag for explicitamente informada:
- `ConfiguracaoRecursos.perfilHabilitado` avalia como `false`.
- O botão de Perfil (`btn_home_perfil`) na AppBar da Home (`ArestaHomeAppBar`) permanece oculto.
- O cartão e o botão de registro de ascensão/cadena (`btn_registrar_cadena`) na tela da via (`via_functions.dart`) permanecem ocultos.
- Tentativas programáticas ou diretas de navegação via `AppNav.toPerfil` são bloqueadas silenciosamente.

### Como Desbloquear Recursos em Desenvolvimento
Desenvolvedores e testadores podem liberar o acesso completo aos recursos durante a execução ou build passando flags via `--dart-define`:

```bash
# Opção 1: Via chave de API / Segredo (conforme exemplo em desenvolvimento)
flutter run --dart-define=API_KEY=my_secret_key --dart-define=APP_MODE=production

# Opção 2: Via chave específica de acesso ao perfil
flutter run --dart-define=CHAVE_ACESSO_PERFIL=aresta_segredo_perfil_2026

# Opção 3: Via flag booleana direta
flutter run --dart-define=HABILITAR_PERFIL=true
```

### Chaves Secretas Autorizadas
O sistema reconhece o seguinte conjunto de chaves padronizadas:
- `my_secret_key`
- `aresta_segredo_perfil_2026`
- `minha_chave_secreta`
- `aresta_dev_secret`

### Testes Automatizados
Para testes unitários e de widget, a classe provê métodos estáticos com a anotação `@visibleForTesting`:
- `ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true)`: Força o estado habilitado.
- `ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(false)`: Força o estado desabilitado.
- `ConfiguracaoRecursos.redefinirParaTestes()`: Restaura o estado original derivado do ambiente.

### Preferência Local do Escalador (`ControladorInteracoesUsuario`)
Mesmo quando `ConfiguracaoRecursos.perfilHabilitado` está ativo na compilação, escaladores que preferem utilizar o aplicativo exclusivamente para consulta de croquis e dados técnicos podem desativar os elementos opcionais de Perfil e Caderneta em tempo de execução na tela de Configurações (`construirCartaoInteracoesCaderneta`):
- **`ControladorInteracoesUsuario` (`controlador_interacoes_usuario.dart`)**: Persiste a chave `interacoes_caderneta_ativas` no `SharedPreferences` (padrão `true`) e expõe `interacoesAtivasNotifier` (`ValueListenable<bool>`) e `exibirElementosInterativos` (`ConfiguracaoRecursos.perfilHabilitado && interacoesAtivasNotifier.value`).
- **Ocultação Reativa Sem Perda de Dados**: Quando desativado pelo usuário, o botão de Perfil na Home (`ArestaHomeAppBar`), o bloco de registro de cadena na tela da via (`via_functions.dart`) e a navegação `AppNav.toPerfil` são ocultados/bloqueados imediatamente, preservando intactos todos os registros locais do `RepositorioCadernetaLocal` e mantendo alertas comunitários de segurança irrestritos.
