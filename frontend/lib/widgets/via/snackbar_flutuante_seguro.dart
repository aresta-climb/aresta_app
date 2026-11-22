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
  });
}
