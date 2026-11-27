// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../idioma/tradutor_app.dart';
import '../../theme/cores_app.dart';

/// Exibe o modal centralizado no padrão visual do Aresta Climb informando a taxa
/// empírica de detecção (~86%) antes de habilitar a camada opcional de chuva e fogo no mapa.
Future<bool> exibirDialogoAvisoPrecisaoClima(BuildContext context) async {
  final confirmado = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black87,
    builder: (ctx) => const DialogoAvisoPrecisaoClima(),
  );
  return confirmado ?? false;
}

/// Modal declarativo (Dumb UI) alinhado à identidade basalto/ferrugem do Aresta Climb,
/// com cabeçalho centralizado, medidor estatístico (~86%) e botões empilhados de largura total.
class DialogoAvisoPrecisaoClima extends StatelessWidget {
  const DialogoAvisoPrecisaoClima({super.key});

  @override
  Widget build(BuildContext context) {
    context.idiomaApp;
    final cores = context.colors;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 356),
        child: Container(
          key: const Key('dialogo_aviso_precisao_clima'),
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
          decoration: BoxDecoration(
            color: cores.deepBasalt,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cores.graniteEdge, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0xBD000000),
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cores.rustIron.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cores.rustIron.withValues(alpha: 0.42),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    Icons.radar_rounded,
                    size: 24,
                    color: cores.rustIron,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tr(ChaveTexto.explorarAvisoClimaTitulo).toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: cores.chalkWhite,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: cores.caveShadow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cores.graniteEdge),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 16,
                        color: cores.rustIron,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '~86%',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          color: cores.chalkWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: Container(
                            height: 6,
                            color: cores.graniteEdge,
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: 0.86,
                              child: Container(color: cores.rustIron),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  tr(ChaveTexto.explorarAvisoClimaCorpo),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cores.ashGrey,
                    fontSize: 13,
                    height: 1.42,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    key: const Key('botao_confirmar_aviso_clima'),
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(
                      Icons.layers_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      tr(ChaveTexto.explorarAvisoClimaConfirmar),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cores.rustIron,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    key: const Key('botao_cancelar_aviso_clima'),
                    onPressed: () => Navigator.of(context).pop(false),
