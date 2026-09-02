// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Banner visual posicionado no topo ou na página de detalhes do pico
/// indicando navegação em modo online e permitindo salvamento offline com 1 toque.
class BannerModoOnline extends StatelessWidget {
  /// Tamanho pré-formatado do download (opcional).
  final String? tamanhoFormatado;

  /// Indica se o pico já se encontra salvo no armazenamento permanente offline.
  final bool isDownloaded;

  /// Progresso atual do download (de `0.0` a `1.0`), ou `null` se inativo.
  final double? progressoDownload;

  /// Callback acionado quando o usuário toca para salvar o croqui offline.
  final VoidCallback onSalvarPraPedra;

  const BannerModoOnline({
    super.key,
    this.tamanhoFormatado,
    required this.isDownloaded,
    this.progressoDownload,
    required this.onSalvarPraPedra,
  });

  @override
  Widget build(BuildContext context) {
    if (isDownloaded) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF7B8B6F).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF7B8B6F).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF7B8B6F),
              size: 20,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'SALVO OFFLINE',
                style: TextStyle(
                  color: Color(0xFF7B8B6F),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isBaixando = progressoDownload != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.colors.caveShadow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.graniteEdge,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_outlined,
                color: context.colors.beastHide,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'MODO ONLINE',
                style: TextStyle(
                  color: context.colors.beastHide,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Você está navegando via internet. Salve o guia completo para usar sem sinal na pedra.',
            style: TextStyle(
              color: context.colors.ashGrey,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          if (isBaixando) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressoDownload,
                backgroundColor: context.colors.graniteEdge,
                color: context.colors.rustIron,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'BAIXANDO (${(progressoDownload! * 100).toInt()}%)...',
              style: TextStyle(
                color: context.colors.dryMoss,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSalvarPraPedra,
                icon: const Icon(
                  Icons.download_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text(
                  'Salvar pra Pedra',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC05244),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
