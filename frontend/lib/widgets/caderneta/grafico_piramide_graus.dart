// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/cores_app.dart';

/// Widget visual que renderiza a pirâmide de graduação de escalada com barras horizontais.
///
/// Permite alternar entre a exibição de Vias de falésia e blocos de Boulder, calculando
/// a largura proporcional de cada nível de grau com base na frequência de encadenamento.
class GraficoPiramideGraus extends StatelessWidget {
  /// Mapeamento de graus ordenados e respectivas quantidades de ascensões encadenadas.
  final Map<String, int> piramide;

  /// Indica se a exibição atual está em modo Vias (`true`) ou Boulders (`false`).
  final bool modoVias;

  /// Callback acionado quando o usuário alterna entre as modalidades Vias e Boulders.
  final void Function(bool apenasVias)? onAlternarModo;

  const GraficoPiramideGraus({
    super.key,
    required this.piramide,
    this.modoVias = true,
    this.onAlternarModo,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    final maxQuantidade = piramide.values.fold<int>(0, math.max);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cores.caveShadow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cores.graniteEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho da pirâmide com seletor de modalidade
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pirâmide de Graduação',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: cores.chalkWhite,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: cores.deepBasalt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cores.graniteEdge),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBotaoModalidade(
                      context,
                      rotulo: 'Vias',
                      ativo: modoVias,
                      onTap: () => onAlternarModo?.call(true),
                    ),
                    _buildBotaoModalidade(
                      context,
                      rotulo: 'Boulders',
                      ativo: !modoVias,
                      onTap: () => onAlternarModo?.call(false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Conteúdo: lista de barras ou estado vazio
          if (piramide.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Nenhuma ascensão registrada nesta modalidade.',
                  style: TextStyle(color: cores.ashGrey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Column(
              children: piramide.entries.map((entrada) {
                final proporcao = maxQuantidade > 0
                    ? entrada.value / maxQuantidade
                    : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(
                          entrada.key,
                          style: TextStyle(
                            color: cores.chalkWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final larguraBarra = math.max(
                              16.0,
                              constraints.maxWidth * proporcao,
                            );

                            return Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                // Fundo da trilha
                                Container(
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: cores.deepBasalt,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                // Barra de progresso do grau
                                Container(
                                  width: larguraBarra,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        cores.rustIron,
                                        cores.rustIron.withValues(alpha: 0.85),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${entrada.value}',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: cores.chalkWhite,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBotaoModalidade(
    BuildContext context, {
    required String rotulo,
    required bool ativo,
    required VoidCallback onTap,
  }) {
    final cores = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: ativo ? cores.rustIron : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          rotulo,
          style: TextStyle(
            color: ativo ? cores.chalkWhite : cores.ashGrey,
            fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
