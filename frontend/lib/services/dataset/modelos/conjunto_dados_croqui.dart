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

  /// Converte elementos da lista para [ResumoPico] de forma simples e segura.
  static List<ResumoPico> _normalizarLista(dynamic lista) {
    if (lista is! Iterable) return const [];

    final resultado = <ResumoPico>[];
    for (final item in lista) {
      if (item is ResumoPico) {
        resultado.add(item);
      } else if (item is Map) {
        resultado.add(ResumoPico.deMapa(Map<String, dynamic>.from(item)));
      }
    }
    return resultado;
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
