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

    _hidratandoAssets = true;
    try {
      final futuros = <Future<Object?>>[
        if (precisaMalhaOuTextura) _carregarMalha(),
        if (precisaMalhaOuTextura) _carregarTextura(),
        if (!_servicoElevacao.inicializado) _servicoElevacao.inicializar(),
      ];
      final resultados = await Future.wait<Object?>(futuros);
      if (_descartado) return;
      if (precisaMalhaOuTextura) {
        _malha = resultados[0] as MalhaGeograficaGlobo;
        _texturaNasa = resultados[1] as ui.Image;
      }
    } finally {
      _hidratandoAssets = false;
    }
    notifyListeners();
  }

  /// Amostra sincronamente em `O(1)` a altitude SRTM real (tile Terrarium ou grade regional offline).
  double? amostrarElevacaoReal(double latitude, double longitude) =>
      _servicoElevacao.amostrarElevacaoReal(
        latitude: latitude,
        longitude: longitude,
      );

  /// Obtém em `O(1)` a [RedeViariaArestaGlobo] memoizada nesta instância para a malha e picos atuais.
  RedeViariaArestaGlobo? obterRedeViaria(List<PicoRelevoReferencia> picos) {
    final malhaAtual = _malha;
    if (malhaAtual == null) return null;
    final assinatura = ConstrutorRedeViariaAresta.calcularAssinaturaPicos(picos);
    if (_redeViariaMemoizada != null &&
        identical(_malhaMemoizada, malhaAtual) &&
        _assinaturaPicosMemoizada == assinatura) {
      return _redeViariaMemoizada;
    }
    final construida = ConstrutorRedeViariaAresta.construir(
      rodovias: malhaAtual.rodoviasProximas,
      localidades: malhaAtual.localidadesProximas,
      picos: picos,
    );
    _malhaMemoizada = malhaAtual;
    _assinaturaPicosMemoizada = assinatura;
    _redeViariaMemoizada = construida;
    return construida;
  }

  /// Obtém as curvas de nível ancoradas em coordenadas fixas do mundo para a região visível,
  /// solicitando tiles Terrarium sob demanda e reutilizando o cache `O(1)` durante o movimento da câmera.
  ConjuntoCurvasNivelMundo? obterCurvasNivelVisiveis({
    required ControladorCameraGlobo controlador,
    required ui.Size tamanhoTela,
    required List<PicoRelevoReferencia> picosReferencia,
  }) {
    final lod = controlador.lod;
    if (lod < 1.90 || tamanhoTela.isEmpty) return null;

    final janela = GeometriaClippingMapa.calcularJanelaVisivelCamera(
      modo3D: controlador.modo3D,
      latitudeCentral: controlador.latitudeCentral,
      longitudeCentral: controlador.longitudeCentral,
      lod: lod,
      raioAparentePx: controlador.raioAparentePx,
      escala2D:
          controlador.modo3D ? 1.0 : controlador.calcularEscala2D(tamanhoTela),
      tamanhoTela: tamanhoTela,
      fatorMargem: 1.08,
    );

    _servicoElevacao.solicitarTilesVisiveis(
      minLat: janela.minLat,
      maxLat: janela.maxLat,
      minLon: janela.minLon,
      maxLon: janela.maxLon,
      lod: lod,
    );

    final nivel = ExtratorCurvasNivelMundo.resolverNivelDetalhe(lod);
    final bloco = ExtratorCurvasNivelMundo.calcularGradeBlocoMundo(
      janela: janela,
      nivelDetalhe: nivel,
    );
    final versao = _servicoElevacao.versaoDados;
    final assinaturaPicos =
        ConstrutorRedeViariaAresta.calcularAssinaturaPicos(picosReferencia);

    final existente = _curvasMemoizadas;
    if (existente != null &&
        existente.chaveBloco == bloco.chaveBloco &&
        existente.nivelDetalhe == nivel &&
        existente.versaoDadosElevacao == versao &&
        _assinaturaPicosCurvas == assinaturaPicos) {
      return existente;
    }

    final malhaAtual = _malha;
    final extraido = ExtratorCurvasNivelMundo.extrairCurvasBloco(
      janela: janela,
      nivelDetalhe: nivel,
      versaoDadosElevacao: versao,
      picosReferencia: picosReferencia,
      amostrarElevacaoMetros: (lat, lon) {
        final ehTerra = malhaAtual?.contemPontoTerrestre(
          latitude: lat,
          longitude: lon,
        );
        return GeradorRelevoLod.amostrarTerrenoRegionalContinuo(
          latitude: lat,
          longitude: lon,
          picosReferencia: picosReferencia,
          ehTerraConfirmada: ehTerra,
          amostradorElevacaoReal: amostrarElevacaoReal,
        );
      },
    );

    _curvasMemoizadas = extraido;
    _assinaturaPicosCurvas = assinaturaPicos;
    return extraido;
  }

  /// Atualiza a preferência de acessibilidade (`MediaQuery.disableAnimations`).
  void atualizarPreferenciaAnimacoesAmbiente(bool ativas) {
    _animacoesAmbienteAtivas = ativas;
  }

  /// Indica se a cena requer quadros contínuos de `Ticker` no instante atual.
  bool precisaAnimarQuadro({
    required ControladorCameraGlobo controlador,
    required bool temFenomenoAoVivo,
  }) {
    final precisaSonar = _progressoSonar < 1.0;
    final precisaLuzViaria = (_progressoLuzViaria - _alvoLuzViaria).abs() > 1e-4;
    final precisaFenomenos = _animacoesAmbienteAtivas && temFenomenoAoVivo;
    return controlador.temAnimacaoAtiva ||
        precisaSonar ||
        precisaLuzViaria ||
        precisaFenomenos;
  }

  /// Sincroniza o gatilho bidirecional da luz viária e o timer esparso das estrelas de fundo.
  void sincronizarEstadoCena({
    required ControladorCameraGlobo controlador,
    required bool tickerAtivo,
  }) {
    _atualizarGatilhoLuzViaria(controlador.lod);
    final deveAnimarEstrelas = _animacoesAmbienteAtivas &&
        controlador.modo3D &&
        controlador.raioAparentePx < 760.0;
    if (deveAnimarEstrelas) {
      _timerEstrelasAmbiente ??= Timer.periodic(
        const Duration(milliseconds: 150),
        (_) {
          if (!tickerAtivo && !_descartado) {
            faseEstrelasSegundos.value =
                (faseEstrelasSegundos.value + 0.15) % 36000.0;
          }
        },
      );
    } else {
      _timerEstrelasAmbiente?.cancel();
      _timerEstrelasAmbiente = null;
    }
  }

  /// Avança um passo físico de simulação (`dtSegundos`) para câmera, luz viária, clima e sonar.
  void avancarQuadro({
    required double dtSegundos,
    required ControladorCameraGlobo controlador,
    required bool temFenomenoAoVivo,
  }) {
    controlador.avancarQuadroFisica(dtSegundos);
    _atualizarGatilhoLuzViaria(controlador.lod);

    if (_animacoesAmbienteAtivas &&
        controlador.modo3D &&
        controlador.raioAparentePx < 760.0) {
      faseEstrelasSegundos.value =
          (faseEstrelasSegundos.value + dtSegundos) % 36000.0;
    }
    if (temFenomenoAoVivo) {
      _faseTempestadeSegundos = (_faseTempestadeSegundos + dtSegundos) % 3600.0;
    }
    if (_progressoSonar < 1.0) {
      _progressoSonar = (_progressoSonar + dtSegundos * 2.2).clamp(0.0, 1.0);
    }
    if (_progressoLuzViaria < _alvoLuzViaria) {
      _progressoLuzViaria =
          (_progressoLuzViaria + dtSegundos / duracaoIdaLuzViariaSegundos)
              .clamp(0.0, _alvoLuzViaria);
    } else if (_progressoLuzViaria > _alvoLuzViaria) {
      _progressoLuzViaria =
          (_progressoLuzViaria - dtSegundos / duracaoVoltaLuzViariaSegundos)
              .clamp(_alvoLuzViaria, 1.0);
    }
  }

  void _atualizarGatilhoLuzViaria(double lodAtual) {
    if (_alvoLuzViaria < 0.5 &&
        lodAtual >= ControladorCameraGlobo.limiarAtivacaoLuzViaria) {
      _alvoLuzViaria = 1.0;
      if (!_animacoesAmbienteAtivas) _progressoLuzViaria = 1.0;
    } else if (_alvoLuzViaria > 0.5 &&
        lodAtual < ControladorCameraGlobo.limiarDesativacaoLuzViaria) {
      _alvoLuzViaria = 0.0;
      if (!_animacoesAmbienteAtivas) _progressoLuzViaria = 0.0;
    }
  }

  /// Resolve o pico atualmente em foco (selecionado ou mais próximo do centro óptico).
  MarcadorPicoGlobo? resolverPicoFocado({
    required List<MarcadorPicoGlobo> picos,
    required String? picoSelecionadoId,
    required ControladorCameraGlobo controlador,
  }) {
    if (picos.isEmpty) return null;
    if (picoSelecionadoId != null) {
      for (final p in picos) {
        if (p.id == picoSelecionadoId) return p;
      }
    }
    final latC = controlador.latitudeCentral;
    final lonC = controlador.longitudeCentral;
    MarcadorPicoGlobo? maisProximo;
    var menorDistGraus2 = 0.72;
    for (final p in picos) {
      final dLat = p.latitude - latC;
      final dLon = ((p.longitude - lonC + 540.0) % 360.0) - 180.0;
      final d2 = dLat * dLat + dLon * dLon;
      if (d2 < menorDistGraus2) {
        menorDistGraus2 = d2;
        maisProximo = p;
      }
    }
    return maisProximo;
  }

  /// Dispara onda sonar e voo parabólico escalonado ao tocar em um marcador de pico no mapa.
  void selecionarPicoNoMapa({
    required MarcadorPicoGlobo pico,
    required String? picoSelecionadoAtualId,
    required ControladorCameraGlobo controlador,
    double? lodExplicito,
  }) {
    _sonarPicoId = pico.id;
    _sonarBolhaId = pico.umidade.bolhaIdAssociada;
    _progressoSonar = 0.0;

    controlador.definirElevacaoReferenciaCamera(
      pico.altitudeBaseMetros.toDouble(),
    );

    final lodAtual = controlador.lod;
    final jaEstavaSelecionado = pico.id == picoSelecionadoAtualId;
    final novoLod = lodExplicito ??
        (jaEstavaSelecionado
            ? (lodAtual < 2.75 ? 3.55 : (lodAtual < 3.90 ? 4.20 : lodAtual))
            : (lodAtual < 1.35
                ? 2.15
                : (lodAtual < 2.65 ? 3.35 : math.max(lodAtual, 3.65))));

    controlador.iniciarVooParabolico(
      destinoLat: pico.latitude,
      destinoLon: pico.longitude,
      destinoLod: novoLod,
    );
  }

  /// Calcula e dispara o voo de aproximação por duplo-toque em 2D (no ponto tocado) ou 3D (no pico focado).
  void executarDuploToqueMapa({
    required ui.Size tamanhoTela,
    required ui.Offset? posicaoToque,
    required MarcadorPicoGlobo? picoFocado,
    required ControladorCameraGlobo controlador,
  }) {
    final proximoLod =
        (controlador.lod + 0.90).clamp(0.0, ControladorCameraGlobo.lodMaximo);
    if (!controlador.modo3D && posicaoToque != null) {
      final coord = controlador.converterTelaParaCoordenada2D(
        pontoTela: posicaoToque,
        tamanhoTela: tamanhoTela,
      );
      controlador.iniciarVooParabolico(
        destinoLat: coord.latitude,
        destinoLon: coord.longitude,
        destinoLod: proximoLod,
      );
      return;
    }
    controlador.iniciarVooParabolico(
      destinoLat: picoFocado?.latitude ?? controlador.latitudeCentral,
      destinoLon: picoFocado?.longitude ?? controlador.longitudeCentral,
      destinoLod: proximoLod,
    );
  }

  /// Retorna a câmera para a visão orbital padrão sobre o Brasil/Minas Gerais.
  void resetarVisaoGlobo(ControladorCameraGlobo controlador) {
    controlador.iniciarVooParabolico(
      destinoLat: -18.5,
      destinoLon: -44.5,
      destinoLod: 0.22,
    );
  }

  @override
  void dispose() {
    _descartado = true;
    _servicoElevacao.removeListener(_aoAtualizarTilesElevacao);
    _timerEstrelasAmbiente?.cancel();
    faseEstrelasSegundos.dispose();
    super.dispose();
  }
}
