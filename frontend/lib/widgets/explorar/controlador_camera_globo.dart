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

