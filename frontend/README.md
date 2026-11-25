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
│   ├── main.dart                        - Inicialização e montagem do aplicativo
│   ├── aresta_api/                      - Submódulo Protobuf (.proto e código gerado)
│   ├── application_managers/            - Orquestração de feedback e migrações
│   ├── constants/                       - Constantes de rede e versão legal gerada
│   ├── data/modelos/                    - Modelos locais (PerfilEscalador, Cadena, AlertaSegurancaVia, ItemFilaInteracao, etc.)
│   ├── navigation/                      - Árvore de navegação (NavNode, AppNav, deep links, PageListenableBuilder)
│   ├── pages/                           - Telas do aplicativo e subpáginas do pico
│   ├── services/                        - Repositórios, HTTP/Sync, autenticação, mídia, caderneta, comunidade, catálogo e Firebase
│   ├── theme/                           - Paleta de cores (AppColors) e temas claro/escuro
│   ├── utils/                           - Geometria vetorial, formatação de graus, filtros, UIDs e consultas no dataset
│   ├── view/
│   │   ├── function_library/            - Construtores declarativos de UI por tela
│   │   └── view_models/                 - ViewModels reativos (ChangeNotifier)
│   └── widgets/                         - Componentes reutilizáveis (navegação, via, caderneta, perfil, login, imagens, modais)
└── test/                                - Testes unitários, de widget, de integração, arquiteturais e de caos
```

---

## Execução e Testes

```bash
# Instalar dependências
flutter pub get

# Executar em modo de desenvolvimento
flutter run

# Executar com Perfil, Caderneta e Interações habilitados
flutter run --dart-define=HABILITAR_PERFIL=true

# Executar todos os testes
flutter test

# Executar uma pasta específica
flutter test test/services/
flutter test test/navigation/
flutter test test/widgets/
```

---

## Build e Release (Android e iOS)

O pipeline gera os artefatos assinados (`.aab` para Google Play e `.ipa` para App Store) e envia símbolos de depuração ao Firebase Crashlytics via GitHub Actions.

### Secrets do GitHub Actions

| Secret | Finalidade |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Keystore `.jks` do Android em Base64 |
| `ANDROID_KEY_ALIAS` | Alias da chave de assinatura Android |
| `ANDROID_KEY_PASSWORD` / `ANDROID_STORE_PASSWORD` | Senhas da chave e do Keystore |
| `ANDROID_PLAY_STORE_CONFIG_JSON` | Service Account JSON da Google Play Console |
| `IOS_BUILD_CERTIFICATE_BASE64` | Certificado de distribuição Apple (`.p12`) em Base64 |
| `IOS_BUILD_CERTIFICATE_PASSWORD` | Senha do certificado `.p12` |
| `IOS_MOBILE_PROVISIONING_PROFILE_BASE64` | Provisioning Profile (`.mobileprovision`) em Base64 |
| `APPSTORE_KEY_ID` / `APPSTORE_ISSUER_ID` / `APPSTORE_PRIVATE_KEY` | Chave da API App Store Connect (`.p8`) |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Service Account com permissão `Firebase Crashlytics Admin` |

### Configurações de Release
- **Memória de Imagens**: Limite de `imageCache` ajustado por faixa de RAM (`configurarGestaoMemoria()`) e decodificação redimensionada com `ResizeImage.resizeIfNeeded` em `ProvedorImagemAresta`.
- **Android (R8)**: `isMinifyEnabled` e `isShrinkResources` ativos com `proguard-rules.pro`.
- **iOS**: Otimizações de compilação definidas em `Release.xcconfig`.
- **Ofuscação Dart**: `--obfuscate --split-debug-info=build/symbols` com envio de `mapping.txt`, `.symbols` e `dSYMs`.

### Workflow de Release (`.github/workflows/release_new_app_version.yml`)

Disparado manualmente (`workflow_dispatch`):

| Parâmetro | Tipo | Padrão | Descrição |
|---|---|---|---|
| `bump_type` | `choice` | `patch` | Tipo de incremento: `patch`, `minor`, `major` ou `custom` |
| `custom_version` | `string` | *(vazio)* | Versão manual quando `bump_type` é `custom` |
| `deploy_android` | `boolean` | `true` | Gera `.aab` e publica na Google Play |
| `deploy_ios` | `boolean` | `true` | Gera `.ipa` e publica na App Store / TestFlight |

#### Versionamento `-dev` na `main`
A branch `main` mantém a versão do próximo patch com sufixo `-dev`:
- Exemplo: partindo de `0.2.5-dev+67`, um release `patch` publica `0.2.5+68`, cria a tag `v0.2.5+68` e atualiza `main` para `0.2.6-dev+69`.
- Scripts auxiliares em `frontend/tool/release_tools/`:
  ```bash
  dart run tool/release_tools/calcular_versao_release.dart --tipo patch
  dart run tool/release_tools/calcular_proximo_dev.dart 0.2.5 --build 68
  dart run tool/release_tools/atualizar_versao_pubspec.dart pubspec.yaml 0.2.5-dev+67
  ```

### Build Local Android
`build.gradle.kts` lê as credenciais de variáveis de ambiente (não utilize `key.properties`):

```powershell
$env:KEY_ALIAS='seu_alias'
$env:STORE_FILE='caminho\absoluto\upload-keystore.jks'
$env:KEY_PASSWORD='sua_senha'
$env:STORE_PASSWORD='sua_senha'

flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```
Saída: `build\app\outputs\bundle\release\app-release.aab`.

---

## Documentação Interna

| Documento | Conteúdo |
|---|---|
| [`lib/README.md`](lib/README.md) | Camadas de `lib/` e fluxo de dados |
| [`lib/data/README.md`](lib/data/README.md) | Modelos de domínio locais |
| [`lib/view/README.md`](lib/view/README.md) | `function_library` e `view_models` |
| [`lib/navigation/README.md`](lib/navigation/README.md) | Árvore de navegação e deep links |
| [`lib/pages/README.md`](lib/pages/README.md) | Telas e ciclo de vida |
| [`lib/services/README.md`](lib/services/README.md) | Serviços, autenticação e Modo Experimental |
| [`lib/widgets/README.md`](lib/widgets/README.md) | Componentes visuais compartilhados |
| [`test/README.md`](test/README.md) | Suíte de testes e execução |

---

## Licença e Contribuição

- **Código-Fonte**: [Mozilla Public License 2.0 (MPL 2.0)](../LICENSE).
- **Contribuição**: Developer Certificate of Origin (`git commit -s`). Detalhes em [CONTRIBUTING.md](../CONTRIBUTING.md).
