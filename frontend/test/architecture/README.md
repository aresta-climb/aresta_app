# Testes Arquiteturais - Aresta Climb

Este diretório (`test/architecture/`) contém testes automatizados que garantem a conformidade arquitetural e os limites de isolamento entre camadas do aplicativo.

## Testes Existentes

### 1. `isolamento_logs_arquitetura_test.dart`
Garante que nenhuma chamada direta a `print()` ou `debugPrint()` exista no código-fonte dentro de `lib/`, com exceção de `lib/services/firebase/app_logger.dart`.
- Toda mensagem informativa deve utilizar `AppLogger.instance.logInfo`.
- Todo aviso operacional deve utilizar `AppLogger.instance.logAviso`.
- Todo tratamento de erro operacional deve capturar `(e, stackTrace)` e enviar ao `AppLogger.instance.logError(..., error: e, stackTrace: stackTrace)`.
- Falhas críticas de integridade devem usar `AppLogger.instance.logCrash`.
- Falhas de download/sincronização devem usar `AppLogger.instance.logFalhaSyncOuDownload`.

### 2. `firebase_isolation_test.dart`
Garante que nenhum arquivo fora de `lib/services/firebase/` importe diretamente pacotes do Firebase (`firebase_core`, `firebase_crashlytics`, `firebase_analytics`, etc.).
Isso previne vazamento de abstração e acoplamento indevido da camada de apresentação ou de domínio aos SDKs de terceiros.

### 3. `path_drawing_isolation_test.dart`
Fiscaliza o isolamento de dependências de renderização vetorial e desenho de trajetos.

### 4. `android_manifest_test.dart`
Valida integridade estrutural e permissões exigidas no `AndroidManifest.xml`.

### 5. `isolamento_cliente_http_test.dart`
Garante o isolamento arquitetural de conexões HTTP em todo o código de produção (`lib/`):
- Proíbe `import 'package:http/...` e referências a `http.Client`, `IOClient(` ou `HttpClient(` fora de `lib/services/http/cliente_http_aresta.dart`.
- Proíbe o uso de `ClienteHttpAresta.paraTestes` dentro de `lib/`.
- Proíbe chamadas a `.close()` em clientes HTTP para preservar o pool persistente de conexões Keep-Alive.

### 6. `isolamento_mvvm_modulos_test.dart`
Fiscaliza a arquitetura limpa, modularidade e padrão **MVVM (Dumb UI)**:
- Garante que páginas e widgets declarativos (`login`, `caderneta`, `hub_perfil_caderneta`, `via`, `widgets/autenticacao`, `widgets/caderneta`, `widgets/perfil`, `widgets/via` e bibliotecas visuais associadas) jamais importem `services/` diretamente.
- Garante que modelos de domínio em `lib/data/modelos/` permaneçam puros, sem acoplamento com `services/`, `view/`, `widgets/` ou `pages/`.
- Garante espelhamento `1:1` obrigatório de `_test.dart` e limites modulares de responsabilidade única (`< 650` linhas por arquivo).


