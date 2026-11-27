// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../data/modelos/modelos_relevo_topografico.dart';
import '../firebase/app_logger.dart';
import '../http/cliente_http_aresta.dart';

/// Fronteira abstrata para busca de tiles PNG de elevação `256x256` no formato Terrarium (`SRTM`/`GMTED`).
abstract interface class FonteTilesElevacaoMapa {
  /// Baixa os bytes PNG brutos do tile `(zoom, x, y)` ou retorna `null` se indisponível/offline.
  Future<Uint8List?> baixarPngTile({
    required int zoom,
    required int x,
    required int y,
  });
}

/// Cliente HTTP público para os tiles globais `NASA SRTM / GMTED` hospedados no AWS Open Data Terrarium.
class ClienteTilesTerrariumAws implements FonteTilesElevacaoMapa {
  static const String urlBasePadrao =
      'https://s3.amazonaws.com/elevation-tiles-prod/terrarium';

  final String urlBase;
  final ClienteHttpAresta _clienteHttp;
  final Duration timeoutRequisicao;

  ClienteTilesTerrariumAws({
    this.urlBase = urlBasePadrao,
    ClienteHttpAresta? clienteHttp,
    this.timeoutRequisicao = const Duration(seconds: 5),
  }) : _clienteHttp = clienteHttp ?? ClienteHttpAresta.instancia;

  @override
  Future<Uint8List?> baixarPngTile({
    required int zoom,
    required int x,
    required int y,
  }) async {
    final uri = Uri.parse('$urlBase/$zoom/$x/$y.png');
    try {
      final resp = await _clienteHttp.get(uri).timeout(timeoutRequisicao);
      if (resp.statusCode >= 200 &&
          resp.statusCode < 300 &&
          resp.bodyBytes.isNotEmpty) {
        return resp.bodyBytes;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

/// Serviço reativo que combina a grade regional SRTM embarcada offline com o download sob demanda
/// de tiles `AWS Open Data Terrarium` (`z=8`, `z=10`, `z=12`) conforme a câmera se move no mapa.
class ServicoTilesElevacaoTerrarium extends ChangeNotifier {
  static const String caminhoAssetAltimetria =
      'assets/dados/altimetria_picos_inicial.json';
  static const int limiteCacheTiles = 48;

  static ServicoTilesElevacaoTerrarium? _instanciaCompartilhada;

  /// Instância compartilhada padrão para uso em produção.
  static ServicoTilesElevacaoTerrarium get instancia =>
      _instanciaCompartilhada ??= ServicoTilesElevacaoTerrarium();

  /// Restaura a instância compartilhada entre suítes de teste.
  @visibleForTesting
  static void redefinirParaTestes() {
    _instanciaCompartilhada?.dispose();
    _instanciaCompartilhada = null;
  }

  final FonteTilesElevacaoMapa _fonteRemota;
  final AssetBundle _assetBundle;
  final Future<Uint8List> Function(Uint8List pngBytes) _decodificadorRgba;

  final LinkedHashMap<int, TileElevacaoTerrarium> _cacheLru =
      LinkedHashMap<int, TileElevacaoTerrarium>();
  final Set<int> _emVoo = <int>{};
  final Set<int> _falhasRecentes = <int>{};

