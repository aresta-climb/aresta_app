// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../theme/cores_app.dart';

/// Cartão modular de configuração (Dumb UI) para exibir ou ocultar os elementos
/// interativos de Perfil e Caderneta Esportiva na interface do aplicativo.
class CartaoPreferenciaCaderneta extends StatelessWidget {
  /// Fonte reativa indicando se as interações de perfil e caderneta estão visíveis.
  final ValueListenable<bool> interacoesAtivasListenable;

  /// Callback acionado quando o usuário alterna o estado do interruptor.
  final ValueChanged<bool> aoAlternar;

  const CartaoPreferenciaCaderneta({
    super.key,
    required this.interacoesAtivasListenable,
    required this.aoAlternar,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return Card(
      elevation: 0,
      color: cores.caveShadow,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cores.graniteEdge,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.menu_book_outlined,
                    color: cores.ashGrey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
