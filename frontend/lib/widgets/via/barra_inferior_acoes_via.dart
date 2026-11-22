// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../theme/cores_app.dart';

/// Barra inferior fixa ao alcance do polegar (*Thumb Dock*, Dumb UI) unificando o atalho
/// do croqui interativo e o botão principal de registro de cadena/tentativa na `ViaPage`.
class BarraInferiorAcoesVia extends StatelessWidget {
  /// Indica se existe croqui interativo para exibir o atalho secundário `'Croqui'`.
  final bool exibirBotaoCroqui;

  /// Callback acionado ao tocar no atalho de croqui.
  final VoidCallback aoAbrirCroqui;

  /// Indica se o botão principal de caderneta deve ser exibido.
  final bool exibirBotaoCaderneta;

  /// Indica se o escalador já encadenou a via (destacando o botão em verde musgo).
  final bool possuiCadena;

  /// Rótulo exibido no botão principal de caderneta.
  final String rotuloBotaoCaderneta;

  /// Callback acionado ao tocar no botão de registro de cadena/tentativa.
  final VoidCallback aoRegistrarCadena;

  /// Cria uma instância de [BarraInferiorAcoesVia].
  const BarraInferiorAcoesVia({
    super.key,
    required this.exibirBotaoCroqui,
    required this.aoAbrirCroqui,
    required this.exibirBotaoCaderneta,
    required this.possuiCadena,
    required this.rotuloBotaoCaderneta,
    required this.aoRegistrarCadena,
  });


  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
