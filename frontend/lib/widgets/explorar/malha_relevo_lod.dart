// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:isolate';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

import '../../data/modelos/modelos_rede_viaria_aresta.dart';
import '../../utils/codificador_malha_binaria.dart';

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
      'assets/geometria/malha_globo_brasil.bin';
  static MalhaGeograficaGlobo? _cacheMemoria;

  /// Retorna a malha geográfica já decodificada em RAM, evitando flash inicial ao reabrir a aba.
  static MalhaGeograficaGlobo? get cacheMemoria => _cacheMemoria;

  final List<PoligonoGeografico> continentes;
  final List<Offset> brasil;
  final List<PoligonoGeografico> estados;
  final List<LocalidadeRegionalMapa> localidadesProximas;
  final List<RodoviaRegionalMapa> rodoviasProximas;
  final String versaoMalhaViaria;

  const MalhaGeograficaGlobo({
    required this.continentes,
    required this.brasil,
    required this.estados,
    this.localidadesProximas = const [],
    this.rodoviasProximas = const [],
    this.versaoMalhaViaria = '',
  });

  /// Retorna uma nova instância imutável substituindo as rodovias pela cópia offline sincronizada.
  MalhaGeograficaGlobo comRodoviasAtualizadas(
    List<RodoviaRegionalMapa> novasRodovias, {
    String? versaoMalhaViaria,
  }) =>
      MalhaGeograficaGlobo(
        continentes: continentes,
        brasil: brasil,
        estados: estados,
        localidadesProximas: localidadesProximas,
        rodoviasProximas: novasRodovias,
        versaoMalhaViaria: versaoMalhaViaria ?? this.versaoMalhaViaria,
      );

  /// Carrega e decodifica o ativo binário compacto em `Isolate.run`, mantendo cache em RAM sem pausas de GC.
  static Future<MalhaGeograficaGlobo> carregarDoAssetBundle({
    AssetBundle? bundle,
    bool usarCache = true,
  }) async {
    if (usarCache && _cacheMemoria != null) {
      return _cacheMemoria!;
    }
    final bd = await (bundle ?? rootBundle).load(caminhoAssetPadrao);
    final bytes = bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);
    final decodificada = await Isolate.run(
      () => _decodificarBinarioEmIsolate(bytes),
    );
    if (usarCache) {
      _cacheMemoria = decodificada;
    }
    return decodificada;
  }

  static MalhaGeograficaGlobo _decodificarBinarioEmIsolate(Uint8List bytes) {
    final d = CodificadorMalhaBinaria.decodificarMalhaGlobo(bytes);
    return MalhaGeograficaGlobo(
      continentes: d.continentes,
      brasil: d.brasil,
      estados: d.estados,
      localidadesProximas: d.localidades,
      rodoviasProximas: d.rodovias,
      versaoMalhaViaria: d.versaoMalhaViaria,
    );
  }

  /// Determina em espaço geográfico exato `(longitude, latitude)` se o ponto pertence à terra firme
  /// (Brasil ou massas continentais), evitando qualquer recorte incorreto de horizonte 3D sobre estados internos.
  bool contemPontoTerrestre({
    required double latitude,
    required double longitude,
  }) {
    // Atalho O(1) para o interior continental brasileiro (Minas Gerais, Goiás, interior SP/BA),
    // eliminando milhares de raycasts poligonais por quadro longe do litoral atlântico.
    if (latitude >= -22.4 &&
        latitude <= -5.0 &&
        longitude >= -58.0 &&
        longitude <= -41.6) {
      return true;
    }
    if (_pontoEmAnelLonLat(longitude, latitude, brasil)) return true;
    for (final cont in continentes) {
      if (_pontoEmAnelLonLat(longitude, latitude, cont.verticesLonLat)) {
        return true;
      }
    }
    return false;
  }

  static bool _pontoEmAnelLonLat(
    double lon,
    double lat,
    List<Offset> anel,
  ) {
    var dentro = false;
    for (var i = 0, j = anel.length - 1; i < anel.length; j = i++) {
      final xi = anel[i].dx;
      final yi = anel[i].dy;
      final xj = anel[j].dx;
      final yj = anel[j].dy;
      final cruza = ((yi > lat) != (yj > lat)) &&
          (lon < (xj - xi) * (lat - yi) / (yj - yi) + xi);
      if (cruza) dentro = !dentro;
    }
    return dentro;
  }
}

/// Gerador determinístico de elevação local por objeto (`LOD 2` e `LOD 3`) interpolando grades DEM reais
/// (`NASA SRTM 30m`) estritamente na vizinhança de cada pico catalogado.
abstract final class GeradorRelevoLod {
  static const double _grausParaRad = math.pi / 180.0;

  /// Calcula a elevação em metros de `(latitude, longitude)` apenas dentro do raio dos [picosReferencia],
  /// retornando `0.0` em oceanos ou regiões distantes sem picos catalogados.
  static double amostrarElevacaoMetros({
    required double latitude,
    required double longitude,
    required List<PicoRelevoReferencia> picosReferencia,
  }) {
    var somaCota = 0.0;
    var somaPeso = 0.0;

    for (final p in picosReferencia) {
      final amostra = amostrarElevacaoObjetoComPeso(
        latitude: latitude,
        longitude: longitude,
        pico: p,
      );
      if (amostra.peso <= 0.0) continue;
      somaCota += amostra.elevacaoMetros * amostra.peso;
      somaPeso += amostra.peso;
    }

    if (somaPeso <= 0.0) return 0.0;
    return somaCota / somaPeso;
  }

  /// Amostra o campo topográfico real contínuo em `(latitude, longitude)`, priorizando
  /// as malhas locais `NASA SRTM 30m` dos picos e os tiles `AWS Terrarium` / grade regional SRTM
  /// providos por [amostradorElevacaoReal], sem gerar ondas senoidais procedurais irreais.
  static double amostrarTerrenoRegionalContinuo({
    required double latitude,
    required double longitude,
    required List<PicoRelevoReferencia> picosReferencia,
    bool? ehTerraConfirmada,
    double? Function(double latitude, double longitude)? amostradorElevacaoReal,
  }) {
    if (ehTerraConfirmada == false) return 0.0;

    var somaDem = 0.0;
    var pesoDem = 0.0;
    var somaDemReal = 0.0;
    var pesoDemReal = 0.0;
    var ganhoCumeSintetico = 0.0;
    var somaPlanalto = 0.0;
    var pesoPlanalto = 0.0;
    var menorDist2 = double.infinity;

    final cosLat = math.max(0.35, math.cos(latitude * _grausParaRad));
    for (final p in picosReferencia) {
      final dx = (longitude - p.longitude) * cosLat;
      final dy = latitude - p.latitude;
      final d2 = dx * dx + dy * dy;
      if (d2 < menorDist2) menorDist2 = d2;

      final wReg = 1.0 / (0.020 + d2);
      somaPlanalto += p.altitudeBaseMetros * wReg;
      pesoPlanalto += wReg;

      if (d2 < 0.045) {
        final am = amostrarElevacaoObjetoComPeso(
          latitude: latitude,
          longitude: longitude,
          pico: p,
        );
        if (am.peso > 0.0) {
          somaDem += am.elevacaoMetros * am.peso;
          pesoDem += am.peso;
          if (p.temGradeDemReal) {
            somaDemReal += am.elevacaoMetros * am.peso;
            pesoDemReal += am.peso;
          }
        }
        if (!p.temGradeDemReal && p.altitudePicoMetros > p.altitudeBaseMetros + 20) {
          final prom = (p.altitudePicoMetros - p.altitudeBaseMetros).toDouble();
          final domo = prom * math.exp(-d2 / 0.0009);
          if (domo > ganhoCumeSintetico) ganhoCumeSintetico = domo;
        }
      }
    }

    final cotaRealExterna = amostradorElevacaoReal?.call(latitude, longitude);
    if (cotaRealExterna != null) {
      final baseReal = ehTerraConfirmada == true
          ? math.max(2.0, cotaRealExterna)
          : cotaRealExterna;
      if (pesoDemReal > 0.0) {
        final cotaLocalReal = somaDemReal / pesoDemReal;
        final mistura = pesoDemReal.clamp(0.0, 1.0);
        return baseReal * (1.0 - mistura) + cotaLocalReal * mistura;
      }
      // Preserva proeminência real de cumes íngremes sem escavar valas circulares no entorno
      return baseReal + ganhoCumeSintetico;
    }

    if (picosReferencia.isEmpty) return 0.0;
    if (ehTerraConfirmada == null && menorDist2 >= 8.5) return 0.0;

    final atenDist = ehTerraConfirmada == true
        ? 1.0 - 0.35 * ((math.sqrt(menorDist2) - 2.0) / 4.0).clamp(0.0, 1.0)
        : 1.0 - ((math.sqrt(menorDist2) - 1.4) / 1.5).clamp(0.0, 1.0);
    final pisoContinental = ehTerraConfirmada == true ? 180.0 : 8.0;
    final cotaRegional =
        math.max(pisoContinental, (somaPlanalto / pesoPlanalto) * atenDist);

    if (pesoDem <= 0.0) return cotaRegional;
    final cotaLocal = somaDem / pesoDem;
    final mistura = pesoDem.clamp(0.0, 1.0);
    return cotaRegional * (1.0 - mistura) + cotaLocal * mistura;
  }

  /// Avalia em `O(1)` a cota altimétrica e o peso espacial (`0.0 .. 1.0`) de um único [pico] em `(latitude, longitude)`.
  static ({double elevacaoMetros, double peso}) amostrarElevacaoObjetoComPeso({
    required double latitude,
    required double longitude,
    required PicoRelevoReferencia pico,
  }) {
    if (pico.temGradeDemReal) {
      final cosLat = math.max(0.35, math.cos(pico.latitude * _grausParaRad));
      final uNorm = (longitude - pico.longitude) * cosLat / pico.raioGradeDemGraus;
      final vNorm = (latitude - pico.latitude) / pico.raioGradeDemGraus;
      final distRadial = math.sqrt(uNorm * uNorm + vNorm * vNorm);
      if (distRadial >= 1.38) {
        return (elevacaoMetros: 0.0, peso: 0.0);
      }
      final uDem = (longitude - pico.longitude) / pico.raioGradeDemGraus;
      final cotaDem = _interpolarBilinearDem(pico, uDem, vNorm);
      final tBorda = ((distRadial - 0.72) / (1.38 - 0.72)).clamp(0.0, 1.0);
      final peso = 1.0 - tBorda * tBorda * (3.0 - 2.0 * tBorda);
      return (elevacaoMetros: cotaDem, peso: peso);
    }

    final dx =
        (longitude - pico.longitude) * math.cos(pico.latitude * _grausParaRad);
    final dy = latitude - pico.latitude;
    final d2 = dx * dx + dy * dy;
    if (d2 >= 0.0064) {
      return (elevacaoMetros: 0.0, peso: 0.0);
    }

    if (pico.altitudeBaseMetros <= 30 && dy < -0.022) {
      return (elevacaoMetros: -25.0, peso: 1.0);
    }

    final semente = _sementeDeterministica(pico.id);
    final baseFloor = pico.altitudeBaseMetros.toDouble();
    final prominencia = math.max(
      120.0,
      (pico.altitudePicoMetros - pico.altitudeBaseMetros).toDouble(),
    );

    final cumePrincipal = math.exp(-d2 / 0.0016) * prominencia;
    final sx1 = dx - 0.018 * math.cos(semente);
    final sy1 = dy + 0.014 * math.sin(semente);
    final crista1 =
        math.exp(-(sx1 * sx1 + sy1 * sy1) / 0.0014) * (prominencia * 0.42);

    final dist = math.sqrt(d2);
    final tBorda = ((dist - 0.045) / (0.080 - 0.045)).clamp(0.0, 1.0);
    final peso = 1.0 - tBorda * tBorda * (3.0 - 2.0 * tBorda);
    final cotaLocal = baseFloor + cumePrincipal + crista1;
    return (elevacaoMetros: cotaLocal, peso: peso);
  }

  static double _interpolarBilinearDem(
    PicoRelevoReferencia p,
    double uNorm,
    double vNorm,
  ) {
    final n = p.dimensaoGradeDem;
    final gx = (((uNorm.clamp(-1.0, 1.0) + 1.0) * 0.5) * (n - 1))
        .clamp(0.0, (n - 1).toDouble());
    final gy = (((vNorm.clamp(-1.0, 1.0) + 1.0) * 0.5) * (n - 1))
        .clamp(0.0, (n - 1).toDouble());

    final i0 = gx.floor().clamp(0, n - 1);
    final j0 = gy.floor().clamp(0, n - 1);
    final i1 = math.min(n - 1, i0 + 1);
    final j1 = math.min(n - 1, j0 + 1);
    final fx = gx - i0;
    final fy = gy - j0;

    final g = p.gradeDemMetros;
    final z00 = g[j0 * n + i0].toDouble();
    final z10 = g[j0 * n + i1].toDouble();
    final z01 = g[j1 * n + i0].toDouble();
    final z11 = g[j1 * n + i1].toDouble();

    final sul = z00 + (z10 - z00) * fx;
    final norte = z01 + (z11 - z01) * fx;
    final baseBilinear = sul + (norte - sul) * fy;

    // Preserva agulhas/paredões sub-grade medidos em 30m no centro do setor
    final centroIdx = (n ~/ 2) * n + (n ~/ 2);
    final zCentroGrade = g[centroIdx].toDouble();
    final ganhoAgulha = (p.altitudePicoMetros - zCentroGrade).clamp(0.0, 180.0);
    final r2 = uNorm * uNorm + vNorm * vNorm;
    return baseBilinear + ganhoAgulha * math.exp(-r2 / 0.055);
  }

  static double _sementeDeterministica(String id) {
    var hash = 2166136261;
    for (var i = 0; i < id.length; i++) {
      hash ^= id.codeUnitAt(i);
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return (hash % 628) / 100.0;
  }
}
