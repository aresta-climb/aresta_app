// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Constantes globais de rede e servidores do Aresta Climb.
class NetworkConstants {
  /// Versão atual dos dados embutidos. Alterar isso forçará um hard update em aparelhos atualizados.
  static const int kDataVersion = 4;

  /// URL base oficial padrão onde os dados estão hospedados.
  static const String kDefaultServingBaseUrl = 'https://serving.arestaclimb.com';

  /// URL base oficial combinada com a versão atual de dados (usada pelo pre-bundling e fallbacks).
  static const String kDefaultOfficialServerUrl =
      '$kDefaultServingBaseUrl/v$kDataVersion';

  /// URL padrão do endpoint seguro de feedback do aplicativo (Edge Function Supabase).
  static const String kDefaultFeedbackEdgeFunctionUrl =
      'https://gawgqiqzptckwghgqypt.supabase.co/functions/v1/app-feedback';
}
