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

      // Caso 2: padding.bottom zerado por ancestral (0), mas viewPadding.bottom do SO segue 48px!
      await tester.pumpWidget(
        MaterialApp(
          theme: construirTemaEscuro(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              padding: EdgeInsets.zero,
              viewPadding: EdgeInsets.only(bottom: 48),
            ),
            child: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    key: const Key('btn_disparar_2'),
                    onPressed: () {
                      exibirSnackBarFlutuanteSeguro(
                        context,
                        texto: 'Notificação simples sem ação.',
                      );
                    },
                    child: const Text('Disparar 2'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_disparar_2')));
      await tester.pumpAndSettle();

      final superficieVisivel2 = find
          .descendant(
            of: find.byType(SnackBar),
            matching: find.byType(Material),
          )
          .first;
      final retangulo2 = tester.getRect(superficieVisivel2);
      // Mesmo com padding.bottom == 0, fica em 800 - 48 (SO) - 16 (folga) = 736px!
      expect(retangulo2.bottom, closeTo(736.0, 1.0));

      // Caso 3: MediaQuery intermediário zerou tanto padding quanto viewPadding, mas a janela física tem 48px!
      await tester.pumpWidget(
        MaterialApp(
          theme: construirTemaEscuro(),
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    key: const Key('btn_disparar_3'),
                    onPressed: () {
                      exibirSnackBarFlutuanteSeguro(
                        context,
                        texto: 'Resgatado via View.viewPadding.',
                      );
                    },
                    child: const Text('Disparar 3'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_disparar_3')));
      await tester.pumpAndSettle();

      final superficieVisivel3 = find
          .descendant(
            of: find.byType(SnackBar),
            matching: find.byType(Material),
          )
          .first;
      final retangulo3 = tester.getRect(superficieVisivel3);
      expect(retangulo3.bottom, closeTo(736.0, 1.0));
    },
  );
}
