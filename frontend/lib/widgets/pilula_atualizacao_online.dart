// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Pílula visual informativa não-intrusiva exibida quando o polling de ETag
/// detecta que uma versão mais recente do croqui foi publicada no servidor remoto.
class PilulaAtualizacaoOnline extends StatelessWidget {
  /// Callback acionado quando o usuário toca para recarregar o croqui.
  final VoidCallback onRecarregar;

  const PilulaAtualizacaoOnline({
    super.key,
    required this.onRecarregar,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onRecarregar,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF2C3E50),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.colors.beastHide, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sync, color: context.colors.beastHide, size: 18),
              const SizedBox(width: 8),
              Text(
                'Novas informações disponíveis • Recarregar',
                style: TextStyle(
                  color: context.colors.chalkWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
