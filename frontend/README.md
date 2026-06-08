# Aresta Climb App — Frontend

Aplicativo Flutter para Android e iOS. Guia de escalada offline com suporte a croquis, mapas GPS e sincronização de repositórios.

---

## Funcionalidades

- **Home**: Carrossel dos guias baixados, ordenados por acesso recente, com **Busca Global Integrada** (Fuzzy Search e accent-insensitive) para navegação rápida entre setores e vias de todos os crags.
- **Explorar**: Lista todos os picos disponíveis no índice remoto com thumbnails e download paralelo.
- **GPS / Mapa Interativo**: Visualização de mapas de setores e picos com overlay interativo e navegação hierárquica.
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
| **`flutter_markdown`** | `^0.7.7+1` | Renderização de betas e descrições em Markdown |
| **`mobile_scanner`** | `^7.2.0` | Leitura de QR codes para importação de repositórios |
| **`file_picker`** | `^11.0.2` | Seleção de arquivos `.croqui` no dispositivo |
| **`crypto`** | `any` | Checksums SHA-256 para validação de arquivos na sync |

---

## Estrutura do Projeto

```
frontend/
├── firebase.json              Configuração do FlutterFire CLI
├── firebase_telemetry_design.md Documentação de design da telemetria
├── legal/
│   └── repo/                  Submodule Git com os Termos de Uso e Política de Privacidade (.md)
├── tool/
│   └── legal_updater/         Ferramenta de linha de comando para atualizar as constantes de data legal
├── lib/
│   ├── main.dart          Ponto de entrada: bindings, serviços e navegação principal
│   ├── firebase_options.dart Configurações geradas pelo FlutterFire
│   ├── constants/
│   │   └── legal_version.g.dart Constante de data autogerada da última atualização legal
│   ├── view_functions/    Builders de UI, callbacks e funções por página
│   │   ├── common_functions.dart     Sistema de design (paletas, tipografia, componentes base)
│   │   ├── offline_markdown.dart     Visualizador Markdown com FileImage offline
│   │   ├── settings_functions.dart   Importação de .croqui, QR code, conexão com editor
│   │   └── *_functions.dart          Funções específicas por página (home, browse, pico, …)
│   ├── aresta_api/          Submodule: arquivos .proto e código Protobuf gerado
│   ├── navigation/        Estrutura de navegação baseada em árvore (Tree Navigation)
│   │   ├── README.md                 Detalhamento da arquitetura de navegação sem pilha
│   │   ├── navigation_functions.dart API estática AppNav com herança de contexto
│   │   └── navigation_tree.dart      Classes dos nós (NavNode) e controlador central
│   ├── pages/             Páginas do app
│   │   ├── home.dart              Carrossel e lista de guias locais
│   │   ├── browse.dart            Índice remoto com download inline
│   │   ├── gps.dart               Entrada do mapa
│   │   ├── mapa_interativo.dart   Mapa interativo com overlay de setores/vias
│   │   ├── mapa_geral_pico.dart   Mapa contendo o overview de todos os setores do pico
│   │   ├── pico.dart              Nó raiz de um guia
│   │   ├── grupo.dart             Agrupamento de setores
│   │   ├── setor.dart             Subárea com lista de vias ou boulders
│   │   ├── via.dart               Nó folha: beta, croqui e imagens
│   │   ├── settings.dart          Configurações e ferramentas de editor
│   │   ├── terms_of_use.dart      Visualizador dos documentos legais
│   │   └── qr_scanner.dart        Scanner de QR code
│   ├── services/          Serviços centrais
│   │   ├── firebase/
│   │   │   ├── init_firebase.dart        Inicialização e captura de Crashlytics
│   │   │   ├── telemetry_service.dart    Isolamento do Analytics
│   │   │   ├── remote_config_service.dart Fallbacks e cache local
│   │   │   └── app_logger.dart           Logger de eventos local (debug)
│   │   ├── http/
│   │   │   ├── sync_service.dart             Orquestra download e validação
│   │   │   ├── sync_network.dart             Faz o download HTTP bruto
│   │   │   ├── sync_storage.dart             Trata arquivos `.tmp` e salva modo atômico
│   │   │   ├── zip_interceptor_client.dart   Ghost Protocol: intercepta aresta-zip://
│   │   │   └── update_downloader.dart        Verificação e download de atualizações do APK
│   │   ├── dataset_repository.dart       Estado central: downloads e metadados
│   │   └── editor_croqui.dart            Contexto de modo e temporizador experimental
│   └── widgets/
│       ├── global_search.dart Busca global agregada de todos os croquis baixados
│       └── mapa_thumbnail.dart    Preview interativo de mapa com resolução offline
└── test/
    ├── services/      Testes unitários: ZipInterceptor, DatasetRepository, EditorDeCroqui, …
    ├── view_functions/ Testes de funções utilitárias (common_functions)
    ├── navigation/    Testes de unidade da navegação em árvore (com testes de prevenção de loops)
    ├── protobuf/      Testes de serialização/desserialização dos objetos Protobuf
    ├── integration/   Testes de fluxo completo: aresta-zip → parse → disco
    └── widgets/       Testes de widget da interface (mapa interativo, navegação)
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
| [`lib/navigation/README.md`](lib/navigation/README.md) | Estrutura e API do sistema de navegação baseada em árvore (Tree Navigation) |
| [`lib/services/README.md`](lib/services/README.md) | Ghost Protocol, Modo Experimental, ciclo de vida de importação e isolamento de dados |
| [`lib/services/firebase/README.md`](lib/services/firebase/README.md) | Isolamento e integração com Firebase (Analytics, Crashlytics, Remote Config) |
| [`test/README.md`](test/README.md) | Estrutura dos testes, como executar e convenções adotadas |
| [`test/navigation/README.md`](test/navigation/README.md) | Cobertura dos testes da árvore de navegação e validação de loop prevention |
