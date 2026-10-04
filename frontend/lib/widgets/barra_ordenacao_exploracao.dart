// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../theme/cores_app.dart';
import '../utils/filtro_grau_escalada.dart';

/// Barra de ordenação padronizada para a página de exploração de setores e escaladas.
///
/// Exibe três opções de ordenação (`PADRÃO`, `GRAU` e `ALFABÉTICO`) em botões
/// uniformes, acompanhados de um botão lateral para alternar a direção
/// da listagem entre crescente (▲) e decrescente (▼).
class BarraOrdenacaoExploracao extends StatelessWidget {
  /// O modo de ordenação atualmente selecionado.
  final TipoOrdenacaoExploracao ordenacaoAtual;

  /// Indica se a ordenação ativa é crescente (`true`) ou decrescente (`false`).
  final bool direcaoCrescente;

  /// Callback acionado quando o usuário seleciona um modo de ordenação diferente.
  final ValueChanged<TipoOrdenacaoExploracao> onOrdenacaoChanged;

  /// Callback acionado quando o usuário toca no botão para inverter a direção.
  final ValueChanged<bool> onDirecaoChanged;

  const BarraOrdenacaoExploracao({
    super.key,
    required this.ordenacaoAtual,
    required this.direcaoCrescente,
    required this.onOrdenacaoChanged,
    required this.onDirecaoChanged,
  });

  Widget _buildCard({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    final Color activeColor = AppColors.brandColor;
    final Color inactiveTextColor = colors.ashGrey;
    final Color inactiveBorderColor = colors.graniteEdge;
    final Color bgColor =
        isActive ? colors.rustIron.withValues(alpha: 0.15) : colors.caveShadow;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(
              color: isActive ? activeColor : inactiveBorderColor,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isActive ? activeColor : inactiveTextColor, size: 15),
              const SizedBox(width: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive ? activeColor : inactiveTextColor,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color activeColor = AppColors.brandColor;
    final Color inactiveBorderColor = colors.graniteEdge;
    final Color bgColor = colors.caveShadow;

    return Row(
      children: [
        _buildCard(
          context: context,
          label: 'PADRÃO',
          icon: Icons.grid_view_rounded,
          isActive: ordenacaoAtual == TipoOrdenacaoExploracao.padrao,
          onTap: () => onOrdenacaoChanged(TipoOrdenacaoExploracao.padrao),
        ),
        const SizedBox(width: 6),
        _buildCard(
          context: context,
          label: 'GRAU',
          icon: Icons.trending_up,
          isActive: ordenacaoAtual == TipoOrdenacaoExploracao.grau,
          onTap: () => onOrdenacaoChanged(TipoOrdenacaoExploracao.grau),
        ),
        const SizedBox(width: 6),
        _buildCard(
          context: context,
          label: 'ALFABÉTICO',
          icon: Icons.sort_by_alpha,
          isActive: ordenacaoAtual == TipoOrdenacaoExploracao.alfabetico,
          onTap: () => onOrdenacaoChanged(TipoOrdenacaoExploracao.alfabetico),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => onDirecaoChanged(!direcaoCrescente),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(
                color: inactiveBorderColor,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              direcaoCrescente ? Icons.arrow_upward : Icons.arrow_downward,
              color: activeColor,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }
}
