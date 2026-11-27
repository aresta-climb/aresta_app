// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';

import '../idioma/tradutor_app.dart';
import '../theme/cores_app.dart';

/// Mini Bottom Sheet explicativo exibido ao tocar no badge de tempo estimado de viagem em um card de pico.
///
/// Apresenta de forma legível o tempo médio em fluxo normal, a distância por estrada em quilômetros
/// e a explicação de que o cálculo é realizado offline pela malha do OpenStreetMap sem trânsito em tempo real.
class FolhaEstimativaViagemPico extends StatelessWidget {
  /// Nome ou título formatado do pico de escalada.
  final String tituloPico;

  /// Tempo médio estimado já arredondado (ex.: `'~1h'`, `'~1h 10min'`).
  final String tempoMedio;

  /// Distância estimada por estrada formatada em quilômetros (ex.: `'54.1 km'`).
  final String distanciaEstradaKm;

  /// Cria a folha explicativa imutável da estimativa de viagem até o pico.
  const FolhaEstimativaViagemPico({
    super.key,
    required this.tituloPico,
    required this.tempoMedio,
    required this.distanciaEstradaKm,
  });

  /// Abre a [FolhaEstimativaViagemPico] como um modal inferior compacto.
  static Future<void> exibir(
    BuildContext context, {
    required String tituloPico,
    required String tempoMedio,
    required String distanciaEstradaKm,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => FolhaEstimativaViagemPico(
        tituloPico: tituloPico,
        tempoMedio: tempoMedio,
        distanciaEstradaKm: distanciaEstradaKm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: cores.caveShadow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cores.graniteEdge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.brandColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_car_filled_rounded,
                    color: AppColors.brandColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(ChaveTexto.viagemSheetTitulo),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tituloPico,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cores.ashGrey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _BlocoMetricaViagem(
                    rotulo: context.tr(ChaveTexto.viagemSheetTempoMedioRotulo),
                    valor: tempoMedio,
                    icone: Icons.schedule_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BlocoMetricaViagem(
                    rotulo: context.tr(
                      ChaveTexto.viagemSheetDistanciaEstradaRotulo,
                    ),
                    valor: distanciaEstradaKm,
                    icone: Icons.route_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              context.tr(ChaveTexto.viagemSheetNotaExplicativa),
              style: TextStyle(
                color: cores.ashGrey,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('botao_fechar_folha_estimativa_viagem'),
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  context.tr(ChaveTexto.viagemSheetFecharBtn),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlocoMetricaViagem extends StatelessWidget {
  final String rotulo;
  final String valor;
  final IconData icone;

  const _BlocoMetricaViagem({
    required this.rotulo,
    required this.valor,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cores.darkPine,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cores.graniteEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 14, color: AppColors.brandColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  rotulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cores.ashGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
