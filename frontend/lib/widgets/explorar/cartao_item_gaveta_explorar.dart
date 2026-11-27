// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/modelos/modelos_clima_pico.dart';
import '../../theme/cores_app.dart';
import '../../view/view_models/card_croqui_view_model.dart';
import '../card_pico.dart';
import '../clima/selo_umidade_pico.dart';

/// Cartão individual de pico exibido na gaveta deslizante da aba `Explorar` (Dumb UI).
///
/// Combina [CragCard], selo altimétrico (`Alt. <N>m`), botão rápido de foco no globo
/// e tarja contextual de umidade quando a rocha encontra-se úmida.
class CartaoItemGavetaExplorar extends StatelessWidget {
  final CardCroquiViewModel card;
  final int? altitudeMetros;
  final EstadoUmidadePico umidade;
  final bool selecionado;
  final bool emPulsoDestaque;
  final ValueListenable<Map<String, double>> downloadingCrags;
  final VoidCallback aoAbrir;
  final VoidCallback aoFocarNoGlobo;

  const CartaoItemGavetaExplorar({
    super.key,
    required this.card,
    required this.altitudeMetros,
    required this.umidade,
    required this.selecionado,
    required this.emPulsoDestaque,
    required this.downloadingCrags,
    required this.aoAbrir,
    required this.aoFocarNoGlobo,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final corBorda = emPulsoDestaque
        ? colors.rustIron
        : (selecionado ? Colors.white38 : Colors.transparent);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: corBorda,
              width: emPulsoDestaque ? 2.4 : 1.2,
            ),
          ),
          child: Stack(
            children: [
              CragCard(
                dados: card,
                downloadingCrags: downloadingCrags,
                onDownload: aoAbrir,
                onOpen: aoAbrir,
              ),
              Positioned(
                top: 18,
                right: 16,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (altitudeMetros != null) ...[
                      Container(
                        key: Key('badge_altitude_${card.id}'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xCC0F151D),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.terrain_rounded,
                              size: 12,
                              color: Color(0xFFD1D5DB),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Alt. ${altitudeMetros}m',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Material(
                      color: const Color(0xCC0F151D),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        key: Key('botao_ver_no_globo_${card.id}'),
                        borderRadius: BorderRadius.circular(12),
                        onTap: aoFocarNoGlobo,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          child: Icon(
                            Icons.public_rounded,
                            size: 14,
                            color: Color(0xFFE27D60),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (umidade.nivel.estaUmido)
          TarjaUmidadePico(
            key: Key('alerta_umidade_${card.id}'),
            umidade: umidade,
            margem: const EdgeInsets.only(top: 6),
          ),
      ],
    );
  }
}
