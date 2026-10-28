// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/pages/tela_splash_inicial.dart';

void main() {
  group('TelaSplashInicial', () {
    testWidgets(
      'renderiza fundo branco (#ffffff) e imagem centralizada assets/logo_splash.png por padrão sem indicador de carregamento',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: TelaSplashInicial(),
          ),
        );

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, equals(const Color(0xFFFFFFFF)));

        final image = tester.widget<Image>(find.byType(Image));
        expect(image.image, isA<AssetImage>());
        final assetImage = image.image as AssetImage;
        expect(assetImage.assetName, equals('assets/logo_splash.png'));
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      'exibe CircularProgressIndicator discreto quando exibirIndicadorCarregamento é true',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: TelaSplashInicial(exibirIndicadorCarregamento: true),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );
  });
}
