class NetworkConstants {
  /// Versão atual dos dados embutidos. Alterar isso forçará um hard update em aparelhos atualizados.
  static const int kDataVersion = 4;

  /// URL base oficial onde os dados estão hospedados.
  static const String kBaseUrl = 'https://serving.arestaclimb.com';

  /// Retorna a URL combinada com a versão atual de dados.
  static String get officialServerUrl => '$kBaseUrl/v$kDataVersion';
}
