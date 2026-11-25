// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../navigation/funcoes_navegacao.dart';
import '../../theme/cores_app.dart';

/// Botão de retorno declarativo (Dumb UI) com suporte a duas interações distintas:
/// - **Toque rápido**: retrocede um nível na árvore de navegação (`aoVoltar` / [AppNav.back]).
/// - **Manter pressionado**: exibe anel de progresso radial, metamorfose suave do ícone
///   de seta para casa e pílula flutuante `"Início"` ao lado do polegar, retornando
///   diretamente à tela inicial ao completar (`aoIrParaInicio` / [AppNav.home]).
class BotaoVoltarComRetornoInicio extends StatefulWidget {
  /// Duração padrão de pressão contínua até acionar o retorno à tela inicial.
  static const Duration duracaoPadraoSegurar = Duration(milliseconds: 600);

  /// Fração inicial da duração reservada para distinguir toque rápido de pressão contínua.
  static const double _limiarInicioVisual = 0.20;

  /// Callback executado em um toque rápido. Quando nulo, delega para [AppNav.back].
  final VoidCallback? aoVoltar;

  /// Callback executado ao completar o gesto de segurar. Quando nulo, delega para [AppNav.home].
  final VoidCallback? aoIrParaInicio;

  /// Cor opcional do ícone de retorno no estado de repouso.
  final Color? corIcone;

  /// Cor de destaque usada no anel de progresso e na pílula de início.
  final Color? corDestaque;

  /// Rótulo semântico de acessibilidade para leitores de tela.
  final String dica;

  /// Duração total de pressão necessária para concluir o retorno ao início.
  final Duration duracaoSegurar;

  /// Cria uma instância de [BotaoVoltarComRetornoInicio].
  const BotaoVoltarComRetornoInicio({
    super.key,
    this.aoVoltar,
    this.aoIrParaInicio,
    this.corIcone,
    this.corDestaque,
    this.dica = 'Voltar',
    this.duracaoSegurar = duracaoPadraoSegurar,
  });

  @override
  State<BotaoVoltarComRetornoInicio> createState() =>
      _BotaoVoltarComRetornoInicioState();
}

class _BotaoVoltarComRetornoInicioState
    extends State<BotaoVoltarComRetornoInicio>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;
  final OverlayPortalController _controladorPilula = OverlayPortalController();
  final LayerLink _eloCamada = LayerLink();
  bool _pressionado = false;
  bool _disparouFeedbackInicioVisual = false;

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(
      vsync: this,
      duration: widget.duracaoSegurar,
    )
      ..addListener(_aoAtualizarProgresso)
      ..addStatusListener(_aoMudarStatusAnimacao);
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  double get _progressoVisual {
    final valor = _controlador.value;
    if (valor <= BotaoVoltarComRetornoInicio._limiarInicioVisual) {
      return 0.0;
    }
    final normalizado =
        (valor - BotaoVoltarComRetornoInicio._limiarInicioVisual) /
        (1.0 - BotaoVoltarComRetornoInicio._limiarInicioVisual);
    return Curves.easeOutCubic.transform(normalizado.clamp(0.0, 1.0));
  }

  void _aoAtualizarProgresso() {
    final valor = _controlador.value;
    if (_pressionado &&
        !_disparouFeedbackInicioVisual &&
        valor >= BotaoVoltarComRetornoInicio._limiarInicioVisual) {
      _disparouFeedbackInicioVisual = true;
      HapticFeedback.selectionClick();
    }
    final deveExibirPilula =
