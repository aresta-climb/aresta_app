// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/cores_app.dart';

/// Folga visual mínima (em pixels lógicos) acima da barra de navegação do SO ou do dock inferior.
const double _folgaBaseSnackBar = 16.0;

/// Despachante pré-capturado de `SnackBar` flutuante que preserva margens seguras em relação
/// aos botões de navegação inferiores do sistema operacional mesmo após fechamento de modais
/// ou lacunas assíncronas (`await`).
@immutable
class DespachanteSnackBarSeguro {
  final ScaffoldMessengerState _mensageiro;
  final AppColors _cores;
  final EdgeInsets _margemFlutuante;

  const DespachanteSnackBarSeguro._({
    required ScaffoldMessengerState mensageiro,
    required AppColors cores,
    required EdgeInsets margemFlutuante,
  }) : _mensageiro = mensageiro,
       _cores = cores,
       _margemFlutuante = margemFlutuante;

  /// Exibe um [SnackBar] flutuante com [texto], [duracao] e botão opcional [rotuloAcao] / [aoAcionar].
  void exibir({
    required String texto,
    Duration duracao = const Duration(seconds: 2),
    String? rotuloAcao,
    VoidCallback? aoAcionar,
  }) {
    _mensageiro
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: _margemFlutuante,
          backgroundColor: _cores.caveShadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: _cores.graniteEdge),
          ),
          content: Text(
            texto,
            style: TextStyle(
              color: _cores.chalkWhite,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          duration: duracao,
          action: rotuloAcao != null && aoAcionar != null
              ? SnackBarAction(
                  label: rotuloAcao,
                  textColor: _cores.rustIron,
                  onPressed: aoAcionar,
                )
              : null,
        ),
      );
  }
}

/// Captura sincronicamente o [ScaffoldMessengerState] e calcula a margem inferior segura do [SnackBar]
/// compensando tanto `viewPadding.bottom` (barra de 3 botões ou pílula gestual do Android em modo
/// *edge-to-edge*, mesmo quando `padding.bottom` já foi consumido) quanto um eventual [recuoExtraInferior]
/// (como a barra fixa de ações da `ViaPage`).
DespachanteSnackBarSeguro capturarDespachanteSnackBarSeguro(
  BuildContext context, {
  double recuoExtraInferior = 0.0,
}) {
  // Usa o BuildContext do Scaffold hospedeiro para medir exatamente o mesmo `padding.bottom`
  // que o SafeArea interno do SnackBar receberá, mesmo quando o widget chamador estiver dentro de um SafeArea filho.
  final contextoScaffold = Scaffold.maybeOf(context)?.context ?? context;
  final mediaQuery = MediaQuery.maybeOf(contextoScaffold);
  final paddingInferior = mediaQuery?.padding.bottom ?? 0.0;
  final viewPaddingMq = mediaQuery?.viewPadding.bottom ?? 0.0;

  final view = View.maybeOf(contextoScaffold);
  final viewPaddingJanela = (view != null && view.devicePixelRatio > 0)
      ? view.viewPadding.bottom / view.devicePixelRatio
      : 0.0;

  final aplicadoPeloSnackBar = math.max(paddingInferior, viewPaddingMq);
  final recuoBarraSistema = math.max(aplicadoPeloSnackBar, viewPaddingJanela);
  // O SafeArea interno do SnackBar flutuante no Material 3 aplica `max(padding.bottom, viewPadding.bottom)`
  // do MediaQuery. Somamos apenas eventual recuo físico da janela (`View.viewPadding`) que tenha sido
  // zerado por algum `MediaQuery` intermediário, evitando invasão dos botões do SO e dupla contagem.
  final compensacaoSoNaoConsumida = math.max(
    0.0,
    recuoBarraSistema - aplicadoPeloSnackBar,
  );

  return DespachanteSnackBarSeguro._(
    mensageiro: ScaffoldMessenger.of(context),
    cores: context.colors,
    margemFlutuante: EdgeInsets.fromLTRB(
      16,
      8,
      16,
      compensacaoSoNaoConsumida + recuoExtraInferior + _folgaBaseSnackBar,
    ),
  );
}

/// Atalho síncrono para exibir imediatamente um [SnackBar] flutuante acima dos botões do SO.
void exibirSnackBarFlutuanteSeguro(
  BuildContext context, {
  required String texto,
  Duration duracao = const Duration(seconds: 2),
});
