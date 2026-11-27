// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'geometria_geoide_globo.dart';

export 'geometria_geoide_globo.dart';

class _AnimacaoVooParabolico {
  final double latInicial;
  final double lonInicial;
  final double lodInicial;
  final double latFinal;
  final double deltaLonCurto;
  final double lodFinal;
  final double recuoArco;
  double progresso = 0.0;

  _AnimacaoVooParabolico({
    required this.latInicial,
    required this.lonInicial,
    required this.lodInicial,
    required this.latFinal,
    required this.deltaLonCurto,
    required this.lodFinal,
    required this.recuoArco,
  });
}

/// Controlador matemático e cinemático da câmera unificada `3D / 2D` em 4 LODs contínuos.
///
/// Concentra toda a projeção esférica-perspectiva, inclinação progressiva de horizonte,
/// acoplamento do centro óptico com a gaveta deslizante, voo parabólico (`Fly-To`)
/// e desaceleração inercial, mantendo widgets gráficos passivos e rápidos (`< 2ms`/frame).
class ControladorCameraGlobo extends ChangeNotifier {
  static const double _grausParaRad = GeometriaGeoideGlobo.grausParaRad;
  static const double lodMinimo = 0.0;
  static const double lodMaximo = 4.65;

  /// Limiar de zoom a partir do qual o mapa inicia a propagação luminosa laranja Aresta pelas rodovias.
  static const double limiarAtivacaoLuzViaria = 1.58;

  /// Limiar de zoom de retorno abaixo do qual a luz laranja recolhe das pontas de volta ao centro de BH.
  static const double limiarDesativacaoLuzViaria = 1.46;

  bool _modo3D;
  double _latitudeCentral;
  double _longitudeCentral;
  double _lod;
  final double _giroLocalRad = 0.0;
  double _alturaGavetaPx = 220.0;
  double _elevacaoReferenciaCameraMetros = 0.0;
  Size _ultimoTamanhoTela = const Size(400, 800);
  bool _interagindoManual = false;
  bool _teveMultiToqueNoGesto = false;
  double _velLon = 0.0;
  double _velLat = 0.0;
  _AnimacaoVooParabolico? _vooAtivo;

  ControladorCameraGlobo({
    double latitudeInicial = -19.5,
    double longitudeInicial = -44.2,
    double lodInicial = 0.22,
    bool modo3DInicial = true,
  })  : _latitudeCentral = latitudeInicial.clamp(
          modo3DInicial ? -68.0 : -85.0,
          modo3DInicial ? 68.0 : 85.0,
        ),
        _longitudeCentral =
            GeometriaGeoideGlobo.normalizarLongitude(longitudeInicial),
        _lod = lodInicial.clamp(lodMinimo, lodMaximo),
        _modo3D = modo3DInicial;

  bool get modo3D => _modo3D;
  double get latitudeCentral => _latitudeCentral;
  double get longitudeCentral => _longitudeCentral;
  double get lod => _lod;
  double get giroLocalRad => _giroLocalRad;
  double get alturaGavetaPx => _alturaGavetaPx;
  double get elevacaoReferenciaCameraMetros => _elevacaoReferenciaCameraMetros;

  /// Define a cota de base local (em metros) para que zooms profundos (`LOD >= 3`) orbitem
  /// na altura real do vale/setor sem atravessar ou cortar maciços altos na lente perspectiva.
  void definirElevacaoReferenciaCamera(double metros) {
    final limpo = math.max(0.0, metros);
    if ((_elevacaoReferenciaCameraMetros - limpo).abs() < 0.5) return;
    _elevacaoReferenciaCameraMetros = limpo;
  }

  /// Raio aparente do planeta em pixels na escala exponencial contínua (`142px` -> `~93.000px`).
  double get raioAparentePx => 142.0 * math.pow(7.6, _lod).toDouble();

  /// Altitude física equivalente da câmera virtual acima da superfície em quilômetros.
  double get altitudeCameraKm => (220.0 / raioAparentePx) * 6371.0;

  /// Distância euclidiana 3D em quilômetros entre a câmera virtual e um objeto em `(latitude, longitude)`.
  double distanciaCameraObjetoKm({
    required double latitude,
    required double longitude,
  }) {
    final dLatKm = (latitude - _latitudeCentral) * 111.32;
    final dLonGraus =
        ((longitude - _longitudeCentral + 540.0) % 360.0) - 180.0;
    final dLonKm = dLonGraus * math.cos(latitude * _grausParaRad) * 111.32;
    final hKm = altitudeCameraKm;
    return math.sqrt(dLatKm * dLatKm + dLonKm * dLonKm + hKm * hKm);
  }

  /// Nível de detalhe progressivo (`0.0 .. 3.0`) calculado individualmente para um objeto pela distância à câmera.
  double nivelDetalheObjeto({
    required double latitude,
    required double longitude,
  }) {
    final distKm = distanciaCameraObjetoKm(
      latitude: latitude,
      longitude: longitude,
    );
    if (distKm < 12.0) {
      return 3.8 + (12.0 - distKm) / 12.0 * 0.85;
    }
    if (distKm < 65.0) {
      return 3.0 + (65.0 - distKm) / (65.0 - 12.0) * 0.8;
    }
    if (distKm < 280.0) {
      return 2.0 + (280.0 - distKm) / (280.0 - 65.0);
    }
    if (distKm < 1800.0) {
      return 1.0 + (1800.0 - distKm) / (1800.0 - 280.0);
    }
    return (1.0 - (distKm - 1800.0) / 4500.0).clamp(0.0, 0.99);
  }

  /// Índice discreto de nível de detalhe (`0` Globo, `1` Região, `2` Serra/Vale, `3` Maciço 3D).
  int get indiceLod {
    if (_lod < 0.75) return 0;
    if (_lod < 1.65) return 1;
    if (_lod < 2.50) return 2;
    return 3;
  }

  /// Fator contínuo (`0.0` satélite colorido -> `1.0` mapa viário P&B com oceano azul-sutil).
  double get fatorModoViario => smoothstep(1.30, 1.75, _lod);

  /// Indica se há voo parabólico ou inércia pós-soltura em andamento exigindo quadros de animação.
  bool get temAnimacaoAtiva =>
      _vooAtivo != null ||
      (!_interagindoManual &&
          (_velLon.abs() > 0.0002 || _velLat.abs() > 0.0002));

  void alternarModo3D() {
    definirModo3D(!_modo3D);
  }

  void definirModo3D(bool valor) {
    if (_modo3D == valor) return;
    _modo3D = valor;
    _velLon = 0.0;
    _velLat = 0.0;
    _latitudeCentral = _modo3D
        ? _latitudeCentral.clamp(-68.0, 68.0)
        : _limitarLatitude2D(_latitudeCentral, _ultimoTamanhoTela);
    notifyListeners();
  }

  void atualizarAlturaGaveta(double novaAlturaPx) {
    if ((_alturaGavetaPx - novaAlturaPx).abs() < 0.25) return;
    _alturaGavetaPx = novaAlturaPx;
    if (!_modo3D) {
      _latitudeCentral =
          _limitarLatitude2D(_latitudeCentral, _ultimoTamanhoTela);
    }
    notifyListeners();
  }

  /// Atualiza o nível contínuo de zoom (`lod`), puxando suavemente o centro apenas se o alvo já estiver próximo.
  void definirLod(
    double novoLod, {
    double? latAlvoSuave,
    double? lonAlvoSuave,
  }) {
    _vooAtivo = null;
    final proximo = novoLod.clamp(lodMinimo, lodMaximo);
    if (proximo > _lod &&
        proximo > 1.25 &&
        latAlvoSuave != null &&
        lonAlvoSuave != null &&
        (latAlvoSuave - _latitudeCentral).abs() < 0.85 &&
        (((lonAlvoSuave - _longitudeCentral + 540.0) % 360.0) - 180.0).abs() <
            0.85) {
      final puxada = smoothstep(1.25, 2.7, proximo) * 0.08;
      _latitudeCentral =
          _lerp(_latitudeCentral, latAlvoSuave, puxada).clamp(-68.0, 68.0);
      _longitudeCentral = GeometriaGeoideGlobo.normalizarLongitude(
        _lerp(_longitudeCentral, lonAlvoSuave, puxada),
      );
    }
    _lod = proximo;
    if (!_modo3D) {
      _latitudeCentral =
          _limitarLatitude2D(_latitudeCentral, _ultimoTamanhoTela);
    }
    notifyListeners();
  }

  /// Marca o início de um gesto contínuo de toque na superfície, inibindo inércia parasita sob o dedo.
  void iniciarInteracaoManual() {
    _interagindoManual = true;
    _teveMultiToqueNoGesto = false;
    _vooAtivo = null;
    _velLon = 0.0;
    _velLat = 0.0;
  }

  /// Processa simultaneamente translação (`dxPx`, `dyPx`) e mudança incremental de escala (`fatorEscala`).
  void aplicarGestoContinuo({
    required double dxPx,
    required double dyPx,
    required double fatorEscala,
    required Offset pontoFocalTela,
    required int contagemPonteiros,
    required Size tamanhoTela,
  }) {
    _ultimoTamanhoTela = tamanhoTela;
    if (contagemPonteiros >= 2) {
      _teveMultiToqueNoGesto = true;
    }
    if (dxPx.abs() > 0.001 || dyPx.abs() > 0.001) {
      _aplicarDeslocamentoPonteiro(
        dxPx: dxPx,
        dyPx: dyPx,
        tamanhoTela: tamanhoTela,
        gravarVelocidade: false,
      );
    }
    if ((fatorEscala - 1.0).abs() >= 1e-4) {
      aplicarZoomFocal(
        fatorEscala: fatorEscala,
        pontoFocalTela: pontoFocalTela,
        tamanhoTela: tamanhoTela,
      );
      return;
    }
    notifyListeners();
  }

  /// Finaliza o gesto manual e converte a velocidade física de soltura (quando 1 dedo) em inércia suave.
  void encerrarInteracaoManual({
    required Size tamanhoTela,
    Offset velocidadePixelsPorSegundo = Offset.zero,
  }) {
    _ultimoTamanhoTela = tamanhoTela;
    _interagindoManual = false;

    final rapidez = velocidadePixelsPorSegundo.distance;
    if (!_teveMultiToqueNoGesto &&
        rapidez > 65.0 &&
        !(_modo3D && _lod >= 2.35)) {
      final escalaMax = rapidez > 2200.0 ? 2200.0 / rapidez : 1.0;
      final vxFrame = velocidadePixelsPorSegundo.dx * escalaMax * 0.0166;
      final vyFrame = velocidadePixelsPorSegundo.dy * escalaMax * 0.0166;
      if (!_modo3D) {
        final escala2D = calcularEscala2D(tamanhoTela);
        _velLon = (-vxFrame / escala2D) / _grausParaRad;
        _velLat = (vyFrame / escala2D) / _grausParaRad;
      } else {
        final grausPorPixel = (1.0 / raioAparentePx) / _grausParaRad;
        final cosLat =
            math.max(0.25, math.cos(_latitudeCentral * _grausParaRad));
        _velLon = (-vxFrame * grausPorPixel) / cosLat;
        _velLat = vyFrame * grausPorPixel;
      }
    } else {
      _velLon = 0.0;
      _velLat = 0.0;
    }
    _teveMultiToqueNoGesto = false;
    notifyListeners();
  }

  /// Aplica fator multiplicativo de escala (`> 1` aproxima, `< 1` afasta) ancorando `pontoFocalTela` em 2D.
  void aplicarZoomFocal({
    required double fatorEscala,
    required Offset pontoFocalTela,
    required Size tamanhoTela,
  }) {
    _ultimoTamanhoTela = tamanhoTela;
    _vooAtivo = null;
    _velLon = 0.0;
    _velLat = 0.0;

    if (!_modo3D) {
      final cy = calcularCentroVerticalOptico(tamanhoTela);
      final escalaAntes = calcularEscala2D(tamanhoTela);
      _latitudeCentral =
          _limitarLatitude2D(_latitudeCentral, tamanhoTela, cy, escalaAntes);
      final lonAncora = _longitudeCentral +
          ((pontoFocalTela.dx - tamanhoTela.width * 0.5) / escalaAntes) /
              _grausParaRad;
      final latAncora = _latitudeCentral +
          ((cy - pontoFocalTela.dy) / escalaAntes) / _grausParaRad;

      final razaoTotal = _escalaMaxima2D / _escalaMinima2D(tamanhoTela);
      final deltaLod =
          lodMaximo * (math.log(fatorEscala) / math.log(razaoTotal));
      _lod = (_lod + deltaLod).clamp(lodMinimo, lodMaximo);

      final escalaDepois = calcularEscala2D(tamanhoTela);
      _longitudeCentral = GeometriaGeoideGlobo.normalizarLongitude(
        lonAncora -
            ((pontoFocalTela.dx - tamanhoTela.width * 0.5) / escalaDepois) /
                _grausParaRad,
      );
      _latitudeCentral = _limitarLatitude2D(
        latAncora -
            ((cy - pontoFocalTela.dy) / escalaDepois) / _grausParaRad,
        tamanhoTela,
        cy,
        escalaDepois,
      );
    } else {
      final deltaLod = math.log(fatorEscala) / math.log(7.6);
      _lod = (_lod + deltaLod).clamp(lodMinimo, lodMaximo);
    }
    notifyListeners();
  }

  /// Aplica arrasto de ponteiro: rastreia 1:1 no plano 2D e move continuamente a superfície 3D.
  void aplicarArrasto({
    required double dxPx,
    required double dyPx,
    Size? tamanhoTela,
  }) {
    final tela = tamanhoTela ?? _ultimoTamanhoTela;
    _ultimoTamanhoTela = tela;
    _aplicarDeslocamentoPonteiro(
      dxPx: dxPx,
      dyPx: dyPx,
      tamanhoTela: tela,
      gravarVelocidade: !_interagindoManual,
    );
    notifyListeners();
  }

  void _aplicarDeslocamentoPonteiro({
    required double dxPx,
    required double dyPx,
    required Size tamanhoTela,
    required bool gravarVelocidade,
  }) {
    _vooAtivo = null;
    if (!_modo3D) {
      final cy = calcularCentroVerticalOptico(tamanhoTela);
      final escala2D = calcularEscala2D(tamanhoTela);
      final dLon = (-dxPx / escala2D) / _grausParaRad;
      final dLat = (dyPx / escala2D) / _grausParaRad;
      _longitudeCentral =
          GeometriaGeoideGlobo.normalizarLongitude(_longitudeCentral + dLon);
      _latitudeCentral = _limitarLatitude2D(
        _latitudeCentral + dLat,
        tamanhoTela,
        cy,
        escala2D,
      );
      _velLon = gravarVelocidade ? dLon : 0.0;
      _velLat = gravarVelocidade ? dLat : 0.0;
      return;
    }

    final grausPorPixel = (1.0 / raioAparentePx) / _grausParaRad;
    final cosLat = math.max(0.25, math.cos(_latitudeCentral * _grausParaRad));
    final tilt = smoothstep(1.50, 2.75, _lod) * 0.66;
    final cosTilt = math.max(0.50, math.cos(tilt));

    final dLon = (-dxPx * grausPorPixel) / cosLat;
    final dLat = (dyPx / cosTilt) * grausPorPixel;
    _longitudeCentral =
        GeometriaGeoideGlobo.normalizarLongitude(_longitudeCentral + dLon);
    _latitudeCentral = (_latitudeCentral + dLat).clamp(-68.0, 68.0);
    final permiteInercia3D = gravarVelocidade && _lod < 2.35;
    _velLon = permiteInercia3D ? dLon : 0.0;
    _velLat = permiteInercia3D ? dLat : 0.0;
  }

  /// Inicia animação suave de voo parabólico (`Fly-To`) pelo menor arco longitudinal até um novo pico/escala.
  void iniciarVooParabolico({
    required double destinoLat,
    required double destinoLon,
    required double destinoLod,
  }) {
    _velLon = 0.0;
    _velLat = 0.0;
    final lonLimpo = GeometriaGeoideGlobo.normalizarLongitude(destinoLon);
    final dLat = destinoLat - _latitudeCentral;
    final dLonCurto =
        ((lonLimpo - _longitudeCentral + 540.0) % 360.0) - 180.0;
    final distGraus = math.sqrt(dLat * dLat + dLonCurto * dLonCurto);
    final recuo = distGraus > 2.2 ? (distGraus * 0.09).clamp(0.22, 0.80) : 0.0;
    final lodLimpo = destinoLod.clamp(lodMinimo, lodMaximo);

    final double latAlvoFinal;
    if (_modo3D) {
      latAlvoFinal = destinoLat.clamp(-68.0, 68.0);
    } else {
      final cy = calcularCentroVerticalOptico(_ultimoTamanhoTela);
      final minEsc = _escalaMinima2D(_ultimoTamanhoTela);
      final escDestino = minEsc *
          math.pow(_escalaMaxima2D / minEsc, lodLimpo / lodMaximo).toDouble();
      latAlvoFinal =
          _limitarLatitude2D(destinoLat, _ultimoTamanhoTela, cy, escDestino);
    }

    _vooAtivo = _AnimacaoVooParabolico(
      latInicial: _latitudeCentral,
      lonInicial: _longitudeCentral,
      lodInicial: _lod,
      latFinal: latAlvoFinal,
      deltaLonCurto: dLonCurto,
      lodFinal: lodLimpo,
      recuoArco: recuo,
    );
    notifyListeners();
  }

  /// Avança um passo temporal de simulação cinemática (`dtSegundos`), retornando `true` se ainda houver movimento.
  bool avancarQuadroFisica(double dtSegundos) {
    final passoNormalizado = (dtSegundos / 0.0166).clamp(0.25, 3.0);

    final voo = _vooAtivo;
    if (voo != null) {
      voo.progresso =
          (voo.progresso + 0.036 * passoNormalizado).clamp(0.0, 1.0);
      final t = voo.progresso;
      final ease = t < 0.5
          ? 4.0 * t * t * t
          : 1.0 - math.pow(-2.0 * t + 2.0, 3) / 2.0;

      _latitudeCentral = _lerp(voo.latInicial, voo.latFinal, ease);
      _longitudeCentral = GeometriaGeoideGlobo.normalizarLongitude(
        voo.lonInicial + voo.deltaLonCurto * ease,
      );
      final recuoMeioVoo = math.sin(math.pi * ease) * voo.recuoArco;
      _lod = (_lerp(voo.lodInicial, voo.lodFinal, ease) - recuoMeioVoo)
          .clamp(lodMinimo, lodMaximo);
      if (!_modo3D) {
        _latitudeCentral =
            _limitarLatitude2D(_latitudeCentral, _ultimoTamanhoTela);
      }

      if (voo.progresso >= 1.0) {
        _latitudeCentral = voo.latFinal;
        _longitudeCentral = GeometriaGeoideGlobo.normalizarLongitude(
          voo.lonInicial + voo.deltaLonCurto,
        );
        _lod = voo.lodFinal;
        _vooAtivo = null;
      }
      notifyListeners();
      return temAnimacaoAtiva;
    }

    if (!_interagindoManual &&
        (_velLon.abs() > 0.0002 || _velLat.abs() > 0.0002)) {
      _longitudeCentral = GeometriaGeoideGlobo.normalizarLongitude(
        _longitudeCentral + _velLon * passoNormalizado,
      );
      final proxLat = _latitudeCentral + _velLat * passoNormalizado;
      _latitudeCentral = _modo3D
          ? proxLat.clamp(-68.0, 68.0)
          : _limitarLatitude2D(proxLat, _ultimoTamanhoTela);
      final amortecimento = math.pow(0.90, passoNormalizado).toDouble();
      _velLon *= amortecimento;
      _velLat *= amortecimento;
      if (_velLon.abs() <= 0.0002 && _velLat.abs() <= 0.0002) {
        _velLon = 0.0;
        _velLat = 0.0;
      }
      notifyListeners();
      return temAnimacaoAtiva;
    }

    return false;
  }

  /// Centro vertical óptico em pixels compensado pela altura instantânea da gaveta deslizante.
  double calcularCentroVerticalOptico(Size tamanhoTela) {
    final alturaUtil =
        tamanhoTela.height - math.min(340.0, _alturaGavetaPx * 0.74);
    final baseCy = math.max(150.0, alturaUtil * 0.52 + 16.0);
    final compensacaoInclinacao =
        _modo3D ? smoothstep(1.6, 2.85, _lod) * 42.0 : 0.0;
    return baseCy + compensacaoInclinacao;
  }

  double _escalaMinima2D(Size tamanhoTela) {
    final cy = calcularCentroVerticalOptico(tamanhoTela);
    final maiorMeiaAltura = math.max(cy, tamanhoTela.height - cy);
    final minVertical = maiorMeiaAltura / (64.0 * _grausParaRad);
    final minHorizontal = tamanhoTela.width / (360.0 * _grausParaRad);
    return math.max(minVertical, minHorizontal);
  }

  double get _escalaMaxima2D =>
      142.0 * math.pow(7.6, lodMaximo).toDouble() * 1.04;

  /// Escala em pixels por radiano no modo 2D, estritamente monótona em todo o intervalo `LOD 0..lodMaximo`.
  double calcularEscala2D(Size tamanhoTela) {
    _ultimoTamanhoTela = tamanhoTela;
    final minEsc = _escalaMinima2D(tamanhoTela);
    final maxEsc = _escalaMaxima2D;
    final t = (_lod / lodMaximo).clamp(0.0, 1.0);
    return minEsc * math.pow(maxEsc / minEsc, t).toDouble();
  }

  double _limitarLatitude2D(
    double latitudeAlvo,
    Size tamanhoTela, [
    double? cyPre,
    double? escalaPre,
  ]) {
    final cy = cyPre ?? calcularCentroVerticalOptico(tamanhoTela);
    final escala2D = escalaPre ?? calcularEscala2D(tamanhoTela);
    final limiteSuperior = 85.0 - (cy / escala2D) / _grausParaRad;
    final limiteInferior =
        -85.0 + ((tamanhoTela.height - cy) / escala2D) / _grausParaRad;
    return latitudeAlvo.clamp(limiteInferior, limiteSuperior);
  }

  /// Converte um ponto em pixels na tela para `(latitude, longitude)` exatos no plano 2D atual.
  ({double latitude, double longitude}) converterTelaParaCoordenada2D({
    required Offset pontoTela,
    required Size tamanhoTela,
  }) {
    _ultimoTamanhoTela = tamanhoTela;
    final cy = calcularCentroVerticalOptico(tamanhoTela);
    final escala2D = calcularEscala2D(tamanhoTela);
    final latCentro =
        _limitarLatitude2D(_latitudeCentral, tamanhoTela, cy, escala2D);
    final lon = GeometriaGeoideGlobo.normalizarLongitude(
      _longitudeCentral +
          ((pontoTela.dx - tamanhoTela.width * 0.5) / escala2D) / _grausParaRad,
    );
    final lat = (latCentro + ((cy - pontoTela.dy) / escala2D) / _grausParaRad)
        .clamp(-85.0, 85.0);
    return (latitude: lat, longitude: lon);
  }

  /// Raio normalizado do Geoide Terrestre (`WGS84 + NASA EGM96 / GRACE`).
  static double raioNormalizadoGeoide({
    required double latitude,
    required double longitude,
  }) =>
      GeometriaGeoideGlobo.raioNormalizadoGeoide(
        latitude: latitude,
        longitude: longitude,
      );

  /// Constrói o contorno fechado da silhueta do Geoide Terrestre na câmera atual.
  Path construirCaminhoSilhuetaGeoide(
    Size tamanhoTela, {
    double escalaExtra = 1.0,
    int segmentos = 108,
  }) =>
      GeometriaGeoideGlobo.construirSilhuetaGeoide(
        tamanhoTela: tamanhoTela,
        centroVerticalOpticoPx: calcularCentroVerticalOptico(tamanhoTela),
        raioAparentePx: raioAparentePx,
        latitudeCentral: _latitudeCentral,
        longitudeCentral: _longitudeCentral,
        lod: _lod,
        escalaExtra: escalaExtra,
        segmentos: segmentos,
      );

  /// Projeta continuamente qualquer coordenada `(latitude, longitude, elevacaoMetros)` do Geoide ao Cume 3D.
  PontoProjetadoTela projetarCoordenada({
    required double latitude,
    required double longitude,
    required double elevacaoMetros,
    required Size tamanhoTela,
    bool estenderBordaHorizonte = false,
  }) {
    _ultimoTamanhoTela = tamanhoTela;
    final cy = calcularCentroVerticalOptico(tamanhoTela);

    if (!_modo3D) {
      final escala2D = calcularEscala2D(tamanhoTela);
      _latitudeCentral =
          _limitarLatitude2D(_latitudeCentral, tamanhoTela, cy, escala2D);
      var dLon = longitude - _longitudeCentral;
      if (!estenderBordaHorizonte) {
        dLon = ((dLon + 540.0) % 360.0) - 180.0;
      }
      final dLat = latitude - _latitudeCentral;
      return PontoProjetadoTela(
        x: tamanhoTela.width * 0.5 + (dLon * _grausParaRad) * escala2D,
        y: cy - (dLat * _grausParaRad) * escala2D,
        profundidade: -elevacaoMetros,
        visivel: true,
      );
    }

    return GeometriaGeoideGlobo.projetarCoordenada3D(
      latitude: latitude,
      longitude: longitude,
      elevacaoMetros: elevacaoMetros,
      latitudeCentral: _latitudeCentral,
      longitudeCentral: _longitudeCentral,
      lod: _lod,
      raioAparentePx: raioAparentePx,
      centroVerticalOpticoPx: cy,
      elevacaoReferenciaCameraMetros: _elevacaoReferenciaCameraMetros,
      tamanhoTela: tamanhoTela,
      estenderBordaHorizonte: estenderBordaHorizonte,
    );
  }

  /// Agrupa picos por sigla de estado (`UF`) para exibição sem poluição no `LOD 0`.
  static List<ClusterEstadoGlobo> agruparPorEstado(
    Iterable<({String id, String uf, double lat, double lon})> picos,
  ) =>
      GeometriaGeoideGlobo.agruparPorEstado(picos);

  /// Seleciona os identificadores cujos rótulos textuais não se sobrepõem.
  static Set<String> selecionarIdsSemColisaoRotulos(
    List<({String id, String nome, Offset posicao, bool prioritario})>
    candidatos, {
    double alturaCaixa = 26.0,
  }) =>
      GeometriaGeoideGlobo.selecionarIdsSemColisaoRotulos(
        candidatos,
        alturaCaixa: alturaCaixa,
      );

  /// Interpolação Hermite cúbica suave `smoothstep(e0, e1, x)`.
  static double smoothstep(double borda0, double borda1, double x) =>
      GeometriaGeoideGlobo.smoothstep(borda0, borda1, x);

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
