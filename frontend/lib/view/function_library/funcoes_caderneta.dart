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
  );
}

/// Constrói o card individual de exibição de uma ascensão esportiva no histórico.
Widget buildItemHistoricoCadena(
  BuildContext context, {
  required Cadena cadena,
  required String nomeVia,
  String? grauVia,
  required String dataFormatada,
  required VoidCallback onExcluir,
}) {
  final cores = context.colors;

  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: cores.caveShadow,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: cores.graniteEdge),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: cadena.isCadena
                ? cores.fernGreen.withValues(alpha: 0.2)
                : cores.rustIron.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            cadena.tipoAscensao.rotulo,
            style: TextStyle(
              color: cadena.isCadena ? cores.fernGreen : cores.rustIron,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      nomeVia,
                      style: TextStyle(
                        color: cores.chalkWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (grauVia != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cores.deepBasalt,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        grauVia,
                        style: TextStyle(
                          color: cores.rustIron,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$dataFormatada • ${cadena.tipoEscalada.rotulo} • ${cadena.tentativas} ${cadena.tentativas == 1 ? 'tentativa' : 'tentativas'}',
                style: TextStyle(color: cores.ashGrey, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (cadena.notasPrivadas.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '“${cadena.notasPrivadas}”',
                  style: TextStyle(
                    color: cores.ashGrey,

Future<bool?> exibirDialogoConfirmarExclusao(BuildContext context) async => false;
