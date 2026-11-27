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

