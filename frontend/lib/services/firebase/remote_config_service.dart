import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Serviço responsável por gerenciar o Firebase Remote Config de forma reativa e não-bloqueante.
///
/// O Remote Config permite alterar o comportamento e a aparência do aplicativo
/// sem precisar publicar uma nova atualização nas lojas (App Store/Google Play).
/// É ideal para:
/// - Feature Flags (ativar/desativar novas funcionalidades).
/// - Version Enforcement (bloqueio de versões defasadas ou aviso de atualização).
/// - Mensagens e avisos globais.
///
/// Como o aplicativo adota uma arquitetura estritamente *offline-first*, este serviço:
/// 1. Carrega valores padrão locais imediatamente no dispositivo via [setDefaults].
/// 2. Executa a sincronização de rede em segundo plano (`fetchAndActivate`).
/// 3. Notifica ouvintes registrados via [ChangeNotifier] quando novos parâmetros são baixados.
class RemoteConfigService extends ChangeNotifier {
  RemoteConfigService._privateConstructor();

  /// Instância singleton global mutável para permitir injeção de dependência/mocks nos testes.
  static RemoteConfigService instance =
      RemoteConfigService._privateConstructor();

  @visibleForTesting
  FirebaseRemoteConfig? debugRemoteConfig;

  FirebaseRemoteConfig get _remoteConfig =>
      debugRemoteConfig ?? FirebaseRemoteConfig.instance;

  Future<void>? _initFuture;

  @visibleForTesting
  void clearInitFuture() => _initFuture = null;

  /// Inicializa o serviço definindo os padrões (defaults) e buscando atualizações em segundo plano.
  ///
  /// Retorna um [Future] que conclui após a definição dos defaults e tentativa de fetch.
  Future<void> initialize() {
    _initFuture ??= _initializeInternal();
    return _initFuture!;
  }

  /// Executa o fluxo interno de inicialização e sincronização com o Firebase Remote Config.
  Future<void> _initializeInternal() async {
    try {
      // 1. Define os padrões locais seguros para garantir funcionamento offline imediato
      await _remoteConfig.setDefaults(const {
        "recommended_version": 0,
        "soft_min_version": 0,
        "hard_min_version": 0,
        "store_url_ios": "",
        "feedback_edge_function_url":
            "https://gawgqiqzptckwghgqypt.supabase.co/functions/v1/app-feedback",
        "serving_base_url": "https://serving.arestaclimb.com",
      });

      // 2. Define o timeout e o intervalo padrão de cache (12 horas) para evitar requisições repetitivas a frio
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 12),
        ),
      );

      // 3. Tenta buscar e ativar novas configurações do servidor
      final updated = await _remoteConfig.fetchAndActivate();

      if (kDebugMode) {
        print('🔧 [RemoteConfig] Configuração atualizada com sucesso (novo valor: $updated).');
      }

      // 4. Notifica widgets ouvintes para atualizarem seu estado reativamente
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print(
          '🔧 [RemoteConfig] Falha ao atualizar (offline/timeout). Usando cache e defaults. Erro: $e',
        );
      }
    }
  }

  /// Retorna um valor booleano do Remote Config ou [false] em caso de erro.
  bool getBool(String key) {
    try {
      return _remoteConfig.getBool(key);
    } catch (_) {
      return false;
    }
  }

  /// Retorna um valor inteiro do Remote Config ou `0` em caso de erro.
  int getInt(String key) {
    try {
      return _remoteConfig.getInt(key);
    } catch (_) {
      return 0;
    }
  }

  /// Retorna uma string do Remote Config ou `""` em caso de erro.
  String getString(String key) {
    try {
      return _remoteConfig.getString(key);
    } catch (_) {
      return "";
    }
  }

  // ===========================================================================
  // GETTERS TIPADOS (FEATURE FLAGS & VERSÕES)
  // ===========================================================================

  /// Versão recomendada para apresentar banner leve azul.
  int get recommendedVersion => getInt('recommended_version');

  /// Versão mínima para apresentar banner fixo laranja e bloquear downloads (soft block).
  int get softMinVersion => getInt('soft_min_version');

  /// Versão mínima absoluta para o app funcionar (bloqueia o app com tela vermelha).
  int get hardMinVersion => getInt('hard_min_version');

  /// URL personalizada para a loja de aplicativos no iOS (útil para beta fechado/TestFlight).
  String get storeUrlIos => getString('store_url_ios');

  /// URL do endpoint seguro de feedback do aplicativo (Edge Function Supabase).
  String get feedbackEdgeFunctionUrl => getString('feedback_edge_function_url');

  /// URL base do servidor de dados de escalada (Cloudflare Serving).
  String get servingBaseUrl => getString('serving_base_url');
}
