// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../theme/cores_app.dart';

/// Barra inferior fixa ao alcance do polegar (*Thumb Dock*, Dumb UI) exibindo a ação primária
/// de registro de cadena ou tentativa alinhada com os cartões da `ViaPage`.
class BarraInferiorAcoesVia extends StatelessWidget {
  /// Indica se o botão principal de caderneta deve ser exibido.
  final bool exibirBotaoCaderneta;

  /// Indica se o escalador já encadenou a via (destacando o botão em verde musgo).
  final bool possuiCadena;

  /// Rótulo exibido no botão principal de caderneta.
  final String rotuloBotaoCaderneta;

  /// Callback acionado ao tocar no botão de registro de cadena/tentativa.
  final VoidCallback aoRegistrarCadena;

  /// Cria uma instância de [BarraInferiorAcoesVia].
  const BarraInferiorAcoesVia({
    super.key,
    required this.exibirBotaoCaderneta,
    required this.possuiCadena,
    required this.rotuloBotaoCaderneta,
    required this.aoRegistrarCadena,
  });

  @override
  Widget build(BuildContext context) {
    if (!exibirBotaoCaderneta) {
      return const SizedBox.shrink();
    }
    final cores = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: cores.deepBasalt,
        border: Border(top: BorderSide(color: cores.graniteEdge)),
      ),
      child: Row(
        children: [
          if (exibirBotaoCaderneta)
            Expanded(
              child: ElevatedButton.icon(
                key: const Key('btn_registrar_cadena'),
                onPressed: aoRegistrarCadena,
                icon: Icon(
                  possuiCadena
                      ? Icons.check_circle_outline_rounded
                      : Icons.bookmark_add_outlined,
                  size: 18,
                  color: cores.chalkWhite,
                ),
                label: Text(
                  rotuloBotaoCaderneta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: possuiCadena
                      ? cores.darkPine
                      : AppColors.brandColor,
                  foregroundColor: cores.chalkWhite,
                  side: possuiCadena
                      ? BorderSide(color: cores.fernGreen)
                      : null,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
