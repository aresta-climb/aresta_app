// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme/temas.dart';
import 'package:frontend/widgets/via/snackbar_flutuante_seguro.dart';

void main() {
  testWidgets(
    'posiciona a pílula visível do SnackBar estritamente acima dos botões inferiores do SO com ou sem consumo prévio de padding',
    (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(400, 800);
      tester.view.viewPadding = const FakeViewPadding(bottom: 48);
      tester.view.padding = const FakeViewPadding(bottom: 48);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewPadding();
        tester.view.resetPadding();
      });

      // Caso 1: padding.bottom == 48 e viewPadding.bottom == 48 + dock extra de 72px
      await tester.pumpWidget(
        MaterialApp(
          theme: construirTemaEscuro(),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  key: const Key('btn_disparar_1'),
                  onPressed: () {
                    final despachante = capturarDespachanteSnackBarSeguro(
                      context,
                      recuoExtraInferior: 72,
                    );
                    despachante.exibir(
                      texto: 'Alerta marcado como resolvido.',
                      duracao: const Duration(seconds: 4),
                      rotuloAcao: 'Desfazer',
                      aoAcionar: () {},
                    );
                  },
                  child: const Text('Disparar'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('btn_disparar_1')));
      await tester.pumpAndSettle();

      final superficieVisivel1 = find
          .descendant(
            of: find.byType(SnackBar),
            matching: find.byType(Material),
          )
          .first;
      final retangulo1 = tester.getRect(superficieVisivel1);
      // 800 - 48 (SO) - 72 (dock) - 16 (folga) = 664 (sem dupla contagem de 48!)
      expect(retangulo1.bottom, closeTo(664.0, 1.0));
      expect(retangulo1.left, closeTo(16.0, 1.0));
      expect(retangulo1.right, closeTo(384.0, 1.0));
  });
}
