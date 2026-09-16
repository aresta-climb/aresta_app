// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'modal_beta_aberto.dart';

/// Micro-indicador textual para sinalização do estágio de "Beta Aberto" no cabeçalho da Home.
///
/// Apresenta o texto `BETA` em laranja vibrante (`#E95440` / [AppColors.brandColor]) com tipografia em Montserrat 9pt e tracking espaçado,
/// posicionado estrategicamente sob o texto `CLIMB` e abrindo o [ModalBetaAberto] ao ser tocado.
class MicroBadgeBeta extends StatelessWidget {
  /// Callback opcional disparado ao tocar no micro-badge.
  /// Se não fornecido, o comportamento padrão é exibir o [ModalBetaAberto].
  final VoidCallback? aoTocar;

  /// Cor opcional para o texto BETA. Padrão: `#E95440` (laranja da marca).
  final Color? corTexto;

  const MicroBadgeBeta({
    super.key,
    this.aoTocar,
    this.corTexto,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: aoTocar ?? () => exibirModalBetaAberto(context),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 1.0),
          child: Text(
            'BETA',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w700,
              fontSize: 9.0,
              letterSpacing: 1.5,
              color: corTexto ?? const Color(0xFFE95440),
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
