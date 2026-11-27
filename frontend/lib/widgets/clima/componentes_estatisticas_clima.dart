// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';

import '../../data/modelos/modelos_estatisticas_clima.dart';
import '../../idioma/tradutor_app.dart';
import '../../theme/cores_app.dart';

/// Cartão de seção padronizado na identidade basalto/ferrugem para a página de estatísticas climáticas.
class CartaoSecaoEstatisticaClima extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final Widget filho;

  const CartaoSecaoEstatisticaClima({
    super.key,
    required this.icone,
    required this.titulo,
    required this.filho,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cores.caveShadow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cores.graniteEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(icone, size: 16, color: cores.rustIron),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: cores.chalkWhite,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          filho,
        ],
      ),
    );
  }
}

/// Linha estruturada de fórmula estatística com resultado alinhado à direita sem quebras no meio de números.
class LinhaFormulaEstatisticaClima extends StatelessWidget {
  final String titulo;
  final String equacao;
  final String resultado;
  final bool destaque;

  const LinhaFormulaEstatisticaClima({
    super.key,
    required this.titulo,
    required this.equacao,
    required this.resultado,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                titulo,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: cores.chalkWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              resultado,
              style: TextStyle(
                fontFamily: 'monospace',
                color: destaque ? cores.rustIron : cores.chalkWhite,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          equacao,
          style: TextStyle(
            fontFamily: 'monospace',
            color: cores.ashGrey,
            fontSize: 11,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

/// Linha responsiva em dois níveis para a Tabela Normal Padrão `Z`, evitando esmagamento horizontal.
class LinhaTabelaZResponsivaClima extends StatelessWidget {
  final LinhaTabelaPadraoZ linha;

  const LinhaTabelaZResponsivaClima({super.key, required this.linha});

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: linha.destacar
            ? cores.rustIron.withValues(alpha: 0.11)
            : Colors.transparent,
        border: Border(
          top: BorderSide(
            color: cores.graniteEdge.withValues(alpha: 0.55),
            width: 0.6,
          ),
          left: linha.destacar
              ? BorderSide(color: cores.rustIron, width: 3.0)
              : BorderSide.none,
        ),
      ),
      padding: EdgeInsets.fromLTRB(linha.destacar ? 10 : 12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '+${linha.escoreZ.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: linha.destacar ? cores.rustIron : cores.chalkWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  linha.probabilidadeAcumuladaPhi.toStringAsFixed(4),
