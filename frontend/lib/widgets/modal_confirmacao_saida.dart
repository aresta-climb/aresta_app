// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../view_functions/common_functions.dart';
import '../services/firebase/telemetry_service.dart';

/// Modal de confirmação e conscientização ("Guardião de Saída") exibido
/// quando o usuário tenta sair de um croqui explorado online sem tê-lo salvo offline.
class ModalConfirmacaoSaida extends StatelessWidget {
  /// Controla se o aviso do Guardião já foi exibido durante a sessão atual do app.
  static bool exibiuNestaSessao = false;

  /// Reseta a flag de exibição da sessão (utilizado em testes unitários).
  static void resetarSessaoParaTestes() {
    exibiuNestaSessao = false;
  }

  /// Nome do pico sendo explorado.
  final String nomePico;

  /// Tamanho pré-formatado do download (opcional).
  final String? tamanhoFormatado;

  /// Ação executada ao escolher salvar o croqui offline.
  final VoidCallback onSalvar;

  /// Ação executada ao escolher sair sem salvar.
  final VoidCallback onSairSemSalvar;

  const ModalConfirmacaoSaida({
    super.key,
    required this.nomePico,
    this.tamanhoFormatado,
    required this.onSalvar,
    required this.onSairSemSalvar,
  });

  /// Exibe o modal como bottom sheet ou diálogo estilizado.
  ///
  /// Garante que o aviso seja exibido no máximo **uma única vez por sessão do aplicativo**,
  /// a menos que [forcarExibicao] seja explicitamente definido como `true`.
  static Future<void> mostrar({
    required BuildContext context,
    required String nomePico,
    String? cragId,
    String? tamanhoFormatado,
    required VoidCallback onSalvar,
    required VoidCallback onSairSemSalvar,
    bool forcarExibicao = false,
  }) {
    if (exibiuNestaSessao && !forcarExibicao) {
      onSairSemSalvar();
      return Future.value();
    }
    exibiuNestaSessao = true;
    final idCroqui = cragId ?? nomePico;
    TelemetryService.instance.logAcaoGuardiaoSaida(idCroqui, 'exibir_modal');

    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.colors.deepBasalt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ModalConfirmacaoSaida(
        nomePico: nomePico,
        tamanhoFormatado: tamanhoFormatado,
        onSalvar: () {
          TelemetryService.instance.logAcaoGuardiaoSaida(idCroqui, 'guardiao_salvar_offline');
          Navigator.pop(ctx);
          onSalvar();
        },
        onSairSemSalvar: () {
          TelemetryService.instance.logAcaoGuardiaoSaida(idCroqui, 'guardiao_sair_sem_salvar');
          Navigator.pop(ctx);
          onSairSemSalvar();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String rotuloBotao = (tamanhoFormatado != null &&
            tamanhoFormatado!.isNotEmpty &&
            tamanhoFormatado != '0 B' &&
            tamanhoFormatado != 'Offline')
        ? 'Salvar Offline ($tamanhoFormatado)'
        : 'Salvar Offline';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.graniteEdge,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC05244).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.signal_wifi_off_rounded,
                          color: Color(0xFFC05244),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'SALVAR PARA A PEDRA?',
                          style: TextStyle(
                            color: context.colors.chalkWhite,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                buildFeedbackButton(context, color: context.colors.chalkWhite),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Lembre-se: na rocha não há sinal de internet. Para consultar os croquis e graus de $nomePico sem conexão, salve o guia offline.',
              style: TextStyle(
                color: context.colors.ashGrey,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSalvar,
                icon: const Icon(Icons.download, color: Colors.white, size: 18),
                label: Text(
                  rotuloBotao,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B8B6F),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onSairSemSalvar,
                child: Text(
                  'Sair sem Salvar',
                  style: TextStyle(
                    color: context.colors.ashGrey,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
