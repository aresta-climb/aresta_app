# Integração Firebase - Aresta Climb

Este diretório (`lib/services/firebase/`) consolida **absolutamente todos** os contatos da aplicação com os SDKs do Firebase. Essa arquitetura de isolamento foi construída para evitar acoplamento forte da UI com provedores analíticos de terceiros, garantindo que o resto do sistema desconheça a existência do Firebase.

## Testes de Arquitetura (Linter)
Existe um teste unitário (`test/architecture/firebase_isolation_test.dart`) desenhado especificamente para analisar todos os arquivos `.dart` de `lib/`. Ele garantirá que o build/CI falhe caso um desenvolvedor importe qualquer pacote do firebase (ex: `firebase_core`, `firebase_crashlytics`) em um arquivo fora deste diretório.

## Componentes

### 1. `init_firebase.dart`
Ponto central de inicialização. Exporta a função `initFirebase()` que deve ser chamada **somente uma vez** durante a inicialização do app no `main.dart`. 
O que ele faz:
- Chama `Firebase.initializeApp()` injetando as opções de plataforma (geradas pelo flutterfire).
- Captura exceções não-fatais do SDK do Flutter mapeando-as para `recordFlutterFatalError`.
- Captura _Unhandled Exceptions_ em processamento Assíncrono do Dart via `PlatformDispatcher.instance.onError` e as envia como falhas fatais.
- Dá o "Start" no serviço de _Remote Config_.

### 2. `telemetry_service.dart`
Abstração construída em cima do pacote `firebase_analytics`.
Nenhuma tela ou componente no Aresta Climb deve chamar o Firebase Analytics diretamente. Qualquer tela que desejar disparar um evento (ex: "Croqui aberto" ou "Mapa carregado") chamará as funções de contrato bem-definidas do `TelemetryService.instance`.
- **Modo Debug**: Se o app estiver rodando localmente, os eventos serão impressos amigavelmente no Console em vez de inundar o Analytics real.
- **Mocking**: Para testes unitários de funções de tela, usamos um `MockTelemetryService` que substitui essa instância para evitar _crashes_ de inicialização do SDK nativo e validar quais eventos foram requisitados.

### 3. `remote_config_service.dart`
Abstração do `firebase_remote_config`. 
Ele funciona mantendo uma tabela de _feature flags_ ou valores remotos de configuração.
- **Valores Padrão**: Toda flag invocada neste app deve ter um fallback inquebrável caso o dispositivo não tenha internet.
- **Cache**: Valores são armazenados localmente e atualizados com cache para evitar excesso de banda.
- **URLs Dinâmicas**: Permite alterar dinamicamente a URL do endpoint de feedback (`feedback_edge_function_url`) e a URL base do servidor de dados (`serving_base_url`) sem necessidade de nova compilação do app.
- **Como expandir**: Para adicionar uma nova flag, declare-a nos fallbacks internos e crie um _getter_ tipado para a UI ler de forma nativa e simples.

### 4. `app_check_service.dart`
Abstração do `firebase_app_check`.
Responsável pela atestação de integridade de hardware e software da aplicação.
- **Produção (Release)**: Ativa Play Integrity no Android e App Attest no iOS para gerar tokens JWT que comprovam a autenticidade do binário perante o backend Supabase.
- **Desenvolvimento (Debug)**: Utiliza o Provedor de Depuração com suporte a UUIDs cadastrados no Firebase Console, permitindo que os desenvolvedores testem a rota real, ou realiza fallback silencioso em ambiente de desenvolvimento sem bloquear a interface.

### 5. Desofuscação e Símbolos no Crashlytics (CI/CD)
Para que os relatórios de crash no painel do Firebase Crashlytics exibam os nomes de funções, arquivos e linhas de código (ao invés de ponteiros hexadecimais *unsymbolicated*), a pipeline do GitHub Actions realiza o upload automático de dois tipos de símbolos a cada release:
- **dSYMs nativos do iOS**: extraídos do `Runner.xcarchive` gerado pelo Xcode.
- **Símbolos Dart (Android e iOS)**: gerados com a flag `--split-debug-info=build/symbols` do Flutter.

**Autenticação**: O upload é autenticado via Google Cloud Service Account com a role `Firebase Crashlytics Admin`, configurada no repositório GitHub como o segredo `FIREBASE_SERVICE_ACCOUNT_JSON`.
