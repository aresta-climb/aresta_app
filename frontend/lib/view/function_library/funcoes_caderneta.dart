// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../data/modelos/cadena.dart';
import '../../theme/cores_app.dart';

/// Constrói a seção de histórico cronológico de ascensões ou o estado vazio informativo.
Widget buildSecaoHistoricoCadenas(
  BuildContext context, {
  required List<Cadena> historico,
  required String Function(String escaladaUid) obterNomeVia,
  required String? Function(String escaladaUid) obterGrauVia,
  required String Function(DateTime data) formatarData,
  required ValueChanged<Cadena> onExcluirCadena,
}) {
  final cores = context.colors;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Histórico de Ascensões (${historico.length})',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: cores.chalkWhite,
              fontWeight: FontWeight.bold,
            ),
      ),
      const SizedBox(height: 12),
      if (historico.isEmpty)
        buildEstadoVazioHistorico(context)
      else
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: historico.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final cadena = historico[index];
            return buildItemHistoricoCadena(
              context,
              cadena: cadena,
              nomeVia: obterNomeVia(cadena.escaladaUid),
              grauVia: obterGrauVia(cadena.escaladaUid),
              dataFormatada: formatarData(cadena.dataAscensao),
              onExcluir: () => onExcluirCadena(cadena),
            );
          },
        ),
    ],
  );
}

/// Constrói o card informativo exibido quando não há ascensões registradas.
Widget buildEstadoVazioHistorico(BuildContext context) {
  final cores = context.colors;

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
    decoration: BoxDecoration(
      color: cores.caveShadow,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: cores.graniteEdge),
    ),
    alignment: Alignment.center,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cores.deepBasalt,
          ),
          child: Icon(
            Icons.menu_book_outlined,
            color: cores.ashGrey,
            size: 22,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Nenhuma ascensão registrada ainda',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: cores.chalkWhite,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Suas cadenas salvas nas páginas das vias aparecerão aqui.',
          textAlign: TextAlign.center,
          style: TextStyle(color: cores.ashGrey, fontSize: 12, height: 1.4),
        ),
      ],
    ),

Widget buildItemHistoricoCadena(BuildContext context, {required Cadena cadena, required String nomeVia, String? grauVia, required String dataFormatada, required VoidCallback onExcluir}) => const SizedBox();
Future<bool?> exibirDialogoConfirmarExclusao(BuildContext context) async => false;
