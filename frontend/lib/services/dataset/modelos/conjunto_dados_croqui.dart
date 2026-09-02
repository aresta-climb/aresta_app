// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Representa o conjunto de dados atual do catálogo de croquis.
///
/// Contém a lista de todos os picos disponíveis no índice e a lista
/// dos picos que já foram baixados para o dispositivo local.
class ConjuntoDadosCroqui {
  /// Lista de todos os picos catalogados disponíveis no índice.
  final List<Map<String, dynamic>> picosDisponiveis;

  /// Lista dos picos salvos no armazenamento local para acesso offline.
  final List<Map<String, dynamic>> picosBaixados;

  const ConjuntoDadosCroqui({
    required this.picosDisponiveis,
    required this.picosBaixados,
  });

  /// Apelido para manter compatibilidade com implementações legadas.
  List<Map<String, dynamic>> get availablePicos => picosDisponiveis;

  /// Apelido para manter compatibilidade com implementações legadas.
  List<Map<String, dynamic>> get downloadedPicos => picosBaixados;

  /// Cria uma cópia com campos atualizados opcionalmente.
  ConjuntoDadosCroqui copyWith({
    List<Map<String, dynamic>>? picosDisponiveis,
    List<Map<String, dynamic>>? picosBaixados,
  }) {
    return ConjuntoDadosCroqui(
      picosDisponiveis: picosDisponiveis ?? this.picosDisponiveis,
      picosBaixados: picosBaixados ?? this.picosBaixados,
    );
  }

  /// Retorna uma instância vazia inicial do conjunto de dados.
  factory ConjuntoDadosCroqui.vazio() {
    return const ConjuntoDadosCroqui(
      picosDisponiveis: [],
      picosBaixados: [],
    );
  }
}

/// Typedef para compatibilidade com o nome antigo `TopoDataset`.
typedef TopoDataset = ConjuntoDadosCroqui;
