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

