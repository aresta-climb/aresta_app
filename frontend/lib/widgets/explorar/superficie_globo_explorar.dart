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

