// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

import '../../data/modelos/modelos_rede_viaria_aresta.dart';

export '../../data/modelos/modelos_rede_viaria_aresta.dart';

/// Carregador e cache em RAM da textura esférica equiretangular NASA Blue Marble (`LODs 0–1`).
abstract final class TexturaGloboNasa {
  static const String caminhoAssetPadrao =
      'assets/geometria/textura_globo_nasa.jpg';
  static ui.Image? _cacheMemoria;
  static Future<ui.Image>? _carregamentoEmVoo;

  /// Retorna a imagem já decodificada em GPU/RAM para pintura instantânea sem piscar.
  static ui.Image? get cacheMemoria => _cacheMemoria;

  /// Decodifica a textura equiretangular do pacote de assets mantendo sua resolução nativa `4096x2048` por padrão.
  static Future<ui.Image> carregarDoAssetBundle({
    AssetBundle? bundle,
    bool usarCache = true,
    int? larguraAlvo,
  }) {
    if (usarCache && _cacheMemoria != null) {
      return Future<ui.Image>.value(_cacheMemoria!);
    }
    if (usarCache && _carregamentoEmVoo != null) {
      return _carregamentoEmVoo!;
    }
    final futuro = _decodificarTextura(
      bundle: bundle,
      usarCache: usarCache,
      larguraAlvo: larguraAlvo,
    );
    if (usarCache) {
      _carregamentoEmVoo = futuro.whenComplete(() => _carregamentoEmVoo = null);
      return _carregamentoEmVoo!;
    }
    return futuro;
  }

  static Future<ui.Image> _decodificarTextura({
    AssetBundle? bundle,
    required bool usarCache,
    int? larguraAlvo,
  }) async {
    final dados = await (bundle ?? rootBundle).load(caminhoAssetPadrao);
    final codec = await ui.instantiateImageCodec(
      dados.buffer.asUint8List(dados.offsetInBytes, dados.lengthInBytes),
      targetWidth: larguraAlvo,
    );
    try {
      final quadro = await codec.getNextFrame();
      if (usarCache) {
        _cacheMemoria = quadro.image;
      }
      return quadro.image;
    } finally {
      codec.dispose();
    }
  }
}

/// Malha geográfica offline imutável dos continentes, contorno brasileiro, 27 UFs, cidades IBGE e rodovias.
class MalhaGeograficaGlobo {
  static const String caminhoAssetPadrao =
      'assets/geometria/malha_globo_brasil.json';
  static MalhaGeograficaGlobo? _cacheMemoria;

  /// Retorna a malha geográfica já decodificada em RAM, evitando flash inicial ao reabrir a aba.
  static MalhaGeograficaGlobo? get cacheMemoria => _cacheMemoria;

  final List<PoligonoGeografico> continentes;
  final List<Offset> brasil;
  final List<PoligonoGeografico> estados;
  final List<LocalidadeRegionalMapa> localidadesProximas;
  final List<RodoviaRegionalMapa> rodoviasProximas;

  const MalhaGeograficaGlobo({
    required this.continentes,
    required this.brasil,
    required this.estados,
    this.localidadesProximas = const [],
    this.rodoviasProximas = const [],
  });

