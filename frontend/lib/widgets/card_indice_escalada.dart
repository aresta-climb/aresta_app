// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/indexador_escaladas.dart';

/// Card de exibição de uma escalada no Índice de Escaladas.
///
/// Exibe o grau em destaque visual à esquerda, nome, modalidade, proteções,
/// localização hierárquica do setor/grupo e ação para abrir a tela de detalhes.
class CardIndiceEscalada extends StatelessWidget {
  /// O item indexado contendo os dados da escalada e localização.
  final ItemIndiceEscalada item;

  /// Ação disparada ao tocar no card.
  final VoidCallback onTap;

  const CardIndiceEscalada({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Subtítulo técnico com modalidade e proteções
    final partesSubtitulo = <String>[];
    if (item.modalidade.isNotEmpty) {
      partesSubtitulo.add(item.modalidade);
    }
    if (item.protecoes.isNotEmpty) {
      partesSubtitulo.add(item.protecoes);
    }

    final subtituloTecnico = partesSubtitulo.join(' • ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colors.caveShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colors.graniteEdge),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Badge de Grau em destaque
                Container(
                  width: 58,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.deepBasalt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.rustIron.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.grau.isNotEmpty ? item.grau : '—',
                        style: TextStyle(
                          color: colors.chalkWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Informações centrais (Nome, Modalidade + Proteções, Localização)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nome da via + Estrela de destaque
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.nome,
                              style: TextStyle(
                                color: colors.chalkWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.isDestaque) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                      if (subtituloTecnico.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtituloTecnico,
                          style: TextStyle(
                            color: colors.ashGrey,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 3),
                      // Localização (Setor ou Grupo > Setor)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: colors.rustIron,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.localizacaoFormatada,
                              style: TextStyle(
                                color: colors.ashGrey.withValues(alpha: 0.8),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Ícone indicador de navegação
                Icon(
                  Icons.chevron_right,
                  color: colors.rustIron,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
