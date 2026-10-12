// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../theme/cores_app.dart';

/// Card visual conciso para apresentação de métricas esportivas do perfil do escalador.
///
/// Exibe um título de referência, valor de destaque em tamanho proeminente,
/// ícone temático opcional e descrição complementar ([subtitulo]).
class CardEstatistica extends StatelessWidget {
  /// Rótulo superior da métrica (ex: 'Total de Cadenas', 'Maior Grau').
  final String titulo;

  /// Valor em destaque (ex: '42', '8a', '75%').
  final String valor;

  /// Ícone opcional ilustrativo da métrica.
  final IconData? icone;

  /// Cor personalizada do ícone (caso omitida, utiliza [cores.rustIron]).
  final Color? corIcone;

  /// Informação de apoio complementar (ex: '30 vias, 12 boulders').
  final String? subtitulo;

  const CardEstatistica({
    super.key,
    required this.titulo,
    required this.valor,
    this.icone,
    this.corIcone,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cores.caveShadow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cores.graniteEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cores.ashGrey,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (icone != null)
                Icon(
                  icone,
                  size: 20,
                  color: corIcone ?? cores.rustIron,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: cores.chalkWhite,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (subtitulo != null && subtitulo!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitulo!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cores.ashGrey.withValues(alpha: 0.8),
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
