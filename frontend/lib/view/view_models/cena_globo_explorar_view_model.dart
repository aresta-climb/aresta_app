// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

import '../../data/modelos/modelos_relevo_topografico.dart';
import '../../services/clima/servico_tiles_elevacao_terrarium.dart';
import '../../utils/construtor_rede_viaria_aresta.dart';
import '../../utils/extrator_curvas_nivel_mundo.dart';
import '../../utils/geometria_clipping_mapa.dart';
import '../../widgets/explorar/componentes_marcador_globo.dart';
import '../../widgets/explorar/controlador_camera_globo.dart';
import '../../widgets/explorar/malha_relevo_lod.dart';

/// ViewModel de apresentação da cena interativa do Globo/Mapa na aba `Explorar` (MVVM).
///
/// Concentra hidratação assíncrona dos assets geográficos, busca sob demanda de tiles SRTM
/// (`AWS Open Data Terrarium`), memoização em coordenadas fixas do mundo de [ConjuntoCurvasNivelMundo]
/// e [RedeViariaArestaGlobo], máquina de estados da luz viária Aresta, onda sonar e regras de câmera.
class CenaGloboExplorarViewModel extends ChangeNotifier {
  static const double duracaoIdaLuzViariaSegundos = 1.60;
  static const double duracaoVoltaLuzViariaSegundos = 1.35;

  final Future<MalhaGeograficaGlobo> Function() _carregarMalha;
  final Future<ui.Image> Function() _carregarTextura;
  final ServicoTilesElevacaoTerrarium _servicoElevacao;

  MalhaGeograficaGlobo? _malha;
  ui.Image? _texturaNasa;
  MalhaGeograficaGlobo? _malhaMemoizada;
  int _assinaturaPicosMemoizada = -1;
  RedeViariaArestaGlobo? _redeViariaMemoizada;

  ConjuntoCurvasNivelMundo? _curvasMemoizadas;
  int _assinaturaPicosCurvas = -1;

  String? _sonarPicoId;
  String? _sonarBolhaId;
  double _progressoSonar = 1.0;
  double _faseTempestadeSegundos = 0.0;
  double _alvoLuzViaria = 0.0;
  double _progressoLuzViaria = 0.0;
  bool _animacoesAmbienteAtivas = true;
  bool _hidratandoAssets = false;
  bool _descartado = false;

  final ValueNotifier<double> faseEstrelasSegundos = ValueNotifier<double>(0.0);
  Timer? _timerEstrelasAmbiente;

  CenaGloboExplorarViewModel({
    required double lodInicialCamera,
    Future<MalhaGeograficaGlobo> Function()? carregarMalha,
    Future<ui.Image> Function()? carregarTextura,
    ServicoTilesElevacaoTerrarium? servicoElevacao,
  })  : _carregarMalha =
            carregarMalha ?? MalhaGeograficaGlobo.carregarDoAssetBundle,
        _carregarTextura =
            carregarTextura ?? TexturaGloboNasa.carregarDoAssetBundle,
        _servicoElevacao =
            servicoElevacao ?? ServicoTilesElevacaoTerrarium.instancia {
    if (lodInicialCamera >= ControladorCameraGlobo.limiarAtivacaoLuzViaria) {
      _alvoLuzViaria = 1.0;
      _progressoLuzViaria = 1.0;
    }
    _malha = carregarMalha == null ? MalhaGeograficaGlobo.cacheMemoria : null;
    _texturaNasa =
        carregarTextura == null ? TexturaGloboNasa.cacheMemoria : null;
    _servicoElevacao.addListener(_aoAtualizarTilesElevacao);
  }

  void _aoAtualizarTilesElevacao() {
    if (!_descartado && !_hidratandoAssets) notifyListeners();
  }

  MalhaGeograficaGlobo? get malha => _malha;
  ui.Image? get texturaNasa => _texturaNasa;
  String? get sonarPicoId => _sonarPicoId;
  String? get sonarBolhaId => _sonarBolhaId;
  double get progressoSonar => _progressoSonar;
  double get faseTempestadeSegundos => _faseTempestadeSegundos;
  double get alvoLuzViaria => _alvoLuzViaria;
  double get progressoLuzViaria => _progressoLuzViaria;
  bool get animacoesAmbienteAtivas => _animacoesAmbienteAtivas;

  /// Hidrata assincronamente a malha vetorial, a textura NASA e a grade regional SRTM offline.
  Future<void> inicializarAssetsSeNecessario() async {
    final precisaMalhaOuTextura = _malha == null || _texturaNasa == null;
    if (!precisaMalhaOuTextura && _servicoElevacao.inicializado) return;

