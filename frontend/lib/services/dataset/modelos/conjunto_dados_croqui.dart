// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../../aresta_api/proto/generated/croqui.pb.dart';
import 'metadados_indice.dart';
import 'resumo_pico.dart';


/// Representa o conjunto de dados atual do catálogo de croquis.
///
/// Fornece acesso direto e fortemente tipado aos metadados do índice ([MetadadosIndice])
/// e aos croquis salvos offline ([Croqui]), além de manter compatibilidade com
/// estruturas intermediárias [ResumoPico].
class ConjuntoDadosCroqui {
  /// Lista de metadados de croquis disponíveis no índice catalogado.
  final List<MetadadosIndice> metadadosDisponiveis;

  /// Lista de croquis completos salvos localmente para acesso offline.
  final List<Croqui> croquisBaixados;

  /// Lista de todos os picos catalogados disponíveis no índice (legado/interoperabilidade).
  final List<ResumoPico> picosDisponiveis;

  /// Lista dos picos salvos no armazenamento local para acesso offline (legado/interoperabilidade).
  final List<ResumoPico> picosBaixados;

  ConjuntoDadosCroqui({
    List<MetadadosIndice>? metadadosDisponiveis,
    List<Croqui>? croquisBaixados,
    dynamic picosDisponiveis,
    dynamic picosBaixados,
    dynamic availablePicos,
    dynamic downloadedPicos,
  })  : metadadosDisponiveis = metadadosDisponiveis ?? const [],
        croquisBaixados = croquisBaixados ??
            _extrairCroquis(picosBaixados ?? downloadedPicos),
        picosDisponiveis = _resolverPicosDisponiveis(
          picosDisponiveis: picosDisponiveis ?? availablePicos,
          metadadosDisponiveis: metadadosDisponiveis,
        ),
        picosBaixados = _resolverPicosBaixados(
          picosBaixados: picosBaixados ?? downloadedPicos,
          croquisBaixados: croquisBaixados,
        );

  /// Construtor constante para conjuntos já estruturados.
  const ConjuntoDadosCroqui.puro({
    this.metadadosDisponiveis = const [],
    this.croquisBaixados = const [],
    this.picosDisponiveis = const [],
    this.picosBaixados = const [],
  });

  static List<Croqui> _extrairCroquis(dynamic lista) {
    if (lista is! Iterable) return const [];
    final resultado = <Croqui>[];
    for (final item in lista) {
      if (item is Croqui) {
        resultado.add(item);
      } else if (item is ResumoPico && item.croqui != null) {
        resultado.add(item.croqui!);
      }
    }
    return resultado;
  }

  static List<ResumoPico> _resolverPicosDisponiveis({
    dynamic picosDisponiveis,
    List<MetadadosIndice>? metadadosDisponiveis,
  }) {
    if (picosDisponiveis != null) {
      return _normalizarLista(picosDisponiveis);
    }
    if (metadadosDisponiveis != null && metadadosDisponiveis.isNotEmpty) {
      return metadadosDisponiveis.map((m) => m.paraResumoPico()).toList();
    }
    return const [];
  }

  static List<ResumoPico> _resolverPicosBaixados({
    dynamic picosBaixados,
    List<Croqui>? croquisBaixados,
  }) {
    if (picosBaixados != null) {
      return _normalizarLista(picosBaixados);
    }
    if (croquisBaixados != null && croquisBaixados.isNotEmpty) {
      return croquisBaixados.map((c) => c.paraResumoPico()).toList();
    }
    return const [];
  }

  /// Converte elementos da lista para [ResumoPico] de forma simples e segura.
  static List<ResumoPico> _normalizarLista(dynamic lista) {
    if (lista is! Iterable) return const [];

    final resultado = <ResumoPico>[];
    for (final item in lista) {
      if (item is ResumoPico) {
        resultado.add(item);
      } else if (item is Croqui) {
        resultado.add(item.paraResumoPico());
      } else if (item is MetadadosIndice) {
        resultado.add(item.paraResumoPico());
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
    List<MetadadosIndice>? metadadosDisponiveis,
    List<Croqui>? croquisBaixados,
    List<ResumoPico>? picosDisponiveis,
    List<ResumoPico>? picosBaixados,
  }) {
    return ConjuntoDadosCroqui(
      metadadosDisponiveis: metadadosDisponiveis ?? this.metadadosDisponiveis,
      croquisBaixados: croquisBaixados ?? this.croquisBaixados,
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
