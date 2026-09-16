// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../theme/app_colors.dart';
import '../utils/consolidador_modalidades.dart';

/// Componente visual reutilizável que apresenta chips/badges informativos
/// das modalidades de escalada presentes em um setor, grupo ou conjunto de vias.
///
/// Os badges adaptam-se com [Wrap] para evitar estouro de layout (overflow)
/// e aplicam concordância gramatical estrita de singular e plural.
/// Se a lista de itens estiver vazia, o widget não renderiza nenhum espaço em branco.
class BadgesModalidades extends StatelessWidget {
  /// Lista de modalidades e contagens consolidadas a serem exibidas.
  final List<ItemModalidade> itens;

  /// Cria uma instância com os itens fornecidos diretamente.
  const BadgesModalidades({super.key, required this.itens});

  /// Constrói os badges a partir das escaladas de um [Setor].
  factory BadgesModalidades.deSetor(Setor setor, {Key? key}) {
    return BadgesModalidades(
      key: key,
      itens: ConsolidadorModalidades.consolidarSetor(setor),
    );
  }

  /// Constrói os badges a partir das escaladas agregadas de um [Grupo].
  factory BadgesModalidades.deGrupo(Grupo grupo, {Key? key}) {
    return BadgesModalidades(
      key: key,
      itens: ConsolidadorModalidades.consolidarGrupo(grupo),
    );
  }

  /// Constrói os badges a partir de uma lista iterável de [Escalada].
  factory BadgesModalidades.deEscaladas(
    Iterable<Escalada> escaladas, {
    Key? key,
  }) {
    return BadgesModalidades(
      key: key,
      itens: ConsolidadorModalidades.consolidarEscaladas(escaladas),
    );
  }

  /// Retorna a cor de destaque temática sutil associada a cada modalidade.
  Color _obterCorModalidade(BuildContext context, ModalidadeEscaladaEnum modalidade) {
    switch (modalidade) {
      case ModalidadeEscaladaEnum.esportiva:
        return context.colors.fernGreen;
      case ModalidadeEscaladaEnum.movel:
        return context.colors.rustIron;
      case ModalidadeEscaladaEnum.boulder:
        return context.colors.slateStone;
      case ModalidadeEscaladaEnum.multienfiada:
        return Colors.amber;
      case ModalidadeEscaladaEnum.highline:
        return Colors.cyan;
    }
  }

  Widget _buildChip(BuildContext context, ItemModalidade item) {
    final corDestaque = _obterCorModalidade(context, item.modalidade);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: corDestaque.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: corDestaque.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Text(
        item.rotuloFormatado,
        style: TextStyle(
          color: context.colors.chalkWhite,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (itens.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: itens.map((item) => _buildChip(context, item)).toList(),
    );
  }
}
