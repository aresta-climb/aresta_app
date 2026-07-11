# Aresta Climb App — Frontend

Aplicativo Flutter para Android e iOS. Guia de escalada offline com suporte a croquis, mapas GPS e sincronização de repositórios.

---

## Funcionalidades

- **Sincronização Atômica & Background Isolates**: Downloads de croquis e atualizações funcionam em plano de fundo via Isolates, processando criptografia SHA256 e validação de arquivos Delta-Sync em paralelo, sem travar a interface de usuário. Feedback de progresso granular via barras lineares (`LinearProgressIndicator`).
- **Compartilhamento P2P Offline**: Módulo de rede descentralizada (Peer-to-Peer) via Wi-Fi Direct e Bluetooth LE. Permite a transferência direta e incrivelmente rápida de guias de escalada inteiros (centenas de megabytes de imagens e metadados) entre os aparelhos de escaladores na base da montanha, de forma 100% offline, sem depender de qualquer torre de celular.
- **Home**: Carrossel dos guias baixados, ordenados por acesso recente, com **Busca Global Integrada** (Fuzzy Search e accent-insensitive) para navegação rápida entre setores e vias de todos os crags.
- **Explorar**: Lista todos os picos disponíveis no índice remoto com thumbnails e download paralelo (via nuvem ou via rede P2P próxima), além do **Mapão Global**, que projeta todos os picos do índice em um mapa-múndi 2D interativo.
- **GPS / Mapas em Carrossel**: Visualização horizontal contínua de múltiplos mapas de setores e picos com overlay interativo e navegação hierárquica fluida entre áreas e subsetores (Carousel).
- **Leitura Offline**: Textos, imagens e betas funcionam sem conexão após o primeiro download.
- **Ghost Protocol (`aresta-zip://`)**: Arquivos `.croqui` locais são tratados como servidores HTTP internos — o mesmo pipeline de rede serve dados remotos e locais sem ramificações no código.
- **Modo Experimental** _(oculto)_: Ferramentas para editores importarem repositórios em desenvolvimento. Acesso via Easter Egg nas Configurações (7 toques no ícone de status). Dados se auto-destroem após 20 minutos.
- **Importação via QR Code**: Escaneia um QR code para conectar a um servidor de editor remoto ou baixar um `.croqui`.
- **Atualização de APK**: Verifica e baixa atualizações do aplicativo em segundo plano.

---

## Tecnologias

| Dependência | Versão | Uso |
|---|---|---|
| **Flutter / Dart** | SDK `^3.11.3` | Framework principal (cross-platform: Android, iOS) |
| **`protobuf`** | `^6.0.0` | Serialização binária de dados de escalada (`.binarypb`) |
| **`http`** | `^1.2.0` | Camada de rede; estendido pelo `ZipInterceptorClient` |
| **`archive`** | `^4.0.9` | Extração de arquivos `.croqui` (ZIP com ofuscação XOR) |
| **`path_provider`** | `^2.1.2` | Resolução de diretórios de armazenamento local |
| **`shared_preferences`** | `^2.2.2` | Persistência leve de configurações |
| **`fuzzy`** | `^0.5.1` | Busca textual aproximada (Fuzzy Search) para a pesquisa global |
| **`google_maps_flutter`**| `^2.5.3` | Renderização nativa e otimizada de mapas e geolocalização do Mapão Global |
| **`flutter_markdown`** | `^0.7.7+1` | Renderização de betas e descrições em Markdown |
| **`mobile_scanner`** | `^7.2.0` | Leitura de QR codes para importação de repositórios |
| **`flutter_nearby_connections`** | `^2.1.2` | Malha P2P offline via Wi-Fi Direct e Bluetooth LE para transferência local |
| **`file_picker`** | `^11.0.2` | Seleção de arquivos `.croqui` no dispositivo |
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
│   │   └── markdown_utils.dart          - Funções utilitárias para parseamento de strings Markdown
│   ├── view_functions/                  - Builders de UI, callbacks e funções por página
│   │   ├── common_functions.dart        - Sistema de design (paletas, tipografia, componentes base)
│   │   ├── offline_markdown.dart        - Visualizador Markdown com FileImage offline
│   │   ├── settings_functions.dart      - Importação de .croqui, QR code, conexão com editor
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
│   │   ├── pico.dart                    - Nó raiz de um guia
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
│   │   │   ├── zip_interceptor_client.dart - Ghost Protocol: intercepta aresta-zip://
│   │   │   └── update_downloader.dart   - Verificação e download de atualizações do APK
│   │   ├── p2p/
│   │   │   ├── ambient_p2p_service.dart - Singleton gerenciador do Wi-Fi Direct e Discovery local
│   │   │   └── p2p_transfer_manager.dart- Empacotador e transferidor de arquivos base64 via P2P
│   │   ├── feedback/
│   │   │   ├── background_worker.dart   - Worker (Workmanager) de envio para o Supabase
│   │   │   ├── feedback_metadata_collector.dart - Coleta diagnóstico do aparelho (RAM, bateria, logs)
│   │   │   └── feedback_queue_service.dart - Fila local persistente (SharedPreferences)
│   │   ├── dataset_repository.dart      - Estado central: downloads e metadados
│   │   └── editor_croqui.dart           - Contexto de modo e temporizador experimental
│   └── widgets/
│       ├── feedback/
│       │   └── custom_feedback_builder.dart - Construtor de interface customizada para formulário de in-app feedback
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

## Build e Release (Android)

O projeto está configurado para gerar a versão final (`.aab` assinado) para a Play Store de forma segura, sem expor senhas no repositório.

### Via GitHub Actions (Recomendado)
A integração contínua (CI/CD) foi configurada no `.github/workflows/build_android.yml`. Ao fazer push para a branch `main` ou engatilhar manualmente via `workflow_dispatch`, o GitHub Actions lerá os seguintes **Secrets do Repositório** para assinar o app:
- `KEYSTORE_BASE64`: Arquivo `.jks` convertido para texto Base64.
- `KEY_ALIAS`: Alias da chave (ex: `upload`).
- `KEYSTORE_PASSWORD` / `KEY_PASSWORD`: Senhas do Keystore e da chave.

O arquivo final `.aab` ficará disponível para download nos Artifacts do fluxo executado na aba "Actions".

### Build Local
Se precisar gerar o `.aab` na sua própria máquina, você **não** deve utilizar o arquivo `key.properties` (por segurança). O arquivo `build.gradle.kts` foi configurado para ler diretamente as Variáveis de Ambiente do Sistema Operacional.

No PowerShell, defina as variáveis temporariamente em memória e rode o build:
```powershell
$env:KEY_ALIAS='seu_alias'
$env:STORE_FILE='caminho\absoluto\upload-keystore.jks'
$env:KEY_PASSWORD='sua_senha'
$env:STORE_PASSWORD='sua_senha'

flutter build appbundle --release
```
> **Nota:** Use aspas simples (`' '`) no PowerShell caso sua senha contenha caracteres especiais como `$`.

O pacote gerado estará em: `build\app\outputs\bundle\release\app-release.aab`

---

## Documentação

| Documento | Conteúdo |
|---|---|
| [`lib/README.md`](lib/README.md) | Arquitetura completa: serviços, páginas, funções e widgets |
| [`lib/navigation/README.md`](lib/navigation/README.md) | Estrutura e API do sistema de navegação baseada em árvore com Hot-Reload (Tree Navigation) |
| [`lib/services/README.md`](lib/services/README.md) | Ghost Protocol, Modo Experimental, ciclo de vida de importação e isolamento de dados |
| [`lib/services/firebase/README.md`](lib/services/firebase/README.md) | Isolamento e integração com Firebase (Analytics, Crashlytics, Remote Config) |
| [`test/README.md`](test/README.md) | Estrutura dos testes, como executar e convenções adotadas |
| [`test/navigation/README.md`](test/navigation/README.md) | Cobertura dos testes da árvore de navegação e validação de loop prevention |
