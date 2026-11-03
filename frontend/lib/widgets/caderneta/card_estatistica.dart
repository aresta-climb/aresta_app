// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../services/caderneta/estatisticas_caderneta.dart';
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

/// Painel em grade 2x2 que apresenta as 4 métricas principais da caderneta esportiva
/// (`Total de Cadenas`, `Taxa À Vista/Flash`, `Maior Grau (Vias)` e `Maior Grau (Boulders)`).
///
/// Componente puramente declarativo (Dumb UI) que compõe instâncias de [CardEstatistica]
/// a partir de [EstatisticasCaderneta].
class PainelResumoEstatisticasCaderneta extends StatelessWidget {
  /// Estatísticas consolidadas da caderneta a serem exibidas nos 4 cartões.
  final EstatisticasCaderneta estatisticas;

  const PainelResumoEstatisticasCaderneta({
    super.key,
    required this.estatisticas,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: CardEstatistica(
                  key: const Key('card_resumo_total_cadenas'),
                  titulo: 'Total de Cadenas',
                  valor: '${estatisticas.totalCadenas}',
                  icone: Icons.check_circle_outline,
                  corIcone: cores.fernGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CardEstatistica(
                  key: const Key('card_resumo_taxa_avista_flash'),
                  titulo: 'Taxa À Vista/Flash',
                  valor: '${estatisticas.taxaAVistaFlash.round()}%',
                  icone: Icons.bolt_rounded,
                  corIcone: cores.rustIron,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: CardEstatistica(
                  key: const Key('card_resumo_maior_grau_via'),
                  titulo: 'Maior Grau (Vias)',
                  valor: estatisticas.maiorGrauVia ?? '-',
                  icone: Icons.trending_up_rounded,
                  corIcone: cores.rustIron,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CardEstatistica(
                  key: const Key('card_resumo_maior_grau_boulder'),
                  titulo: 'Maior Grau (Boulders)',
                  valor: estatisticas.maiorGrauBoulder ?? '-',
                  icone: Icons.landscape_rounded,
                  corIcone: cores.rustIron,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
