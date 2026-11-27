// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:flutter/material.dart';

import '../../idioma/tradutor_app.dart';
import '../../theme/cores_app.dart';
import '../../view/view_models/card_croqui_view_model.dart';
import '../../view/view_models/explorar_view_model.dart';
import 'cartao_item_gaveta_explorar.dart';

export 'cartao_item_gaveta_explorar.dart';

/// Posições discretas de encaixe vertical da gaveta deslizante sobre o globo.
enum PosicaoEncaixeGaveta {
  /// Borda mínima na base da tela deixando apenas a alça visível e ~96% da tela livre para o mapa.
  mapa(0.038),

  /// Divisão equilibrada entre globo/relevo superior e cards de picos abaixo.
  dividir(0.48),

  /// Catálogo em tela cheia encostando na barra de pesquisa e cobrindo todo o mapa.
  lista(0.93);

  final double fracaoAltura;

  const PosicaoEncaixeGaveta(this.fracaoAltura);

  /// Rótulo localizado exibido nos botões da alça da gaveta.
  String get rotulo => switch (this) {
        PosicaoEncaixeGaveta.mapa => tr(ChaveTexto.explorarModoMapa),
        PosicaoEncaixeGaveta.dividir => tr(ChaveTexto.explorarModoDividir),
        PosicaoEncaixeGaveta.lista => tr(ChaveTexto.explorarModoLista),
      };
}

/// Gaveta inferior ajustável em 3 estágios (`Mapa`, `Dividir`, `Lista`) sincronizada ao globo.
///
/// Propaga continuamente sua altura em pixels em [alturaGavetaPx] para compensar o centro
/// óptico da câmera 3D/2D e realiza auto-scroll animado até o card correspondente quando um
/// pino é tocado no mapa.
class GavetaDeslizanteExplorar extends StatefulWidget {
  final BrowseViewModel viewModel;
  final ValueNotifier<double> alturaGavetaPx;
  final void Function(CardCroquiViewModel card) aoAbrirPico;
  final void Function(String picoId)? aoFocarPicoNaLista;
  final PosicaoEncaixeGaveta posicaoInicial;
  final ScrollController? scrollControllerExterno;
  final GlobalKey? chaveSetimoPicoExterna;

  const GavetaDeslizanteExplorar({
    super.key,
    required this.viewModel,
    required this.alturaGavetaPx,
    required this.aoAbrirPico,
    this.aoFocarPicoNaLista,
    this.posicaoInicial = PosicaoEncaixeGaveta.dividir,
    this.scrollControllerExterno,
    this.chaveSetimoPicoExterna,
  });

  @override
  State<GavetaDeslizanteExplorar> createState() =>
      _GavetaDeslizanteExplorarState();
}

class _GavetaDeslizanteExplorarState extends State<GavetaDeslizanteExplorar>
    with SingleTickerProviderStateMixin {
  static const List<ModalidadeExploracaoPico> _modalidadesRapidas = [
    ModalidadeExploracaoPico.esportiva,
    ModalidadeExploracaoPico.boulder,
    ModalidadeExploracaoPico.movel,
    ModalidadeExploracaoPico.paredao,
  ];

  late final AnimationController _animadorAltura;
  late ScrollController _scrollController;
  late bool _gerenciaScrollInterno;
  late GlobalKey _chaveSetimoInterna;

  final Map<String, GlobalKey> _chavesCardsPorId = {};
  PosicaoEncaixeGaveta _encaixeAtual = PosicaoEncaixeGaveta.dividir;
  double _fracaoAtual = PosicaoEncaixeGaveta.dividir.fracaoAltura;
  double _fracaoInicioAnim = PosicaoEncaixeGaveta.dividir.fracaoAltura;
  double _fracaoAlvoAnim = PosicaoEncaixeGaveta.dividir.fracaoAltura;
  double _alturaTotalDisponivel = 760.0;

  String? _picoComPulsoDestaque;
  Timer? _timerPulsoDestaque;

  GlobalKey get _chaveSetimoEfetiva =>
      widget.chaveSetimoPicoExterna ?? _chaveSetimoInterna;

  @override
  void initState() {
    super.initState();
    _encaixeAtual = widget.posicaoInicial;
    _fracaoAtual = widget.posicaoInicial.fracaoAltura;
    _fracaoInicioAnim = _fracaoAtual;
    _fracaoAlvoAnim = _fracaoAtual;
    _chaveSetimoInterna = GlobalKey();
    _gerenciaScrollInterno = widget.scrollControllerExterno == null;
    _scrollController = widget.scrollControllerExterno ?? ScrollController();

    _animadorAltura = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addListener(() {
        final t = Curves.easeOutCubic.transform(_animadorAltura.value);
        setState(() {
          _fracaoAtual =
              _fracaoInicioAnim + (_fracaoAlvoAnim - _fracaoInicioAnim) * t;
        });
        _publicarAlturaEmPixels();
      });

    _registrarOuvintes(widget.viewModel);
    if (widget.viewModel.solicitacaoScrollSetimoPico.value > 0) {
      _aoSolicitarScrollSetimoPico();
    }
  }

  @override
  void didUpdateWidget(covariant GavetaDeslizanteExplorar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      _removerOuvintes(oldWidget.viewModel);
      _registrarOuvintes(widget.viewModel);
      if (widget.viewModel.solicitacaoScrollSetimoPico.value > 0) {
        _aoSolicitarScrollSetimoPico();
      }
    }
  }

  @override
  void dispose() {
    _timerPulsoDestaque?.cancel();
    _removerOuvintes(widget.viewModel);
    _animadorAltura.dispose();
    if (_gerenciaScrollInterno) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _registrarOuvintes(BrowseViewModel vm) {
    vm.solicitacaoAutoScrollPicoSelecionado
        .addListener(_aoSolicitarAutoScrollMapa);
    vm.solicitacaoScrollSetimoPico.addListener(_aoSolicitarScrollSetimoPico);
  }

  void _removerOuvintes(BrowseViewModel vm) {
    vm.solicitacaoAutoScrollPicoSelecionado
        .removeListener(_aoSolicitarAutoScrollMapa);
    vm.solicitacaoScrollSetimoPico.removeListener(_aoSolicitarScrollSetimoPico);
  }

  void _publicarAlturaEmPixels() {
    final px = (_alturaTotalDisponivel * _fracaoAtual)
        .clamp(28.0, _alturaTotalDisponivel);
    if ((widget.alturaGavetaPx.value - px).abs() > 0.2) {
      widget.alturaGavetaPx.value = px;
    }
  }

  void _animarParaEncaixe(PosicaoEncaixeGaveta destino) {
    _encaixeAtual = destino;
    _fracaoInicioAnim = _fracaoAtual;
    _fracaoAlvoAnim = destino.fracaoAltura;
    _animadorAltura.forward(from: 0.0);
  }

  void _aoSolicitarAutoScrollMapa() {
    final idSelecionado = widget.viewModel.picoSelecionadoId;
    if (idSelecionado == null) return;

    if (_encaixeAtual == PosicaoEncaixeGaveta.mapa) {
      _animarParaEncaixe(PosicaoEncaixeGaveta.dividir);
    }

