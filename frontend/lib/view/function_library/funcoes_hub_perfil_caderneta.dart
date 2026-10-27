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
