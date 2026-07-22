import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Serviço responsável por gerenciar o Firebase Remote Config.
///
/// O Remote Config permite alterar o comportamento e a aparência do aplicativo
/// sem precisar publicar uma nova atualização nas lojas (App Store/Google Play).
/// É ideal para:
/// - Feature Flags (ativar/desativar novas funcionalidades).
/// - Testes A/B (entregar configurações diferentes para grupos de usuários).
/// - Mensagens de aviso globais.
///
/// ## Como adicionar uma nova flag (Nova Configuração):
/// 1. Adicione a chave e o valor padrão no mapa `setDefaults` dentro do método `initialize()`.
///    Exemplo: `"nova_funcionalidade": false`
/// 2. Crie um novo `getter` tipado no final desta classe para facilitar o acesso na UI.
///    Exemplo: `bool get novaFuncionalidade => getBool('nova_funcionalidade');`
/// 3. No painel do Firebase Console, vá em "Remote Config" e crie um parâmetro com a MESMA chave.
///
/// ## Como usar no código:
/// Acesse a instância global (singleton) do serviço em qualquer lugar:
/// ```dart
/// if (RemoteConfigService.instance.novaFuncionalidade) {
///   // Código da nova funcionalidade
/// }
/// ```
class RemoteConfigService {
  RemoteConfigService._privateConstructor();

  /// Instância singleton global mutável para facilitar injeção de mock nos testes.
  static RemoteConfigService instance =
      RemoteConfigService._privateConstructor();

  @visibleForTesting
  FirebaseRemoteConfig? debugRemoteConfig;

  FirebaseRemoteConfig get _remoteConfig =>
      debugRemoteConfig ?? FirebaseRemoteConfig.instance;

  Future<void>? _initFuture;

  @visibleForTesting
  void clearInitFuture() => _initFuture = null;

  /// Inicializa o serviço definindo os padrões (defaults) e tentando buscar configurações do servidor.
  Future<void> initialize() {
    _initFuture ??= _initializeInternal();
    return _initFuture!;
  }

  Future<void> _initializeInternal() async {
    try {
      // 1. Definimos os defaults inquebráveis locais (fallback para offline)
      await _remoteConfig.setDefaults(const {
        "recommended_version": 0,
        "soft_min_version": 0,
        "hard_min_version": 0,
        "store_url_ios": "",
      });

      // 2. Configurações iniciais com cache ZERO para forçar o download na abertura do app
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: Duration.zero, // Força a buscar da rede
        ),
      );

      // 3. Tenta buscar no fundo sem travar a interface
      await _remoteConfig.fetchAndActivate();

      // 4. Volta o cache para 12 horas para proteger a cota do Firebase caso haja fetches subsequentes
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 12),
        ),
      );

      if (kDebugMode) {
        print('🔧 [RemoteConfig] Configuração atualizada com sucesso.');
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '🔧 [RemoteConfig] Falha ao atualizar (offline?). Usando cache/defaults. Erro: $e',
        );
      }
    }
  }

  /// Retorna um valor booleano do Remote Config.
  bool getBool(String key) {
    try {
      return _remoteConfig.getBool(key);
    } catch (_) {
      return false;
    }
  }

  /// Retorna um valor inteiro do Remote Config.
  int getInt(String key) {
    try {
      return _remoteConfig.getInt(key);
    } catch (_) {
      return 0;
    }
  }

  /// Retorna uma string do Remote Config.
  String getString(String key) {
    try {
      return _remoteConfig.getString(key);
    } catch (_) {
      return "";
    }
  }

  // ===========================================================================
  // GETTERS TIPADOS (FEATURE FLAGS)
  // Adicione novas flags aqui seguindo o padrão abaixo.
  // ===========================================================================

  /// Versão recomendada para apresentar banner leve.
  int get recommendedVersion => getInt('recommended_version');

  /// Versão mínima para apresentar banner fixo e bloquear navegação (soft block).
  int get softMinVersion => getInt('soft_min_version');

  /// Versão mínima absoluta para o app funcionar (bloqueia o app inteiro).
  int get hardMinVersion => getInt('hard_min_version');

  /// URL personalizada para a loja de aplicativos no iOS (útil para beta fechado).
  String get storeUrlIos => getString('store_url_ios');
}
