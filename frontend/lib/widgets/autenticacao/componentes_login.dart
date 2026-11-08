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

/// Cabeçalho textual da tela de login exibindo título e subtítulo do modo atual.
class CabecalhoTelaLogin extends StatelessWidget {
  /// Título de destaque (ex.: entrar ou criar conta).
  final String titulo;

  /// Subtítulo explicativo sobre sincronização de cadenas e interações.
  final String subtitulo;

  /// Cria uma instância de [CabecalhoTelaLogin].
  const CabecalhoTelaLogin({
    super.key,
    required this.titulo,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            color: cores.chalkWhite,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitulo,
          style: TextStyle(
            color: cores.ashGrey,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

