# Design Técnico: Telemetria e Testes A/B (Firebase) - Aresta Climb

Este documento descreve a arquitetura técnica e o passo a passo para integrar as ferramentas do Firebase (Analytics, Crashlytics e Remote Config) no aplicativo Aresta Climb, garantindo que tudo funcione de maneira robusta em cenários **offline** (sem internet na montanha).

---

## 1. Visão Geral da Arquitetura

Para não acoplar as bibliotecas do Google diretamente nas páginas do Flutter (o que dificulta a manutenção e quebra os testes unitários), criaremos dois serviços dedicados na pasta `lib/services/`:

1. **`TelemetryService`**: Centraliza o rastreamento de uso (Analytics) e captura de erros (Crashlytics).
2. **`RemoteConfigService`**: Centraliza a configuração de Feature Flags e Testes A/B.

Todos os testes de widget e de integração existentes continuarão funcionando, pois usaremos injeção de dependência ou instâncias "Mockadas" (falsas) desses serviços quando o app for compilado em modo de teste (`flutter test`).

---

## 2. Configuração e Dependências

Para iniciar, o arquivo `pubspec.yaml` receberá as dependências oficiais do Firebase:

```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_analytics: ^10.7.4
  firebase_crashlytics: ^3.4.9
  firebase_remote_config: ^4.3.8
```

> [!IMPORTANT]
> ## Requisito Prévio (Console)
> Para que isso funcione, o projeto deve ser criado no [Firebase Console](https://console.firebase.google.com/) usando o Application ID atual do app (`app.escalada.croquis`). O arquivo `google-services.json` deverá ser salvo na pasta `android/app/`.

---

## 3. TelemetryService (Analytics e Crashlytics)

O serviço de telemetria lidará com o monitoramento de uso em campo. Como o Firebase Analytics já faz o cache local SQLite e sincronização offline por conta própria, o nosso serviço será apenas um roteador simples.

### Eventos Customizados Mapeados

Para entregar valor aos provedores de croqui (autores), rastrearemos os seguintes eventos estruturados:

- `open_crag_details`: Disparado quando o usuário entra na tela de um pico.
  - Parâmetros: `crag_id`, `crag_name`.
- `download_croqui`: Disparado no sucesso da extração/sincronização do `.croqui`.
  - Parâmetros: `crag_id`, `source` (github ou aresta-zip).
- `view_route`: Disparado ao abrir a aba de uma via específica.
  - Parâmetros: `crag_id`, `route_name`, `grade`.

### Captura de Erros

Na inicialização do aplicativo (`main.dart`), injetaremos o Crashlytics no motor central do Flutter:

```dart
// Captura erros no framework do Flutter
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

// Captura erros assíncronos não tratados no Dart
PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

---

## 4. RemoteConfigService (A/B Testing e Experimentos)

O `RemoteConfigService` será o responsável por ditar as regras do aplicativo baseadas nas definições da nuvem, mas sempre focando em **não quebrar o modo offline**.

### Valores Padrão (Defaults) Inquebráveis

Qualquer flag de teste A/B deverá ser registrada com um valor padrão hardcoded (direto no código). Isso garante que, no primeiro uso sem internet, o aplicativo não espere infinitamente.

```dart
final remoteConfig = FirebaseRemoteConfig.instance;

// 1. Definimos os defaults locais
await remoteConfig.setDefaults(const {
    "usar_mapa_novo": false,
    "mostrar_banner_doacao": true,
});
```

### Estratégia de Cache e Fetch Offline-First

Para não gastar o plano de dados 4G do escalador nem travar a inicialização do app, configuramos o tempo de cache (Time To Live - TTL) para **12 horas**. 
O app vai buscar dados da nuvem silenciosamente no fundo apenas se a última verificação tiver ocorrido há mais de 12 horas.

```dart
await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(seconds: 10), // Desiste rápido se a internet estiver ruim
    minimumFetchInterval: const Duration(hours: 12), // Usa o cache local por 12 horas
));

// Tenta buscar no fundo sem travar a interface. 
// Se falhar (offline), mantém os valores salvos da última vez (ou os defaults).
remoteConfig.fetchAndActivate().catchError((_) => false);
```

### Uso no Código da UI

Sempre que a interface precisar decidir algo, consultará o serviço localmente:

```dart
bool deveUsarMapaNovo = RemoteConfigService.instance.getBool('usar_mapa_novo');

if (deveUsarMapaNovo) {
  return MapaInterativoNovo();
} else {
  return MapaInterativoLegado();
}
```

---

## 5. Próximos Passos (User Review Required)

> [!TIP]
> ## Open Questions
> Esse é um design conceitual para você entender como a arquitetura sustentará as necessidades offline.
> 
> **Pergunta:** Você gostaria que eu implementasse a Fase 1 (Configuração Básica do Firebase + Crashlytics) agora mesmo no código? 
> Se sim, me envie o conteúdo do arquivo `google-services.json` gerado pelo seu painel do Firebase para que eu possa iniciar as instalações. Caso contrário, você pode guardar esse design para usar como guia no futuro.
