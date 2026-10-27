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
