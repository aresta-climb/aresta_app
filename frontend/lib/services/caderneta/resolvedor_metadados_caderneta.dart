// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
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

  /// Cria o resolvedor e inicia a escuta reativa da caderneta e do catálogo local.
  ResolvedorMetadadosCaderneta({
    required RepositorioCaderneta repositorioCaderneta,
    RepositorioCatalogo? repositorioCatalogo,
    DatasetRepository? datasetRepo,
  }) : _repositorioCaderneta = repositorioCaderneta,
       _datasetRepo = datasetRepo,
       _catalogo = repositorioCatalogo ?? datasetRepo?.repositorioCatalogo {
    _repositorioCaderneta.cadenasNotifier.addListener(_aoMudarFonteDeDados);
    _catalogo?.versaoNotificador.addListener(_aoMudarFonteDeDados);
    _datasetRepo?.activeDataset.addListener(_aoMudarFonteDeDados);
    unawaited(atualizar());
  }

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

  void _aoMudarFonteDeDados() {
    if (_descartado) return;
    notifyListeners();
    unawaited(atualizar());
  }

  /// Sincroniza o cache em memória com os registros do SQLite (`catalogo.db`)
  /// para todos os `escaladaUid` presentes na caderneta do usuário.
  Future<void> atualizar() async {
    final catalogo = _catalogo;
    if (catalogo == null || _descartado) return;

    final versaoAtual = catalogo.versaoNotificador.value;
    final invalidarCache = _versaoCatalogoHidratada != versaoAtual;
    final proximoCache = invalidarCache
        ? <String, _MetadadosEscaladaResolvidos>{}
        : Map<String, _MetadadosEscaladaResolvidos>.from(_cacheCatalogo);

    final uidsDistintos = _repositorioCaderneta.cadenasNotifier.value
        .map((c) => c.escaladaUid)
        .where((uid) => uid.isNotEmpty)
        .toSet();

    var alterou = invalidarCache && _cacheCatalogo.isNotEmpty;

    for (final uid in uidsDistintos) {
      if (proximoCache.containsKey(uid)) continue;
      final item = await catalogo.obterItemPorUid(uid);
      if (_descartado) return;
      if (item != null) {
        final novo = _MetadadosEscaladaResolvidos(
          nome: item.nome,
          grau: normalizarGrauEscalada(
            item.escaladaGrau,
            tipoEscalada: item.escaladaTipo,
          ),
          croquiUid: item.croquiUid,
        );
        final anterior = _cacheCatalogo[uid];
        if (anterior == null || !anterior.equivalenteA(novo)) {
          alterou = true;
        }
        proximoCache[uid] = novo;
      }
    }

    _cacheCatalogo
      ..clear()
      ..addAll(proximoCache);
    _versaoCatalogoHidratada = versaoAtual;

    if (alterou) {
      notifyListeners();
    }
  }


  _MetadadosEscaladaResolvidos? _resolverMetadados(String escaladaUid) =>
      _cacheCatalogo[escaladaUid];

  /// Retorna o nome legível da via ou bloco correspondente a [escaladaUid],
  /// ou `null` caso não conste no catálogo local nem nos croquis carregados.
  String? obterNomeDaVia(String escaladaUid) =>
      _resolverMetadados(escaladaUid)?.nome;

  /// Retorna a graduação normalizada da via ou bloco correspondente a [escaladaUid],
  /// ou `null` quando indisponível ou pertencente à modalidade highline.
  String? obterGrauDaVia(String escaladaUid) =>
      _resolverMetadados(escaladaUid)?.grau;

  /// Calcula a quantidade real de picos/croquis distintos presentes nas cadenas.
  ///
  /// Retorna `0` quando a caderneta está vazia e garante o mínimo de `1` quando
  /// existem cadenas cujo croqui ainda não foi indexado localmente.
  int obterTotalPicosDistintos() {
    final cadenas = _repositorioCaderneta.cadenasNotifier.value;
    if (cadenas.isEmpty) return 0;

    final croquisDistintos = <String>{};
    for (final cadena in cadenas) {
      final croquiUid = _resolverMetadados(cadena.escaladaUid)?.croquiUid;
      if (croquiUid != null && croquiUid.isNotEmpty) {
        croquisDistintos.add(croquiUid);
      }
    }
    return croquisDistintos.isNotEmpty ? croquisDistintos.length : 1;
  }

  @override
  void dispose() {
    _descartado = true;
    _repositorioCaderneta.cadenasNotifier.removeListener(_aoMudarFonteDeDados);
    _catalogo?.versaoNotificador.removeListener(_aoMudarFonteDeDados);
    _datasetRepo?.activeDataset.removeListener(_aoMudarFonteDeDados);
    super.dispose();
  }
}
