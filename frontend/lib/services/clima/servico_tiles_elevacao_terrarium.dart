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

  /// Dispara em background (sem bloquear a UI) o download dos tiles Terrarium priorizando
  /// radialmente o centro óptico da câmera (`latitudeCentral`, `longitudeCentral`) antes das bordas.
  void solicitarTilesVisiveis({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
    required double lod,
    double? latitudeCentral,
    double? longitudeCentral,
  }) {
    if (_descartado || lod < 1.85) return;
    final latAlvo = latitudeCentral ?? (minLat + maxLat) * 0.5;
    final lonAlvo = longitudeCentral ?? (minLon + maxLon) * 0.5;
    final zoom = escolherZoomTerrarium(lod);

    // Em zoom profundo (z=12), garante primeiro o tile pai z=10 (~38x38 km) sob o centro da câmera
    if (zoom == 12) {
      final paiZ10 = TileElevacaoTerrarium.projetarWebMercator(
        latitude: latAlvo,
        longitude: lonAlvo,
        zoom: 10,
      );
      _enfileirarTileSeNecessario(
        zoom: 10,
        tx: paiZ10.tileX,
        ty: paiZ10.tileY,
      );
    }

    final centroProj = TileElevacaoTerrarium.projetarWebMercator(
      latitude: latAlvo,
      longitude: lonAlvo,
      zoom: zoom,
    );
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

    final candidatos = <({int tx, int ty, int dist2})>[];
    final txIni = cantoNoroeste.tileX.clamp(centroProj.tileX - 4, centroProj.tileX + 4);
    final txFim = cantoSudeste.tileX.clamp(centroProj.tileX - 4, centroProj.tileX + 4);
    final tyIni = cantoNoroeste.tileY.clamp(centroProj.tileY - 4, centroProj.tileY + 4);
    final tyFim = cantoSudeste.tileY.clamp(centroProj.tileY - 4, centroProj.tileY + 4);

    for (var ty = tyIni; ty <= tyFim; ty++) {
      for (var tx = txIni; tx <= txFim; tx++) {
        final dx = tx - centroProj.tileX;
        final dy = ty - centroProj.tileY;
        candidatos.add((tx: tx, ty: ty, dist2: dx * dx + dy * dy));
      }
    }
    candidatos.sort((a, b) => a.dist2.compareTo(b.dist2));

    var solicitados = 0;
    for (final c in candidatos) {
      if (solicitados >= 14) return;
      solicitados++;
      _enfileirarTileSeNecessario(zoom: zoom, tx: c.tx, ty: c.ty);
    }
  }

  void _enfileirarTileSeNecessario({
    required int zoom,
    required int tx,
    required int ty,
  }) {
    final chave = TileElevacaoTerrarium.calcularChave(zoom, tx, ty);
    if (_cacheLru.containsKey(chave) ||
        _emVoo.contains(chave) ||
        _falhasRecentes.contains(chave)) {
      return;
    }
    _emVoo.add(chave);
    unawaited(
      _buscarEDecodificarTile(zoom: zoom, x: tx, y: ty, chave: chave),
    );
  }

  Future<void> _buscarEDecodificarTile({
    required int zoom,
    required int x,
    required int y,
    required int chave,
  }) async {
    try {
      final png = await _fonteRemota.baixarPngTile(zoom: zoom, x: x, y: y);
      if (_descartado || png == null) {
        _falhasRecentes.add(chave);
        return;
      }
      final rgba = await _decodificadorRgba(png);
      if (_descartado) return;
      final tile = TileElevacaoTerrarium.deRgba256(
        zoom: zoom,
        x: x,
        y: y,
        rgba: rgba,
      );
      _inserirNoLru(chave, tile);
      _versaoDados++;
      notifyListeners();
    } catch (_) {
      _falhasRecentes.add(chave);
    } finally {
      _emVoo.remove(chave);
    }
  }

  void _inserirNoLru(int chave, TileElevacaoTerrarium tile) {
    _cacheLru.remove(chave);
    _cacheLru[chave] = tile;
    while (_cacheLru.length > limiteCacheTiles) {
      _cacheLru.remove(_cacheLru.keys.first);
    }
  }

  /// Registra diretamente um tile já decodificado em memória (útil em pré-carga ou testes).
  void registrarTileEmMemoria(TileElevacaoTerrarium tile) {
    _inserirNoLru(tile.chave, tile);
    _versaoDados++;
    if (!_descartado) notifyListeners();
  }

  /// Amostra sincronamente em `O(1)` a melhor elevação SRTM disponível (`z=12 -> z=10 -> z=8 -> offline`).
  double? amostrarElevacaoReal({
    required double latitude,
    required double longitude,
  }) {
    const niveisZoom = <int>[12, 10, 8];
    for (final z in niveisZoom) {
      final proj = TileElevacaoTerrarium.projetarWebMercator(
        latitude: latitude,
        longitude: longitude,
        zoom: z,
      );
      final chave =
          TileElevacaoTerrarium.calcularChave(z, proj.tileX, proj.tileY);
      final tile = _cacheLru[chave];
      if (tile != null) {
        return tile.amostrarLocal(proj.localX, proj.localY);
      }
    }
    return _gradeRegionalOffline?.amostrarBilinear(latitude, longitude);
  }

  /// Decodifica um PNG `256x256` em buffer RGBA bruto utilizando o codec nativo C++ do Flutter.
  static Future<Uint8List> decodificarPngParaRgba256(Uint8List pngBytes) async {
    final codec = await ui.instantiateImageCodec(
      pngBytes,
      targetWidth: TileElevacaoTerrarium.dimensao,
      targetHeight: TileElevacaoTerrarium.dimensao,
    );
    try {
      final quadro = await codec.getNextFrame();
      try {
        final byteData = await quadro.image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        if (byteData == null) {
          throw const FormatException('Falha ao extrair RGBA do tile PNG.');
        }
        return byteData.buffer.asUint8List();
      } finally {
        quadro.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  @override
  void dispose() {
    _descartado = true;
    _cacheLru.clear();
    super.dispose();
  }
}
