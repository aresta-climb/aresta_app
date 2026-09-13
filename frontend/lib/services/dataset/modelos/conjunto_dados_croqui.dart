// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'resumo_pico.dart';

/// Representa o conjunto de dados atual do catálogo de croquis.
///
/// Contém a lista de todos os picos disponíveis no índice e a lista
/// dos picos que já foram baixados para o dispositivo local, utilizando
/// objetos fortemente tipados [ResumoPico].
class ConjuntoDadosCroqui {
  /// Lista de todos os picos catalogados disponíveis no índice.
  final List<ResumoPico> picosDisponiveis;

  /// Lista dos picos salvos no armazenamento local para acesso offline.
  final List<ResumoPico> picosBaixados;

  ConjuntoDadosCroqui({
    dynamic picosDisponiveis,
    dynamic picosBaixados,
    dynamic availablePicos,
    dynamic downloadedPicos,
  })  : picosDisponiveis = _normalizarLista(picosDisponiveis ?? availablePicos),
        picosBaixados = _normalizarLista(picosBaixados ?? downloadedPicos);

  /// Construtor constante para listas puras já tipadas.
  const ConjuntoDadosCroqui.puro({
    this.picosDisponiveis = const [],
    this.picosBaixados = const [],
  });

  static List<ResumoPico> _normalizarLista(dynamic lista) {
    if (lista == null) return [];
    if (lista is List<ResumoPico>) return List<ResumoPico>.from(lista);
    if (lista is List) {
      return lista.map((item) {
        if (item is ResumoPico) return item;
        if (item is Map<String, dynamic>) return ResumoPico.deMapa(item);
        if (item is Map) {
          return ResumoPico.deMapa(Map<String, dynamic>.from(item));
        }
        throw ArgumentError(
          'Tipo inválido de item na lista de picos: ${item.runtimeType}',
        );
      }).toList();
    }
    return [];
  }

  /// Apelido para manter compatibilidade com implementações legadas.
  List<ResumoPico> get availablePicos => picosDisponiveis;

  /// Apelido para manter compatibilidade com implementações legadas.
  List<ResumoPico> get downloadedPicos => picosBaixados;

  /// Cria uma cópia com campos atualizados opcionalmente.
  ConjuntoDadosCroqui copyWith({
    List<ResumoPico>? picosDisponiveis,
    List<ResumoPico>? picosBaixados,
  }) {
    return ConjuntoDadosCroqui(
      picosDisponiveis: picosDisponiveis ?? this.picosDisponiveis,
      picosBaixados: picosBaixados ?? this.picosBaixados,
    );
  }

  /// Retorna uma instância vazia inicial do conjunto de dados.
  factory ConjuntoDadosCroqui.vazio() {
    return const ConjuntoDadosCroqui.puro();
  }
}

/// Typedef para compatibilidade com o nome antigo `TopoDataset`.
typedef TopoDataset = ConjuntoDadosCroqui;
