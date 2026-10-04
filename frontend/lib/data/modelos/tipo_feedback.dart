// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Define as categorias de feedback enviadas pelos usuários.
enum TipoFeedback {
  /// Sugestão ou relato associado a um croqui, setor ou via específica.
  croqui,

  /// Sugestão ou relato associado ao funcionamento do aplicativo em si.
  aplicativo;

  /// Retorna a representação textual serializável para persistência e rede.
  String get valor {
    switch (this) {
      case TipoFeedback.croqui:
        return 'croqui';
      case TipoFeedback.aplicativo:
        return 'app';
    }
  }

  /// Converte uma [String] arbitrária para [TipoFeedback], com fallback para [aplicativo].
  static TipoFeedback fromString(String? valor) {
    if (valor == 'croqui') {
      return TipoFeedback.croqui;
    }
    return TipoFeedback.aplicativo;
  }
}
