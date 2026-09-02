// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/formatador_creditos.dart';

/// Widget que exibe os créditos do autor/criador do croqui de forma padronizada.
class LinhaCreditoAutor extends StatelessWidget {
  final List<String> creditos;

  const LinhaCreditoAutor({
    super.key,
    required this.creditos,
  });

  @override
  Widget build(BuildContext context) {
    final textoFormatado = FormatadorCreditos.formatarLinhaCreditos(creditos);
    if (textoFormatado == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            Icons.person_outline,
            size: 16,
            color: context.colors.chalkWhite,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              textoFormatado,
              style: TextStyle(
                color: context.colors.chalkWhite,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
