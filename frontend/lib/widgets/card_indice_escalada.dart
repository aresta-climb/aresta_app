// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../theme/cores_app.dart';
import '../utils/indexador_escaladas.dart';
import '../view/function_library/setor_functions.dart';

/// Card de exibição de uma escalada no Índice de Escaladas ou na página de Setor.
///
/// Exibe o grau ou rótulo de croqui em destaque visual à esquerda, nome, modalidade,
/// proteções, localização opcional e ação para abrir a tela de detalhes.
class CardIndiceEscalada extends StatelessWidget {
  /// O item indexado contendo os dados da escalada e localização.
  final ItemIndiceEscalada item;

  /// Rótulo opcional de referência do croqui/mapa quando exibido no contexto do setor.
  final RotulosVia? rotuloCroqui;

  /// Define se o caminho de localização (Setor / Grupo > Setor) deve ser exibido.
  final bool mostrarLocalizacao;

  /// Indica se a via é o alvo direto de foco/rolagem (`scrollToEscalada`), aplicando realce visual suave.
  final bool isTarget;

  /// Ação disparada ao tocar no card.
  final VoidCallback onTap;

  const CardIndiceEscalada({
    super.key,
    required this.item,
    this.rotuloCroqui,
    this.mostrarLocalizacao = true,
    this.isTarget = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Subtítulo técnico com modalidade, grau (quando em modo setor) e proteções
    final partesSubtitulo = <String>[];
    if (rotuloCroqui != null) {
      final modalidadeComGrau = item.grau.isNotEmpty
          ? '${item.modalidade} | ${item.grau}'
          : item.modalidade;
      if (modalidadeComGrau.isNotEmpty) {
        partesSubtitulo.add(modalidadeComGrau);
      }
    } else {
      if (item.modalidade.isNotEmpty) {
        partesSubtitulo.add(item.modalidade);
      }
    }
    if (item.protecoes.isNotEmpty) {
      partesSubtitulo.add(item.protecoes);
    }

    final subtituloTecnico = partesSubtitulo.join(' • ');

    Widget buildBadgeConteudo() {
      if (rotuloCroqui != null) {
        if (rotuloCroqui!.resolvedLabel.isNotEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (rotuloCroqui!.mapIndicator.isNotEmpty)
                Text(
                  rotuloCroqui!.mapIndicator,
                  style: TextStyle(
                    color: colors.ashGrey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text(
                rotuloCroqui!.resolvedLabel,
                style: TextStyle(
                  color: colors.chalkWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: rotuloCroqui!.resolvedLabel.length > 3 ? 12 : 15,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        } else {
          return Icon(
            Icons.terrain_outlined,
            color: colors.rustIron,
            size: 22,
          );
        }
      }

      return Text(
        item.grau.isNotEmpty ? item.grau : '—',
        style: TextStyle(
          color: colors.chalkWhite,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      );
    }

    final card = Padding(
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
                // Badge à esquerda (Grau no índice geral, Rótulo do croqui no setor)
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
                      child: buildBadgeConteudo(),
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
                      if (mostrarLocalizacao && item.localizacaoFormatada.isNotEmpty) ...[
                        const SizedBox(height: 3),
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

    return _buildEfeitoRealceAlvo(
      child: card,
      isTarget: isTarget,
      context: context,
    );
  }

  /// Constrói a animação de realce suave quando a via é o alvo direto de busca ou deep link.
  Widget _buildEfeitoRealceAlvo({
    required Widget child,
    required bool isTarget,
    required BuildContext context,
  }) {
    if (!isTarget) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 2500),
      builder: (context, value, childWidget) {
        final double fadeProgress = value < 0.40 ? 0.0 : (value - 0.40) / 0.60;
        final Color brandColor = context.colors.rustIron;
        final Color color = value < 0.40
            ? Colors.transparent
            : brandColor.withValues(alpha: 0.3 * (1.0 - fadeProgress));

        return Stack(
          clipBehavior: Clip.none,
          children: [
            childWidget!,
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 10,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: (color.a * 255.0).round().clamp(0, 255) == 0
                        ? null
                        : [
                            BoxShadow(
                              color: brandColor.withValues(
                                alpha: 0.6 * (1.0 - fadeProgress),
                              ),
                              blurRadius: 15 * (1.0 - fadeProgress),
                              spreadRadius: 2 * (1.0 - fadeProgress),
                            ),
                          ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: child,
    );
  }
}
