# Aresta Climb App — Frontend

Aplicativo Flutter para Android e iOS. Guia de escalada offline com suporte a croquis, mapas GPS e sincronização de repositórios.

---

## Funcionalidades

- **Sincronização Atômica & Background Isolates**: Downloads de croquis e atualizações funcionam em plano de fundo via Isolates, processando criptografia SHA256 e validação de arquivos Delta-Sync em paralelo, sem travar a interface de usuário. Feedback de progresso granular via barras lineares (`LinearProgressIndicator`) e gerenciamento de notificações silenciosas em Foreground Service nativo ininterrupto.
- **Home com Busca Global Unificada**: Carrossel dos guias baixados com ordenação por prioridade/acesso recente e barra de busca integrada que realiza Fuzzy Search aproximado (insensível a acentos) em todos os picos, setores e vias da aplicação.
- **Explorar & Sincronização com Serving**: Lista todos os picos do índice remoto com download paralelo, botão de sincronização forçada com o serving ativo e acesso direto ao **Mapão Global**, projetando os crags em um mapa 2D interativo com Google Maps.
- **Croquis Topográficos e Mapas Interativos**:
  - Renderização vetorial nativa de traçados de vias (sólido, tracejado, pontilhado) com hit-testing por distância euclidiana (16dp).
  - Contenção rígida de limites (`boundaryMargin: EdgeInsets.zero`) e zoom mínimo (`minScale: 1.0`) para evitar perda do mapa em telas pretas.
  - Botão de recentralização ergonômico no canto inferior direito com a mesma identidade visual do Mapa Global.
- **Leitura Offline e Streaming Online**: Textos, imagens de alta resolução e betas funcionam 100% offline após o download ou em modo streaming online sob demanda (com guardião de saída para salvar offline).
- **Formatação Padronizada de Graus**: Dificuldades de escalada esportiva, móvel, boulder e multienfiada formatadas no padrão brasileiro com barras diagonais (ex: `7b/7c`, `4º/5º`, `6ºsup/7a`, `10a/10b`).
- **Índice de Escaladas (Catálogo e Filtros)**: Aba dedicada ao catálogo de vias e boulders de cada pico com abas dinâmicas por modalidade existente (`Esportivas`, `Boulders`, `Móveis`, `Multienfiadas`), painel colapsável de filtros rápidos e avançados (grau, setor, autor, clássicas), busca textual em tempo real e atalho direto ao croqui do setor.
- **Créditos e Conquistadores**: Componente `LinhaCreditoAutor` com quebra automática em múltiplas linhas e higienização de placeholders genéricos (`FormatadorCreditos`).
- **Live Reload & Modo Experimental**: Conexão WebSocket e sincronização em tempo real com o Editor Desktop (vida útil de 20 minutos com Nuke automático ao expirar).
- **Importação via QR Code**: Leitura rápida de QR codes para emparelhamento instantâneo com o editor em rede local ou relay.

---

## Tecnologias

| Dependência | Versão | Uso |
|---|---|---|
| **Flutter / Dart** | SDK `^3.11.3` | Framework principal (cross-platform: Android, iOS) |
| **`protobuf`** | `^6.0.0` | Serialização binária de dados de escalada (`.binarypb`) |
| **`http`** | `^1.2.0` | Camada de rede e downloads atômicos |
| **`path_provider`** | `^2.1.2` | Resolução de diretórios de armazenamento local |
| **`shared_preferences`** | `^2.2.2` | Persistência leve de configurações |
| **`fuzzy`** | `^0.5.1` | Busca textual aproximada (Fuzzy Search) para a pesquisa global |
| **`google_maps_flutter`**| `^2.5.3` | Renderização nativa e otimizada de mapas e geolocalização do Mapão Global |
| **`flutter_markdown`** | `^0.7.7+1` | Renderização de betas e descrições em Markdown |
| **`mobile_scanner`** | `^7.2.0` | Leitura de QR codes para conexão com o editor |
| **`crypto`** | `any` | Checksums SHA-256 para validação de arquivos na sync |

---

## Estrutura do Projeto

```text
frontend/
├── firebase.json                        - Configuração do FlutterFire CLI
├── firebase_telemetry_design.md         - Documentação de design da telemetria
├── legal/
│   └── repo/                            - Submodule Git com os Termos de Uso e Política de Privacidade (.md)
├── tool/
│   └── legal_updater/                   - Ferramenta de linha de comando para atualizar as constantes legais
├── lib/
│   ├── main.dart                        - Ponto de entrada: bindings, serviços e navegação principal
│   ├── firebase_options.dart            - Configurações geradas pelo FlutterFire
│   ├── constants/
│   │   └── legal_version.g.dart         - Constante de data autogerada da última atualização legal
│   ├── theme/
│   │   ├── app_colors.dart              - Definição da paleta mestre de cores com suporte a Light/Dark Mode
│   │   └── theme_controller.dart        - Gerenciamento de estado do tema
│   ├── utils/
│   │   ├── markdown_utils.dart          - Funções utilitárias para parseamento de strings Markdown
│   │   └── pico_categorization.dart     - Analisa metadados (tags) e agrupa botões do pico em categorias semânticas
│   ├── view_functions/                  - Builders de UI, callbacks e funções por página
│   │   ├── common_functions.dart        - Sistema de design (paletas, tipografia, componentes base)
│   │   ├── offline_markdown.dart        - Visualizador Markdown com FileImage offline
│   │   ├── settings_functions.dart      - Conexão com Editor Desktop via QR Code/URL, temas e diagnósticos
│   │   ├── mapa/
│   │   │   ├── mapa_global_functions.dart - Funções e visual builders específicos para o mapa mundial
│   │   │   └── mapa_marker.dart        - Renderiza via Canvas o pino (BitmapDescriptor) com o logo no Mapa
│   │   └── *_functions.dart             - Funções específicas por página (home, browse, pico, …)
│   ├── aresta_api/                      - Submodule: arquivos .proto e código Protobuf gerado
│   ├── navigation/                      - Estrutura de navegação baseada em árvore (Tree Nav) e Hot-Reload
│   │   ├── README.md                    - Detalhamento da arquitetura de navegação reativa sem pilha
│   │   ├── navigation_functions.dart    - API estática AppNav com herança de contexto
│   │   ├── navigation_tree.dart         - Classes dos nós baseados em ID (NavNode) e controlador central
│   │   └── page_listenable_builder.dart - O coração do Hot-Reload Reativo (injetor de UI passivo)
│   ├── pages/                           - Páginas do app
│   │   ├── home.dart                    - Carrossel e lista de guias locais
│   │   ├── browse.dart                  - Índice remoto com download inline
│   │   ├── mapa_global.dart            - Visão de mapa global interativa a partir do Explorar
│   │   ├── gps.dart                     - Entrada do mapa
│   │   ├── mapa_interativo.dart         - Mapa interativo com overlay de setores/vias
│   │   ├── mapa_geral_pico.dart         - Mapa contendo o overview de todos os setores do pico
│   │   ├── pico.dart                    - Nó raiz de um guia, atua como hub distribuindo para as sub-páginas
│   │   ├── pico_subpages/               - Views tabulares do guia (Comunidade Local, Setores, Explorar Local, etc)
│   │   ├── comunidade.dart              - Hub global de redes sociais (Discord, WhatsApp, GitHub)
│   │   ├── grupo.dart                   - Agrupamento de setores
│   │   ├── setor.dart                   - Subárea com lista de vias ou boulders
│   │   ├── via.dart                     - Nó folha: beta, croqui e imagens
│   │   ├── settings.dart                - Configurações e ferramentas de editor
│   │   ├── terms_of_use.dart            - Visualizador dos documentos legais
│   │   └── qr_scanner.dart              - Scanner de QR code
│   ├── services/                        - Serviços centrais
│   │   ├── firebase/
│   │   │   ├── init_firebase.dart       - Inicialização e captura de Crashlytics
│   │   │   ├── telemetry_service.dart   - Isolamento do Analytics
│   │   │   ├── remote_config_service.dart - Fallbacks e cache local
│   │   │   └── app_logger.dart          - Logger de eventos local (debug)
│   │   ├── http/
│   │   │   ├── sync_service.dart        - Orquestra download e validação de forma assíncrona
│   │   │   ├── sync_isolate.dart        - Processa downloads e cálculos em background thread
│   │   │   ├── sync_network.dart        - Faz o download HTTP bruto e gestão de ETags
│   │   │   ├── sync_storage.dart        - Trata arquivos `.tmp` e salva de forma atômica
│   │   │   └── update_downloader.dart   - Verificação e download de atualizações do APK
│   │   ├── feedback/
│   │   │   ├── background_worker.dart   - Worker (Workmanager) de envio para o Supabase
│   │   │   ├── feedback_metadata_collector.dart - Coleta diagnóstico do aparelho (RAM, bateria, logs)
│   │   │   └── feedback_queue_service.dart - Fila local persistente (SharedPreferences)
│   │   ├── dataset_repository.dart      - Estado central: downloads e metadados
│   │   └── editor_croqui.dart           - Contexto de modo e temporizador experimental
│   └── widgets/
│       ├── bottom_sheets/               - Painéis flutuantes (Regras, Mapas) de ativação interativa
│       ├── feedback/
│       │   └── custom_feedback_builder.dart - Construtor de interface customizada para formulário de in-app feedback
│       ├── pico_menu_card.dart          - Card estilizado base para botões da página raiz do Pico
│       ├── global_search.dart           - Busca global agregada de todos os croquis baixados
│       └── mapa_thumbnail.dart          - Preview interativo de mapa com resolução offline
└── test/
    ├── architecture/                    - Testes arquiteturais e de convenção de código
    ├── integration/                     - Testes de integração de fluxos completos (download, leitura, etc)
    ├── legal/                           - Testes para validação e extração de datas de documentos legais
    ├── navigation/                      - Testes unitários da árvore de navegação, loops e reatividade
    ├── pages/                           - Testes de widget das páginas de roteamento superior
    ├── protobuf/                        - Testes de serialização/desserialização dos objetos Protobuf
    ├── services/                        - Testes unitários dos serviços principais (SyncService, etc)
    ├── theme/                           - Testes unitários do gerenciamento de temas e persistência
    ├── view_functions/                  - Testes unitários de funções utilitárias compartilhadas
    └── widgets/                         - Testes de widget da interface do usuário
```

---

## Como Começar

```bash
# Instalar dependências
flutter pub get

# Rodar em modo de desenvolvimento
flutter run

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
| [`lib/navigation/README.md`](lib/navigation/README.md) | Estrutura e API do sistema de navegação baseada em árvore com Hot-Reload (Tree Navigation) |
| [`lib/services/README.md`](lib/services/README.md) | Modo Experimental, ciclo de vida de importação e isolamento de dados |
| [`lib/services/firebase/README.md`](lib/services/firebase/README.md) | Isolamento e integração com Firebase (Analytics, Crashlytics, Remote Config) |
| [`test/README.md`](test/README.md) | Estrutura dos testes, como executar e convenções adotadas |
| [`test/navigation/README.md`](test/navigation/README.md) | Cobertura dos testes da árvore de navegação e validação de loop prevention |

---

## Licença e Contribuição

- **Código-Fonte**: Licenciado sob a [Mozilla Public License 2.0 (MPL 2.0)](../LICENSE).
- **Diretrizes de Contribuição**: Adotamos o Developer Certificate of Origin (DCO com `git commit -s`). Veja detalhes em [CONTRIBUTING.md](../CONTRIBUTING.md).
- **Princípios de Engenharia**: Desenvolvimento orientado a testes (TDD), 100% de cobertura e tudo em português brasileiro. Consulte [PRINCIPIOS.md](../PRINCIPIOS.md).


