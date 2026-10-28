// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../theme/cores_app.dart';

/// Tela de splash reativa exibida imediatamente na abertura do aplicativo (*Cold Start*)
/// enquanto o bootstrap paralelo e a resolução inicial de Deep Links estão em andamento.
///
/// Mantém a identidade visual da splash nativa (`#ffffff` + `assets/logo_splash.png`),
/// eliminando qualquer janela em branco durante a inicialização ou download sob demanda.
class TelaSplashInicial extends StatelessWidget {
  /// Define se um indicador discreto de progresso deve ser exibido abaixo da logo.
  final bool exibirIndicadorCarregamento;

  const TelaSplashInicial({
    super.key,
    this.exibirIndicadorCarregamento = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/logo_splash.png',
              width: 288,
              height: 288,
              fit: BoxFit.contain,
            ),
            if (exibirIndicadorCarregamento)
              const Padding(
                padding: EdgeInsets.only(top: 192),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.brandColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
