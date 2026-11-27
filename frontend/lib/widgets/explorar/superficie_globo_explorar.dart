// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../data/modelos/modelos_clima_pico.dart';
import '../../view/view_models/cena_globo_explorar_view_model.dart';
import 'botao_camada_clima_mapa.dart';
import 'camada_marcadores_globo_explorar.dart';
import 'controlador_camera_globo.dart';
import 'pintor_campo_estrelas_globo.dart';
import 'pintor_planeta_globo.dart';

export 'camada_marcadores_globo_explorar.dart';
export 'pintor_campo_estrelas_globo.dart';

/// Superfície interativa declarativa (Dumb UI) do Globo 3D/2D e Relevo DEM na aba `Explorar`.
///
/// Delega toda a hidratação de assets, memoização da rede viária, progressão/retração da luz
/// laranja Aresta e regras de seleção/foco para [CenaGloboExplorarViewModel] e [ControladorCameraGlobo],
/// limitando-se a acoplar `Ticker`, gestos brutos e a pilha visual de camadas.
class SuperficieGloboExplorar extends StatefulWidget {
  final ControladorCameraGlobo controlador;
  final List<MarcadorPicoGlobo> picos;
  final List<BolhaAtivaRenderizavel> bolhasAtivas;
  final List<BolhaIncendioAtivaRenderizavel> incendiosAtivos;
  final String? picoSelecionadoId;
  final ValueListenable<double>? alturaGavetaNotificador;
  final ValueChanged<String?> aoSelecionarPicoNoMapa;
  final ({double latitude, double longitude})? localizacaoUsuario;
  final VoidCallback? aoCentralizarNoUsuario;
  final bool buscandoLocalizacaoUsuario;
  final bool camadaClimaAtiva;
  final ValueChanged<bool>? aoAlterarCamadaClima;
  final double recuoSuperiorControles;
  final CenaGloboExplorarViewModel? cenaViewModel;

  const SuperficieGloboExplorar({
    super.key,
    required this.controlador,
    required this.picos,
    required this.bolhasAtivas,
    this.incendiosAtivos = const [],
    required this.picoSelecionadoId,
    required this.aoSelecionarPicoNoMapa,
    this.alturaGavetaNotificador,
    this.localizacaoUsuario,
    this.aoCentralizarNoUsuario,
    this.buscandoLocalizacaoUsuario = false,
    this.camadaClimaAtiva = false,
    this.aoAlterarCamadaClima,
    this.recuoSuperiorControles = 62.0,
    this.cenaViewModel,
  });

  @override
  State<SuperficieGloboExplorar> createState() =>
      _SuperficieGloboExplorarState();
}

class _SuperficieGloboExplorarState extends State<SuperficieGloboExplorar>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late CenaGloboExplorarViewModel _cena;
  bool _cenaPropria = false;
  Duration? _ultimoInstante;
  double _escalaAnteriorPinch = 1.0;
  Offset? _posicaoUltimoToqueDuplo;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_aoBaterTicker);
    _vincularCenaViewModel(widget.cenaViewModel);
    widget.controlador.addListener(_sincronizarCena);
    widget.alturaGavetaNotificador?.addListener(_aoMudarAlturaGaveta);
    if (widget.alturaGavetaNotificador != null) {
      widget.controlador
          .atualizarAlturaGaveta(widget.alturaGavetaNotificador!.value);
    }
    _sincronizarCena();
  }

  void _vincularCenaViewModel(CenaGloboExplorarViewModel? externo) {
    if (externo != null) {
      _cena = externo;
      _cenaPropria = false;
    } else {
      _cena = CenaGloboExplorarViewModel(
        lodInicialCamera: widget.controlador.lod,
      );
      _cenaPropria = true;
    }
    _cena.addListener(_aoNotificarCena);
    unawaited(_cena.inicializarAssetsSeNecessario());
  }

  void _aoNotificarCena() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cena.atualizarPreferenciaAnimacoesAmbiente(
      !(MediaQuery.maybeDisableAnimationsOf(context) ?? false),
    );
    _sincronizarCena();
  }

  @override
  void didUpdateWidget(covariant SuperficieGloboExplorar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controlador != widget.controlador) {
      oldWidget.controlador.removeListener(_sincronizarCena);
      widget.controlador.addListener(_sincronizarCena);
    }
    if (oldWidget.alturaGavetaNotificador != widget.alturaGavetaNotificador) {
      oldWidget.alturaGavetaNotificador?.removeListener(_aoMudarAlturaGaveta);
      widget.alturaGavetaNotificador?.addListener(_aoMudarAlturaGaveta);
    }
    if (oldWidget.cenaViewModel != widget.cenaViewModel) {
      _cena.removeListener(_aoNotificarCena);
      if (_cenaPropria) _cena.dispose();
      _vincularCenaViewModel(widget.cenaViewModel);
    }
    _sincronizarCena();
  }

  @override
  void dispose() {
    widget.controlador.removeListener(_sincronizarCena);
    widget.alturaGavetaNotificador?.removeListener(_aoMudarAlturaGaveta);
    _cena.removeListener(_aoNotificarCena);
    if (_cenaPropria) _cena.dispose();
    _ticker.dispose();
    super.dispose();
  }

  void _aoMudarAlturaGaveta() {
    final h = widget.alturaGavetaNotificador?.value;
    if (h != null) widget.controlador.atualizarAlturaGaveta(h);
  }

  bool get _temFenomenoAoVivo =>
      widget.bolhasAtivas.isNotEmpty || widget.incendiosAtivos.isNotEmpty;

  void _sincronizarCena() {
    _cena.sincronizarEstadoCena(
      controlador: widget.controlador,
      tickerAtivo: _ticker.isActive,
    );
    final precisa = _cena.precisaAnimarQuadro(
      controlador: widget.controlador,
      temFenomenoAoVivo: _temFenomenoAoVivo,
    );
    if (precisa && !_ticker.isActive) {
      _ultimoInstante = null;
      _ticker.start();
    } else if (!precisa && _ticker.isActive) {
      _ticker.stop();
    }
    if (mounted) setState(() {});
  }

  void _aoBaterTicker(Duration decorrido) {
    final anterior = _ultimoInstante;
    _ultimoInstante = decorrido;
    final dt = anterior == null
        ? 0.0166
        : ((decorrido - anterior).inMicroseconds / 1e6).clamp(0.004, 0.05);

    _cena.avancarQuadro(
      dtSegundos: dt,
      controlador: widget.controlador,
      temFenomenoAoVivo: _temFenomenoAoVivo,
    );

    final continua = _cena.precisaAnimarQuadro(
      controlador: widget.controlador,
      temFenomenoAoVivo: _temFenomenoAoVivo,
    );
    if (!continua && _ticker.isActive) {
      _ticker.stop();
    }
    if (mounted) setState(() {});
  }

  void _aoSelecionarPico(MarcadorPicoGlobo pico, {double? lodExplicito}) {
    _cena.selecionarPicoNoMapa(
      pico: pico,
      picoSelecionadoAtualId: widget.picoSelecionadoId,
      controlador: widget.controlador,
      lodExplicito: lodExplicito,
    );
    widget.aoSelecionarPicoNoMapa(pico.id);
    _sincronizarCena();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricoes) {
        final tamanho = Size(restricoes.maxWidth, restricoes.maxHeight);
        final focado = _cena.resolverPicoFocado(
          picos: widget.picos,
          picoSelecionadoId: widget.picoSelecionadoId,
          controlador: widget.controlador,
        );
        if (focado != null) {
          widget.controlador.definirElevacaoReferenciaCamera(
            focado.altitudeBaseMetros.toDouble(),
          );
        }
        final referenciasRelevo = widget.picos
            .map((p) => p.paraReferenciaRelevo())
            .toList(growable: false);
        final redeViaria = _cena.obterRedeViaria(referenciasRelevo);
        final curvasMundo = _cena.obterCurvasNivelVisiveis(
          controlador: widget.controlador,
          tamanhoTela: tamanho,
          picosReferencia: referenciasRelevo,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  key: const Key('camada_estrelas_globo'),
                  child: CustomPaint(
                    size: tamanho,
                    painter: PintorCampoEstrelasGlobo(
                      controlador: widget.controlador,
                      tempoSegundosListenable: _cena.faseEstrelasSegundos,
                    ),
                  ),
                ),
              ),
            ),
            Listener(
              behavior: HitTestBehavior.translucent,
              onPointerSignal: (evento) {
                if (evento is PointerScrollEvent) {
                  widget.controlador.aplicarZoomFocal(
                    fatorEscala: math.exp(-evento.scrollDelta.dy * 0.0038),
                    pontoFocalTela: evento.localPosition,
                    tamanhoTela: tamanho,
                  );
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onScaleStart: (_) {
                  _escalaAnteriorPinch = 1.0;
                  widget.controlador.iniciarInteracaoManual();
                },
                onScaleUpdate: (detalhes) {
                  final fatorIncremental =
                      detalhes.scale / _escalaAnteriorPinch;
                  _escalaAnteriorPinch = detalhes.scale;
                  widget.controlador.aplicarGestoContinuo(
                    dxPx: detalhes.focalPointDelta.dx,
                    dyPx: detalhes.focalPointDelta.dy,
                    fatorEscala: fatorIncremental,
                    pontoFocalTela: detalhes.localFocalPoint,
                    contagemPonteiros: detalhes.pointerCount,
                    tamanhoTela: tamanho,
                  );
                },
                onScaleEnd: (detalhes) {
                  widget.controlador.encerrarInteracaoManual(
                    velocidadePixelsPorSegundo:
                        detalhes.velocity.pixelsPerSecond,
                    tamanhoTela: tamanho,
                  );
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (widget.picoSelecionadoId != null) {
                          widget.aoSelecionarPicoNoMapa(null);
                        }
                      },
                      onDoubleTapDown: (detalhes) {
                        _posicaoUltimoToqueDuplo = detalhes.localPosition;
                      },
                      onDoubleTap: () => _cena.executarDuploToqueMapa(
                        tamanhoTela: tamanho,
                        posicaoToque: _posicaoUltimoToqueDuplo,
                        picoFocado: focado,
                        controlador: widget.controlador,
                      ),
                      child: RepaintBoundary(
                        child: CustomPaint(
                          size: tamanho,
                          painter: PintorPlanetaGlobo(
                            controlador: widget.controlador,
                            malha: _cena.malha,
                            redeViaria: redeViaria,
                            curvasMundo: curvasMundo,
                            amostradorElevacaoReal: (lat, lon) =>
                                _cena.amostrarElevacaoReal(
                                  lat,
                                  lon,
                                  lod: widget.controlador.lod,
                                ),
                            texturaNasa: _cena.texturaNasa,
                            picosReferencia: referenciasRelevo,
                            sonarPico: _cena.sonarPicoId == null
                                ? null
                                : widget.picos
                                    .where((p) => p.id == _cena.sonarPicoId)
                                    .firstOrNull,
                            progressoSonar: _cena.progressoSonar,
                            progressoLuzViaria: _cena.progressoLuzViaria,
                          ),
                        ),
                      ),
                    ),
                    ...CamadaMarcadoresGloboExplorar.construirCamadas(
                      context: context,
                      tamanho: tamanho,
                      controlador: widget.controlador,
                      redeViaria: redeViaria,
                      picos: widget.picos,
                      referenciasRelevo: referenciasRelevo,
                      picoSelecionadoId: widget.picoSelecionadoId,
                      localizacaoUsuario: widget.localizacaoUsuario,
                      recuoSuperiorControles: widget.recuoSuperiorControles,
                      progressoLuzViaria: _cena.progressoLuzViaria,
                      aoSelecionarPico: _aoSelecionarPico,
                    ),
                    if (_temFenomenoAoVivo)
                      Positioned.fill(
                        child: IgnorePointer(
                          key: const Key('camada_atmosfera_clima_globo'),
                          child: CustomPaint(
                            size: tamanho,
                            painter: PintorFenomenosAtmosfericosGlobo(
                              controlador: widget.controlador,
                              picosReferencia: referenciasRelevo,
                              bolhasAtivas: widget.bolhasAtivas,
                              incendiosAtivos: widget.incendiosAtivos,
                              sonarBolhaId: _cena.progressoSonar < 1.0
                                  ? _cena.sonarBolhaId
                                  : null,
                              faseTempestadeSegundos:
                                  _cena.faseTempestadeSegundos,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (widget.aoAlterarCamadaClima != null)
              Positioned(
                top: widget.recuoSuperiorControles,
                left: 12,
                child: BotaoCamadaClimaMapa(
                  ativo: widget.camadaClimaAtiva,
                  aoAlterarAtivo: widget.aoAlterarCamadaClima!,
                ),
              ),
            Positioned(
              top: widget.recuoSuperiorControles,
              right: 12,
              child: CapsulaControlesModoGlobo(
                modo3D: widget.controlador.modo3D,
                temLocalizacaoUsuario: widget.localizacaoUsuario != null,
                buscandoLocalizacaoUsuario: widget.buscandoLocalizacaoUsuario,
                aoAlternarModo3D: widget.controlador.alternarModo3D,
                aoResetarGlobo: () => _cena.resetarVisaoGlobo(widget.controlador),
                aoCentralizarNoUsuario: widget.aoCentralizarNoUsuario,
              ),
            ),
          ],
        );
      },
    );
  }
}
