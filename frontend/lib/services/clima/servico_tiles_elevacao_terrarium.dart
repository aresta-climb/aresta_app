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

  GradeElevacaoRegionalOffline? _gradeRegionalOffline;
  bool _inicializado = false;
  bool _descartado = false;
  int _versaoDados = 0;

  ServicoTilesElevacaoTerrarium({
    FonteTilesElevacaoMapa? fonteRemota,
    AssetBundle? assetBundle,
    Future<Uint8List> Function(Uint8List pngBytes)? decodificadorRgba,
  })  : _fonteRemota = fonteRemota ?? ClienteTilesTerrariumAws(),
        _assetBundle = assetBundle ?? rootBundle,
        _decodificadorRgba = decodificadorRgba ?? decodificarPngParaRgba256;

  bool get inicializado => _inicializado;
  int get versaoDados => _versaoDados;
  int get totalTilesEmCache => _cacheLru.length;
  GradeElevacaoRegionalOffline? get gradeRegionalOffline =>
      _gradeRegionalOffline;

  /// Hidrata a grade regional SRTM offline embarcada em `altimetria_picos_inicial.json`.
  Future<void> inicializar() async {
    if (_inicializado || _descartado) return;
    try {
      final texto = await _assetBundle.loadString(
        caminhoAssetAltimetria,
        cache: false,
      );
      if (_descartado) return;
      final raiz = jsonDecode(texto) as Map<String, dynamic>;
      final brutoGrade = raiz['grade_regional_offline'];
      if (brutoGrade is Map) {
        _gradeRegionalOffline = GradeElevacaoRegionalOffline.deMapa(
          Map<String, dynamic>.from(brutoGrade),
        );
        _versaoDados++;
      }
    } catch (e, st) {
      AppLogger.instance.logError(
        '[ServicoTilesElevacaoTerrarium] Falha ao carregar grade regional offline',
        error: e,
        stackTrace: st,
      );
    }
    _inicializado = true;
    if (!_descartado) notifyListeners();
  }

  /// Seleciona o zoom Terrarium ideal (`8`, `10` ou `12`) para o `LOD` atual da câmera.
  static int escolherZoomTerrarium(double lod) {
    if (lod >= 3.55) return 12;
    if (lod >= 2.72) return 10;
    return 8;
  }

  /// Dispara em background (sem bloquear a UI) o download dos tiles Terrarium visíveis na janela.
  void solicitarTilesVisiveis({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
    required double lod,
  }) {
    if (_descartado || lod < 1.85) return;
    final zoom = escolherZoomTerrarium(lod);
    final cantoNoroeste = TileElevacaoTerrarium.projetarWebMercator(
      latitude: maxLat,
      longitude: minLon,
      zoom: zoom,
    );
    final cantoSudeste = TileElevacaoTerrarium.projetarWebMercator(
      latitude: minLat,
      longitude: maxLon,
      zoom: zoom,
    );

    var solicitados = 0;
    for (var ty = cantoNoroeste.tileY; ty <= cantoSudeste.tileY; ty++) {
      for (var tx = cantoNoroeste.tileX; tx <= cantoSudeste.tileX; tx++) {
        if (solicitados >= 9) return;
        solicitados++;
        final chave = TileElevacaoTerrarium.calcularChave(zoom, tx, ty);
        if (_cacheLru.containsKey(chave) ||
            _emVoo.contains(chave) ||
            _falhasRecentes.contains(chave)) {
          continue;
        }
        _emVoo.add(chave);
        unawaited(_buscarEDecodificarTile(zoom: zoom, x: tx, y: ty, chave: chave));
      }
    }
  }

