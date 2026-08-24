import '../services/firebase/remote_config_service.dart';

/// Constantes globais de rede e servidores do Aresta Climb.
class NetworkConstants {
  /// Versão atual dos dados embutidos. Alterar isso forçará um hard update em aparelhos atualizados.
  static const int kDataVersion = 4;

  /// Retorna a URL combinada do servidor de dados com a versão atual (lida dinamicamente do Remote Config).
  static String get officialServerUrl =>
      '${RemoteConfigService.instance.servingBaseUrl}/v$kDataVersion';

  /// Retorna a URL do endpoint de feedback (lida dinamicamente do Remote Config).
  static String get feedbackEdgeFunctionUrl =>
      RemoteConfigService.instance.feedbackEdgeFunctionUrl;
}
