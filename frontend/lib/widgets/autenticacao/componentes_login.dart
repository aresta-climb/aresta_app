// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../theme/cores_app.dart';

/// Barra superior declarativa da tela de login com botão de retorno e marca.
class BarraTopoLogin extends StatelessWidget {
  /// Callback acionado ao tocar no botão de voltar.
  final VoidCallback aoVoltar;

  /// Cria uma instância de [BarraTopoLogin].
  const BarraTopoLogin({
    super.key,
    required this.aoVoltar,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 20, 0),
      child: Row(
        children: [
          IconButton(
            key: const Key('btn_voltar_login'),
            icon: Icon(Icons.arrow_back, color: cores.chalkWhite),
            tooltip: 'Voltar',
            onPressed: aoVoltar,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'ARESTA CLIMB',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cores.dryMoss,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

