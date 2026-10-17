// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../theme/cores_app.dart';

/// Diálogo modal exibido quando a sessão de prévia (Modo Experimental) do Editor Desktop
/// é encerrada ou expira no servidor remoto.
///
/// Informa ao escalador, de maneira clara e acolhedora, que a conexão temporária com o
/// Editor Desktop foi finalizada e que o aplicativo restaurou automaticamente o catálogo
/// oficial de produção do Aresta Climb.
class ModalSessaoExperimentalEncerrada extends StatelessWidget {
  /// Indica se o modal já está atualmente aberto na tela para evitar empilhamento duplicado.
  static bool _estaExibindo = false;

  /// Callback opcional acionado antes de fechar o modal ao tocar no botão de confirmação.
  final VoidCallback? aoConfirmar;

  const ModalSessaoExperimentalEncerrada({
    super.key,
    this.aoConfirmar,
  });

  /// Reinicia a flag de controle de exibição para isolamento em testes automatizados.
  @visibleForTesting
  static void resetarParaTestes() {
    _estaExibindo = false;
  }

  /// Exibe o diálogo modal no `Navigator` raiz, protegendo contra aberturas simultâneas duplicadas.
  static Future<void> exibir(
    BuildContext context, {
    VoidCallback? aoConfirmar,
  }) async {
    if (_estaExibindo) return;
    _estaExibindo = true;

    try {
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (dialogContext) => ModalSessaoExperimentalEncerrada(
          aoConfirmar: aoConfirmar,
        ),
      );
    } finally {
      _estaExibindo = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    const corDestaque = AppColors.brandColor;

    return AlertDialog(
      backgroundColor: context.colors.caveShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.colors.graniteEdge),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: corDestaque.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: corDestaque,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Sessão de Prévia Encerrada',
            style: TextStyle(
              color: context.colors.chalkWhite,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Text(
        'A conexão com o Editor Desktop foi finalizada. Como o modo de prévia é temporário, restauramos automaticamente o catálogo oficial do Aresta Climb para você continuar navegando.',
        style: TextStyle(
          color: context.colors.ashGrey,
          fontSize: 14,
          height: 1.45,
        ),
        textAlign: TextAlign.center,
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: const Key('btn_entendi_sessao_experimental_encerrada'),
            style: ElevatedButton.styleFrom(
              backgroundColor: corDestaque,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () {
              aoConfirmar?.call();
              if (Navigator.of(context, rootNavigator: true).canPop()) {
                Navigator.of(context, rootNavigator: true).pop();
              }
            },
            child: const Text(
              'ENTENDI',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
