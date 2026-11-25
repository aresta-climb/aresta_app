# Aresta Climb App — Frontend

Aplicativo Flutter para Android e iOS. Guia de escalada com leitura offline, mapas vetoriais de setores, busca em catálogo SQLite, caderneta de ascensões e alertas de segurança.

---

## Funcionalidades

- **Sincronização em Isolate**: Downloads e atualizações de croquis rodam em background via `Isolate`, validando hashes SHA-256 e baixando apenas arquivos alterados. No Android, downloads em segundo plano usam Foreground Service com notificação de progresso.
- **Autenticação Sem Senha, Perfil e Caderneta**:
  - Registro local de ascensões (`Cadena`) por estilo (*À Vista*, *Flash*, *Trabalhado*, *Tentativa*), pirâmide de graus, estatísticas, acompanhamento dos alertas criados ou confirmados pelo usuário e identificador público NanoID de 14 caracteres (`autorIdPublico`).
  - Login sem senha via **Google** (Android e iOS), **Apple** (iOS) ou **código OTP de 6 dígitos por e-mail** no **Supabase Auth**, preservando o `autorIdPublico` e as cadenas locais. Inclui atalho direto para abrir as configurações sem exigir login.
  - Seleção nativa de foto de perfil (`app.escalada.croquis/seletor_midia`) com correção EXIF, recorte quadrado `256x256` em WebP e envio ao bucket `avatars` no Supabase Storage.
- **Interações Comunitárias e Alertas nas Vias**:
  - Votação de consenso de grau (`-2` a `+2`), comentários públicos de beta e alertas de segurança (`Fauna` `🐝`, `Rocha ou Agarra Instável` `🪨`, `Proteção Precária` `🔩`, `Exposição E4+` `⚠️`) exibidos na página da via e sobre os marcadores do croqui interativo, com confirmação *"Ainda está lá?"* limitada a uma contribuição positiva por perfil.
- **Home e Busca Global (`catalogo.db`)**: Carrossel de croquis salvos e busca aproximada (*fuzzy*, sem diferenciar acentos) sobre o banco SQLite local (`catalogo.db`), cobrindo picos, grupos, setores e escaladas.
- **Compartilhamento e Deep Links (`aresta.cc` e `arestaclimb.com/croquis`)**: Geração de links curtos (`/s/<uid>`, `/sm/<uid>`), leitura de placas QR Code (`/q/<uid>`, `/qm/<uid>`) e abertura de URLs de `/croquis/<uid>`, preservando parâmetros UTM e separando callbacks OAuth (`aresta://app.arestaclimb.com/auth-callback`).
- **Explorar e Mapa Global**: Catálogo de picos com download individual, sincronização incremental do `catalogo.db` e visualização geográfica no Google Maps.
- **Croquis e Mapas Interativos**: Desenho vetorial de linhas de vias (sólida, tracejada, pontilhada), detecção de toque por distância euclidiana (16dp), carrossel entre mapas e botão de recentralização.
- **Navegação em Árvore e Retorno Rápido ao Início**: Roteamento declarativo baseado em nós (`NavNode`); em qualquer página secundária, tocar no botão de voltar recua um nível e segurar o botão anima o indicador radial e retorna à Home.
- **Live Reload e Modo Experimental**: Conexão por QR Code ou código de sessão com o Editor Desktop via LAN ou Cloudflare Relay e atualização via WebSocket.

---

## Tecnologias

| Dependência | Uso |
|---|---|
| **Flutter / Dart** (`^3.11.3`) | Interface multiplataforma (Android e iOS) |
| **`protobuf`** (`^6.0.0`) | Serialização binária de índices e croquis (`.binarypb`) |
| **`sqflite`** (`^2.4.1`) | Catálogo relacional local (`catalogo.db`) e busca textual |
| **`share_plus`** (`^13.3.1`) | Compartilhamento de links (`aresta.cc`) |
| **`app_links` / `url_launcher`** | Recebimento de deep links e abertura de links externos |
| **`http`** | Downloads, sincronização e comunicação REST/Auth/Storage com o Supabase (isolado em `ClienteHttpAresta`) |
| **`path_provider`** | Diretórios locais de documentos e cache |
| **`shared_preferences`** | Preferências locais, cache de perfil, caderneta e filas offline |
| **`fuzzy`** | Busca aproximada na pesquisa global e busca interna de pico |
| **`google_maps_flutter`** | Mapa Global de picos |
| **`flutter_markdown_plus`** | Renderização de descrições e termos em Markdown |
| **`mobile_scanner`** | Leitura de QR Codes |
| **`sentry_flutter`** | Monitoramento de erros e breadcrumbs com fila offline (junto ao Firebase Crashlytics) |
| **`crypto`** | Cálculo de SHA-256 e desafios OAuth PKCE (`S256`) |

---

## Estrutura do Projeto

```text
frontend/
├── firebase.json                        - Configuração do FlutterFire CLI
├── legal/repo/                          - Submódulo com Termos de Uso e Política de Privacidade (.md)
├── tool/                                - Utilitários CLI de termos legais, versão e auditoria de binário
├── lib/
│   ├── main.dart                        - Ponto de entrada: bindings, serviços e navegação principal
│   ├── firebase_options.dart            - Configurações geradas pelo FlutterFire
│   ├── constants/
│   │   └── legal_version.g.dart         - Constante de data autogerada da última atualização legal
│   ├── data/
│   │   └── modelos/                     - Modelos de domínio locais (PerfilEscalador, Cadena, TipoAscensao, TipoEscalada, FeedbackMetadata)
│   ├── theme/
│   │   ├── cores_app.dart               - Definição da paleta mestre de cores com suporte a Light/Dark Mode
│   │   └── gerenciador_tema.dart        - Gerenciamento de estado do tema
│   ├── utils/
│   │   ├── calculadora_distancia_estrada.dart - KD-Tree 2D e cálculo offline de distância rodoviária estimada
│   │   ├── utilitarios_markdown.dart    - Funções utilitárias para parseamento de strings Markdown
│   │   ├── formatador_escalada.dart     - Formatação de graus, nomes e localização de escaladas por UID
│   │   └── categorizacao_pico.dart      - Analisa metadados (tags) e agrupa botões do pico em categorias semânticas
│   ├── view/                            - Camada de visualização e apresentação
│   │   ├── function_library/            - Construtores de UI, callbacks e componentes visuais
│   │   │   ├── biblioteca_funcoes_comuns.dart - Sistema de design (paletas, tipografia, componentes base)
│   │   │   ├── markdown_offline.dart    - Visualizador Markdown com FileImage offline
│   │   │   ├── funcoes_configuracoes.dart - Conexão com Editor Desktop via QR Code/URL, temas e diagnósticos
│   │   │   ├── funcoes_hub_perfil_caderneta.dart - Cabeçalho com avatar/câmera, cartões de métricas e menu do Hub de Perfil
│   │   │   ├── funcoes_caderneta.dart   - Histórico de ascensões e componentes da caderneta
│   │   │   ├── mapa/
│   │   │   │   ├── mapa_global_functions.dart - Construtores visuais específicos para o mapa mundial
│   │   │   │   └── mapa_marker.dart     - Renderiza via Canvas o pino (BitmapDescriptor) com o logo no Mapa
│   │   │   └── *_functions.dart         - Funções específicas por página (home, browse, pico, …)
│   │   └── view_models/                 - Modelos de apresentação e gerenciamento de estado
│   │       ├── login_view_model.dart    - Estado e comandos de login, criação de conta e Google OAuth
│   │       ├── hub_perfil_caderneta_view_model.dart - Estado reativo do Hub de Perfil, foto e métricas
│   │       ├── perfil_view_model.dart   - Estatísticas e histórico da caderneta esportiva
│   │       ├── card_croqui_view_model.dart - Estado e apresentação de cards de croqui
│   │       ├── mapa_pico_view_model.dart - Apresentação e coordenadas de picos no mapa
│   │       ├── pico_proximo_view_model.dart - Apresentação de picos próximos e distâncias
│   │       └── *_view_model.dart        - View models para páginas e componentes reativos
│   ├── aresta_api/                      - Submodule: arquivos .proto, SQL, OpenAPI e código Protobuf gerado
│   ├── navigation/                      - Estrutura de navegação baseada em árvore (Tree Nav) e Hot-Reload
│   │   ├── README.md                    - Detalhamento da arquitetura de navegação reativa sem pilha
│   │   ├── funcoes_navegacao.dart       - API estática AppNav com herança de contexto
│   │   ├── arvore_navegacao.dart        - Classes dos nós baseados em ID (NavNode) e controlador central
│   │   ├── servico_navegacao_deep_link.dart - Resolução de deep links aresta.cc e interceptação de callbacks OAuth
│   │   └── construtor_reativo_pagina.dart - Injetor reativo de UI para hot-reload de croquis
│   ├── pages/                           - Páginas do app
│   │   ├── home.dart                    - Carrossel e lista de guias locais
│   │   ├── explorar.dart                - Índice remoto com download inline
│   │   ├── mapa_global.dart             - Visão de mapa global interativa a partir do Explorar
│   │   ├── gps.dart                     - Entrada do mapa
│   │   ├── mapa_interativo.dart         - Mapa interativo com overlay de setores/vias e compartilhamento
│   │   ├── mapa_geral_pico.dart         - Mapa contendo o overview de todos os setores do pico
│   │   ├── pico.dart                    - Nó raiz de um guia, atua como hub distribuindo para as sub-páginas
│   │   ├── pico_subpages/               - Views tabulares do guia (Comunidade Local, Setores, Explorar Local, etc)
│   │   ├── comunidade.dart              - Hub global de redes sociais (Discord, WhatsApp, GitHub)
│   │   ├── grupo.dart                   - Agrupamento de setores
│   │   ├── setor.dart                   - Subárea com lista de vias ou boulders
│   │   ├── via.dart                     - Nó folha: beta, croqui, imagens e seção da caderneta
│   │   ├── login.dart                   - Autenticação com Google, e-mail/senha, criação de conta e modo offline
│   │   ├── hub_perfil_caderneta.dart    - Hub de Perfil do Escalador com avatar, métricas e menu
│   │   ├── caderneta.dart               - Caderneta esportiva detalhada e pirâmide de graus
│   │   ├── configuracoes.dart           - Configurações e ferramentas de editor
│   │   ├── termos_de_uso.dart           - Visualizador dos documentos legais
│   │   └── qr_scanner.dart              - Scanner de QR code
│   ├── services/                        - Serviços centrais
│   │   ├── autenticacao/
│   │   │   ├── servico_autenticacao.dart - Domínio de autenticação, validação e persistência do PerfilEscalador
│   │   │   └── cliente_supabase_autenticacao.dart - Comunicação GoTrue (/auth/v1), PostgREST (perfis), Storage (avatars) e OAuth PKCE
│   │   ├── midia/
│   │   │   └── seletor_foto_perfil.dart - Seletor nativo de foto de perfil recortada 256x256 em Data URI base64
│   │   ├── caderneta/
│   │   │   ├── repositorio_caderneta.dart - Repositório reativo de cadenas e perfil do escalador
│   │   │   ├── armazenamento_local_caderneta.dart - Persistência local em SharedPreferences
│   │   │   ├── compilador_estatisticas.dart - Cálculo de pirâmide de graus e recordes
│   │   │   └── catalogo_vias_caderneta.dart - Hidratação de nomes, graus e picos via SQLite e memória
│   │   ├── catalogo/
│   │   │   └── repositorio_catalogo.dart - Banco SQLite local (catalogo.db), batch delta sync e consultas relacionais
│   │   ├── compartilhamento/
│   │   │   └── servico_compartilhamento.dart - Formatação de links compactos aresta.cc (/s/<uid>, /sm/<uid>) e share_plus
│   │   ├── firebase/
│   │   │   ├── inicializar_firebase.dart - Inicialização e captura de Crashlytics
│   │   │   ├── telemetria.dart          - Isolamento do Analytics
│   │   │   ├── remote_config.dart       - Fallbacks (incluindo URL e chave pública do Supabase), cache local e degradação offline
│   │   │   ├── validador_app.dart       - Atestação de integridade via App Check resiliente a quedas de rede
│   │   │   └── app_logger.dart          - Logger centralizado com filtro de falhas transitórias HTTP e Firebase
│   │   ├── http/
│   │   │   ├── cliente_http_aresta.dart - Pool compartilhado de conexões HTTP Keep-Alive
│   │   │   ├── sync_service.dart        - Orquestra download, validação e sincronização assíncrona do catálogo
│   │   │   ├── sync_isolate.dart        - Processa downloads e cálculos em background thread
│   │   │   ├── sync_rede.dart           - Faz o download HTTP bruto, consulta /sync do catálogo e gestão de ETags
│   │   │   ├── sync_armazenamento.dart  - Trata arquivos `.tmp` e salva de forma atômica
│   │   │   └── baixador_atualizacoes.dart - Verificação e download de atualizações do APK
│   │   ├── feedback/
│   │   │   ├── background_worker.dart   - Worker (Workmanager) de envio para o Supabase
│   │   │   ├── feedback_metadata_collector.dart - Coleta diagnóstico do aparelho (RAM, bateria, logs)
│   │   │   └── feedback_queue_service.dart - Fila local persistente (SharedPreferences)
│   │   ├── repositorio_dataset.dart     - Estado central: downloads e metadados
│   │   └── editor_croqui.dart           - Contexto de modo experimental e Live Reload
│   └── widgets/
│       ├── bottom_sheets/               - Painéis flutuantes (Regras, Mapas) de ativação interativa
│       ├── caderneta/                   - Modal de registro de cadena, pirâmide de graus e cards estatísticos
│       ├── perfil/
│       │   └── dialogos_hub_perfil.dart - Diálogos de edição de perfil/foto, dados/privacidade e confirmação de saída
│       ├── feedback/
│       │   └── construtor_feedback_usuario.dart - Construtor de interface customizada para formulário de in-app feedback
│       ├── card_pico.dart               - Card interativo do pico com status, progresso de download e estatísticas
│       ├── pico_menu_card.dart          - Card estilizado base para botões da página raiz do Pico
│       ├── busca_global.dart            - Busca global Fuzzy sobre catalogo.db com prioridade e badge Offline
│       └── mapa_thumbnail.dart          - Preview interativo de mapa com resolução offline
└── test/
    ├── architecture/                    - Testes arquiteturais e de convenção de código
    ├── data/                            - Testes de modelos de domínio (PerfilEscalador, Cadena, FeedbackMetadata)
    ├── integration/                     - Testes de integração de fluxos completos (download, leitura, etc)
    ├── legal/                           - Testes para validação e extração de datas de documentos legais
    ├── navigation/                      - Testes unitários da árvore de navegação, loops e reatividade
    ├── pages/                           - Testes de widget das páginas de roteamento superior
    ├── protobuf/                        - Testes de serialização/desserialização dos objetos Protobuf
    ├── services/                        - Testes unitários dos serviços principais (Autenticacao, Midia, Caderneta, SyncService, etc)
    ├── theme/                           - Testes unitários do gerenciamento de temas e persistência
    ├── view/                            - Testes unitários da camada de apresentação
    │   ├── function_library/            - Testes de funções utilitárias e builders de tela
    │   └── view_models/                 - Testes de modelos de apresentação e gerenciamento de estado
    └── widgets/                         - Testes de widget da interface do usuário
```

---

## Como Começar

```bash
# Instalar dependências
flutter pub get

# Rodar em modo de desenvolvimento
flutter run

# Rodar em modo de desenvolvimento com Perfil e Caderneta habilitados
flutter run --dart-define=HABILITAR_PERFIL=true

# Rodar a suíte de testes
flutter test

# Rodar apenas uma pasta de testes
flutter test test/services/
flutter test test/navigation/
flutter test test/integration/
```

> **Pré-requisito:** Flutter SDK instalado e configurado. Consulte [flutter.dev](https://flutter.dev/docs/get-started/install) para instruções de instalação.

---

## Build e Release (Android & iOS)

O projeto está configurado para gerar as versões finais assinadas (`.aab` para Google Play e `.ipa` para App Store) e enviar automaticamente os símbolos de depuração para o Firebase Crashlytics via CI/CD.

### Segredos do Repositório (GitHub Actions Secrets)
Para que o pipeline automatizado (`release_new_app_version.yml`) compile, assine e envie os relatórios de crash desofuscados, configure os seguintes secrets no GitHub:

| Secret | Finalidade |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Arquivo Keystore `.jks` do Android em Base64 |
| `ANDROID_KEY_ALIAS` | Alias da chave de assinatura do Android |
| `ANDROID_KEY_PASSWORD` / `ANDROID_STORE_PASSWORD` | Senhas da chave e do Keystore |
| `ANDROID_PLAY_STORE_CONFIG_JSON` | Service Account JSON da Google Play Console |
| `IOS_BUILD_CERTIFICATE_BASE64` | Certificado de Distribuição Apple (`.p12`) em Base64 |
| `IOS_BUILD_CERTIFICATE_PASSWORD` | Senha do certificado `.p12` |
| `IOS_MOBILE_PROVISIONING_PROFILE_BASE64` | Provisioning Profile (`.mobileprovision`) em Base64 |
| `APPSTORE_KEY_ID` / `APPSTORE_ISSUER_ID` / `APPSTORE_PRIVATE_KEY` | Chave API da App Store Connect (`.p8`) |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Service Account JSON do Google Cloud com role `Firebase Crashlytics Admin` para upload de `dSYMs` e `.symbols` |

### Otimizações de Compilação e Google Play Vitals
O Aresta implementa as melhores práticas recomendadas para Android Vitals e App Store:
- **Gestão de Memória e Bitmaps:** Teto global de 100 MB para o `imageCache` (via `configurarGestaoMemoria()`) e decodificação com downsampling via `ResizeImage.resizeIfNeeded` no `ProvedorImagemAresta` e `_CragBackgroundWidget` (restringindo o uso de RAM por miniatura a ~160 KB).
- **R8 e Minificação (Android):** `isMinifyEnabled` e `isShrinkResources` ativados com `proguard-android-optimize.txt` e `proguard-rules.pro`, reduzindo o DEX e tamanho do AAB em mais de 25%.
- **ThinLTO e Dead Code Stripping (iOS):** Otimizações inter-módulos ativadas no Clang via `Release.xcconfig`.
- **Ofuscação de Código Dart:** Flags `--obfuscate --split-debug-info=build/symbols` aplicadas nos builds de release com upload automático de `mapping.txt`, `.symbols` e `dSYMs` para o Firebase Crashlytics e Google Play Console.

### Fluxo de Release Automatizado (GitHub Actions)
O lançamento de novas versões para as lojas de aplicativo é realizado através do workflow unificado [`.github/workflows/release_new_app_version.yml`](../.github/workflows/release_new_app_version.yml) via disparo manual (**workflow_dispatch**):

| Parâmetro | Tipo | Padrão | Descrição |
|---|---|---|---|
| `bump_type` | `choice` | `patch` | Tipo de incremento semântico: `patch`, `minor`, `major` ou `custom`. |
| `custom_version` | `string` | *(vazio)* | Versão explícita (obrigatória apenas se `bump_type` for `custom`, ex: `1.0.0`). |
| `deploy_android` | `boolean` | `true` | Se verdadeiro, executa build do AAB e publicação na Google Play Store. |
| `deploy_ios` | `boolean` | `true` | Se verdadeiro, executa build do IPA e publicação na Apple App Store / TestFlight. |

#### Ciclo Contínuo de Desenvolvimento (`-dev`)
O repositório adota a convenção de que a branch `main` sempre aponta para a versão do **próximo patch planejado** com o sufixo `-dev`:
- Quando a versão atual for `0.2.5-dev+67` e um release `patch` for disparado, o pipeline lança `0.2.5+68`, cria a tag `v0.2.5+68` e comita automaticamente o início do próximo ciclo dev em `main` como `0.2.6-dev+69`.
- Se um incremento `minor` for selecionado, a versão lançada será `0.3.0+68` e o ciclo seguinte em `main` iniciará em `0.3.1-dev+69`.
- Se um incremento `major` for selecionado, a versão lançada será `1.0.0+68` e o ciclo seguinte em `main` iniciará em `1.0.1-dev+69`.

As ferramentas de cálculo e manipulação de versão estão centralizadas e testadas em `frontend/tool/release_tools/`:
```bash
# Calcular versão de lançamento:
dart run tool/release_tools/calcular_versao_release.dart --tipo patch

# Calcular próximo ciclo dev:
dart run tool/release_tools/calcular_proximo_dev.dart 0.2.5 --build 68

# Atualizar o pubspec.yaml:
dart run tool/release_tools/atualizar_versao_pubspec.dart pubspec.yaml 0.2.5-dev+67
```

### Artefatos de Release no GitHub Actions
A cada release gerada pelos workflows `build_android.yml` e `build_ios.yml`, um pacote `.zip` completo contendo os binários (`.aab` / `.ipa`), tabelas de símbolos Dart (`.symbols`), dSYMs do Xcode e arquivos de mapeamento R8/ProGuard é armazenado na aba **Actions** do GitHub (com retenção de 90 dias).

### Build Local
Se precisar gerar o `.aab` na sua própria máquina, você **não** deve utilizar o arquivo `key.properties` (por segurança). O arquivo `build.gradle.kts` foi configurado para ler diretamente as Variáveis de Ambiente do Sistema Operacional.

No PowerShell, defina as variáveis temporariamente em memória e rode o build:
```powershell
$env:KEY_ALIAS='seu_alias'
$env:STORE_FILE='caminho\absoluto\upload-keystore.jks'
$env:KEY_PASSWORD='sua_senha'
$env:STORE_PASSWORD='sua_senha'

flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```
> **Nota:** Use aspas simples (`' '`) no PowerShell caso sua senha contenha caracteres especiais como `$`.

O pacote gerado estará em: `build\app\outputs\bundle\release\app-release.aab`

---

## Documentação

| Documento | Conteúdo |
|---|---|
| [`lib/README.md`](lib/README.md) | Arquitetura completa: serviços, páginas, funções e widgets |
| [`lib/view/README.md`](lib/view/README.md) | Camada de apresentação: separação entre `function_library` e `view_models` |
| [`lib/navigation/README.md`](lib/navigation/README.md) | Estrutura e API do sistema de navegação baseada em árvore com Hot-Reload (Tree Navigation) |
| [`lib/services/README.md`](lib/services/README.md) | Serviços centrais, autenticação Supabase, Modo Experimental e isolamento de dados |
| [`lib/services/caderneta/README.md`](lib/services/caderneta/README.md) | Caderneta esportiva, estatísticas e sincronização de perfil |
| [`lib/services/firebase/README.md`](lib/services/firebase/README.md) | Isolamento e integração com Firebase (Analytics, Crashlytics, Remote Config) |
| [`test/README.md`](test/README.md) | Estrutura dos testes, como executar e convenções adotadas |
| [`test/navigation/README.md`](test/navigation/README.md) | Cobertura dos testes da árvore de navegação e validação de prevenção de loops |

---

## Licença e Contribuição

- **Código-Fonte**: Licenciado sob a [Mozilla Public License 2.0 (MPL 2.0)](../LICENSE).
- **Diretrizes de Contribuição**: Adotamos o Developer Certificate of Origin (DCO com `git commit -s`). Veja detalhes em [CONTRIBUTING.md](../CONTRIBUTING.md).
