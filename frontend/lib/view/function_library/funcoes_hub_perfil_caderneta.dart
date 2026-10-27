// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../theme/cores_app.dart';

/// Constrói o cabeçalho centralizado de identidade do atleta no Hub de Perfil.
///
/// Renderiza o avatar circular envolvido pelo anel de acento da marca,
/// o nome esportivo em destaque, o rótulo de função e o botão cápsula de edição.
Widget buildCabecalhoHubPerfil({
  required String nome,
  required String funcao,
  required VoidCallback onEditarPerfil,
  String? avatarUrl,
}) {
  return Builder(
    builder: (context) {
      final cores = context.colors;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar central com anel de acento vibrante
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE05A47), width: 2.5),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: cores.caveShadow,
              child: Icon(
                Icons.person,
                color: cores.chalkWhite,
                size: 42,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Nome do atleta
          Text(
            nome,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: cores.chalkWhite,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          // Subtítulo / Função esportiva
          Text(
            funcao,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          // Botão pílula "Editar perfil"
          InkWell(
            key: const Key('btn_editar_perfil_hub'),
            onTap: onEditarPerfil,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: cores.caveShadow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF3F4248)),
              ),
              child: Text(
                'Editar perfil',
                style: TextStyle(
                  color: cores.chalkWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// Constrói a barra horizontal contendo os 4 cartões de métricas rápidas.
Widget buildBarraMetricasHub({
  required int totalCadenas,
  required int totalTentativas,
  required int totalPicos,
  required int totalVias,
}) {
  return Builder(
    builder: (context) {
      // Cores vibrantes em harmonia com o design oficial
      const corCadenas = Color(0xFF22C55E); // Verde esmeralda vivo
      const corTentativas = Color(0xFFE05A47); // Coral/ferrugem vivo
      const corPicos = Color(0xFF94A3B8); // Slate/cinza límpido
      const corVias = Color(0xFFE05A47); // Coral/laranja vivo

      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: buildCardMetricaHub(
                key: const Key('card_metrica_cadenas'),
                icone: Icons.check_rounded,
                corIcone: corCadenas,
                corBorda: corCadenas.withValues(alpha: 0.28),
                valor: '$totalCadenas',
                rotulo: 'CADENAS',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: buildCardMetricaHub(
                key: const Key('card_metrica_tentativas'),
                icone: Icons.refresh_rounded,
                corIcone: corTentativas,
                corBorda: corTentativas.withValues(alpha: 0.28),
                valor: '$totalTentativas',
                rotulo: 'TENTATIVAS',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: buildCardMetricaHub(
                key: const Key('card_metrica_picos'),
                icone: Icons.terrain_rounded,
                corIcone: corPicos,
                corBorda: corPicos.withValues(alpha: 0.22),
                valor: '$totalPicos',
                rotulo: 'PICOS',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: buildCardMetricaHub(
                key: const Key('card_metrica_vias'),
                icone: Icons.alt_route_rounded,
                corIcone: corVias,
                corBorda: corVias.withValues(alpha: 0.28),
                valor: '$totalVias',
                rotulo: 'VIAS',
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Constrói um cartão individual de métrica rápida esportiva com cantos arredondados.
Widget buildCardMetricaHub({
  Key? key,
  required IconData icone,
  required Color corIcone,
  required String valor,
  required String rotulo,
  Color? corBorda,
}) {
  return Builder(
    builder: (context) {
      final cores = context.colors;
      final bordaEfetiva = corBorda ?? corIcone.withValues(alpha: 0.25);

      return Container(
        key: key,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 3),
        decoration: BoxDecoration(
          color: cores.caveShadow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bordaEfetiva, width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Selo circular com ícone temático
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: corIcone.withValues(alpha: 0.18),
              ),
              child: Icon(icone, color: corIcone, size: 18),
            ),
