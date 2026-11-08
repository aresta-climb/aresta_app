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

/// Botão padronizado para provedores de login social OAuth (Google, Apple).
class BotaoProvedorOAuthLogin extends StatelessWidget {
  /// Rótulo exibido ao lado do distintivo do provedor.
  final String rotulo;

  /// Ícone ou letra estilizada que identifica o provedor OAuth.
  final Widget distintivo;

  /// Callback acionado ao pressionar o botão (`null` desabilita durante carregamento).
  final VoidCallback? aoPressionar;

  /// Cria uma instância de [BotaoProvedorOAuthLogin].
  const BotaoProvedorOAuthLogin({
    super.key,
    required this.rotulo,
    required this.distintivo,
    required this.aoPressionar,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return OutlinedButton(
      onPressed: aoPressionar,
      style: OutlinedButton.styleFrom(
        backgroundColor: cores.caveShadow,
        foregroundColor: cores.chalkWhite,
        side: BorderSide(color: cores.graniteEdge, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: distintivo,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              rotulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cores.chalkWhite,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

