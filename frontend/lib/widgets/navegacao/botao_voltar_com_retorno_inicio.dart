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
        valor > BotaoVoltarComRetornoInicio._limiarInicioVisual;
    if (deveExibirPilula != _controladorPilula.isShowing) {
      if (deveExibirPilula) {
        _controladorPilula.show();
      } else {
        _controladorPilula.hide();
      }
    }
    setState(() {});
  }

  void _aoMudarStatusAnimacao(AnimationStatus status) {
    if (status == AnimationStatus.completed && _pressionado) {
      _pressionado = false;
      _controladorPilula.hide();
      _controlador.reset();
      HapticFeedback.mediumImpact();
      _executarIrParaInicio();
    }
  }

  void _aoPressionarPonteiro(PointerDownEvent _) {
    _pressionado = true;
    _disparouFeedbackInicioVisual = false;
    _controlador.duration = widget.duracaoSegurar;
    _controlador.forward(from: 0.0);
  }

  void _aoSoltarPonteiro(PointerUpEvent _) {
    if (!_pressionado) return;
    _pressionado = false;
    if (_controlador.value < BotaoVoltarComRetornoInicio._limiarInicioVisual) {
      _controlador.reset();
      _executarVoltar();
    } else {
      _controlador.reverse();
    }
  }

  void _aoCancelarPonteiro(PointerCancelEvent _) {
    if (!_pressionado) return;
    _pressionado = false;
    _controlador.reverse();
  }

  void _executarVoltar() {
    final callback = widget.aoVoltar;
    if (callback != null) {
      callback();
    } else {
      AppNav.back(context);
    }
  }

  void _executarIrParaInicio() {
    final callback = widget.aoIrParaInicio;
    if (callback != null) {
      callback();
    } else {
      AppNav.home(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).extension<AppColors>() ?? AppColors.dark;
    final corBase =
        widget.corIcone ?? IconTheme.of(context).color ?? cores.chalkWhite;
    final corRealce = widget.corDestaque ?? AppColors.brandColor;
    final progresso = _progressoVisual;

    final opacidadeSeta = (1.0 - progresso * 1.65).clamp(0.0, 1.0);
    final escalaBotao = 1.0 + 0.08 * math.sin(progresso * math.pi);

    Widget conteudoBotao = Stack(
      alignment: Alignment.center,
      children: [
        if (progresso > 0.0)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: corRealce.withValues(alpha: 0.18 * progresso),
              ),
            ),
          ),
        if (opacidadeSeta > 0.0)
          Opacity(
            opacity: opacidadeSeta,
            child: Transform.translate(
              offset: Offset(-5.0 * progresso, 0),
              child: Transform.scale(
                scale: 1.0 - 0.35 * progresso,
                child: Icon(Icons.arrow_back, color: corBase, size: 24),
              ),
            ),
          ),
        if (progresso > 0.0)
          Opacity(
            opacity: ((progresso - 0.12) / 0.68).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.55 + 0.48 * Curves.easeOutBack.transform(progresso),
              child: Icon(
                Icons.home_rounded,
                color: Color.lerp(corBase, corRealce, 0.35)!,
                size: 22,
              ),
            ),
          ),
      ],
    );

    if (progresso > 0.0) {
      conteudoBotao = CustomPaint(
        painter: _PintorArcoRetornoInicio(
          progresso: progresso,
          corDestaque: corRealce,
          corTrilha: corBase.withValues(alpha: 0.22),
        ),
        child: conteudoBotao,
      );
    }

    return Semantics(
      button: true,
      label: widget.dica,
      hint: 'Segure para ir ao início',
      excludeSemantics: true,
      onTap: _executarVoltar,
      onLongPress: _executarIrParaInicio,
      child: CompositedTransformTarget(
        link: _eloCamada,
        child: OverlayPortal(
          controller: _controladorPilula,
          overlayChildBuilder: (_) => _PilulaIndicadoraInicio(
            eloCamada: _eloCamada,
            progresso: progresso,
            corDestaque: corRealce,
            cores: cores,
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _aoPressionarPonteiro,
              onPointerUp: _aoSoltarPonteiro,
              onPointerCancel: _aoCancelarPonteiro,
              child: RepaintBoundary(
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Transform.scale(
                    scale: escalaBotao,
                    child: conteudoBotao,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pílula visual flutuante projetada ao lado do botão para indicar o retorno ao início
/// sem sofrer oclusão pelo polegar do usuário nem alterar o layout da barra superior.
class _PilulaIndicadoraInicio extends StatelessWidget {
  final LayerLink eloCamada;
  final double progresso;
  final Color corDestaque;
  final AppColors cores;

  const _PilulaIndicadoraInicio({
    required this.eloCamada,
    required this.progresso,
    required this.corDestaque,
    required this.cores,
  });

  @override
  Widget build(BuildContext context) {
    final entrada = (progresso * 3.0).clamp(0.0, 1.0);
    return CompositedTransformFollower(
      link: eloCamada,
      showWhenUnlinked: false,
      targetAnchor: Alignment.centerRight,
      followerAnchor: Alignment.centerLeft,
      offset: Offset(6.0 * entrada, 0),
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.centerLeft,
          child: Opacity(
            opacity: entrada,
            child: Transform.scale(
              scale: 0.90 + 0.10 * entrada,
              alignment: Alignment.centerLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cores.caveShadow.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: corDestaque.withValues(alpha: 0.70),
                    width: 1.2,
                  ),
                  boxShadow: [
