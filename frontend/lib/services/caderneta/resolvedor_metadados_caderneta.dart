// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import '../repositorio_dataset.dart';
import 'repositorio_caderneta.dart';

class _MetadadosEscaladaResolvidos {
  final String nome;
  final String? grau;
  final String croquiUid;

  const _MetadadosEscaladaResolvidos({
    required this.nome,
    required this.grau,
    required this.croquiUid,
  });

  bool equivalenteA(_MetadadosEscaladaResolvidos outro) =>
      nome == outro.nome &&
      grau == outro.grau &&
      croquiUid == outro.croquiUid;
}

/// Ponte reativa entre a [RepositorioCaderneta] e o catálogo local de escaladas.
///
/// Hidrata assincronamente nomes de vias, graduações normalizadas para a pirâmide
/// esportiva e contagem de picos distintos a partir do `catalogo.db` ([RepositorioCatalogo]),
/// utilizando os croquis carregados em memória no [DatasetRepository] como fallback
/// síncrono imediato para funcionamento offline e em sessões online sob demanda.
class ResolvedorMetadadosCaderneta extends ChangeNotifier {
  final RepositorioCaderneta _repositorioCaderneta;
  final DatasetRepository? _datasetRepo;
  final RepositorioCatalogo? _catalogo;

  final Map<String, _MetadadosEscaladaResolvidos> _cacheCatalogo = {};
  int? _versaoCatalogoHidratada;
  bool _descartado = false;


  ResolvedorMetadadosCaderneta({
    required RepositorioCaderneta repositorioCaderneta,
    RepositorioCatalogo? repositorioCatalogo,
    DatasetRepository? datasetRepo,
  }) : _repositorioCaderneta = repositorioCaderneta,
       _datasetRepo = datasetRepo,
       _catalogo = repositorioCatalogo ?? datasetRepo?.repositorioCatalogo;

  /// Normaliza strings brutas de graduação vindas do catálogo SQLite ou de Protobufs
  /// para os rótulos canônicos esperados pela pirâmide esportiva (ex.: `'6sup'` -> `'6ºsup'`,
  /// `'5'` -> `'5º'`, `'v4'` -> `'V4'`), descartando metragens de `'highline'`.
  static String? normalizarGrauEscalada(
    String? grauBruto, {
    String? tipoEscalada,
  }) {
    if (tipoEscalada == 'highline' || grauBruto == null) {
      return null;
    }
    final texto = grauBruto.trim();
    if (texto.isEmpty) {
      return null;
    }

    final ehBoulder =
        tipoEscalada == 'boulder' ||
        RegExp(r'^[vV]([bB]|\d+)').hasMatch(texto);
    if (ehBoulder) {
      return texto.toUpperCase();
    }

    return texto
        .split('/')
        .map((parte) {
          final limpa = parte.trim();
          final match = RegExp(
            r'^([1-9])\s*(sup)?$',
            caseSensitive: false,
          ).firstMatch(limpa);
          if (match != null) {
            final numero = match.group(1)!;
            final sufixo = match.group(2) != null ? 'sup' : '';
            return '$numeroº$sufixo';
          }
          return limpa;
        })
        .join('/');
  }

  Future<void> atualizar() async {
    if (_catalogo == null || _descartado || _datasetRepo == null) {
      _versaoCatalogoHidratada = _catalogo?.versaoNotificador.value;
    }
  }

  String? obterNomeDaVia(String escaladaUid) => _cacheCatalogo[escaladaUid]?.nome;

  String? obterGrauDaVia(String escaladaUid) => _cacheCatalogo[escaladaUid]?.grau;

  int obterTotalPicosDistintos() =>
      _repositorioCaderneta.cadenasNotifier.value.isEmpty ? 0 : 1;

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}
