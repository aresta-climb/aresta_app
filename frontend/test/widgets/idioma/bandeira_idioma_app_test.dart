// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/idioma/modelo_idioma_app.dart';
import 'package:frontend/widgets/idioma/bandeira_idioma_app.dart';

void main() {
  group('BandeiraIdiomaApp e PintorBandeiraIdioma', () {
    testWidgets(
      'renderiza as cinco bandeiras vetoriais sem widgets Image e atualiza pintura quando idioma ou raio mudam',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  for (final idioma in IdiomaApp.values)
                    BandeiraIdiomaApp(
                      key: Key('bandeira_${idioma.codigoIso}'),
                      idioma: idioma,
                      largura: 28,
                      altura: 20,
                      raioBorda: 4.5,
                    ),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(BandeiraIdiomaApp), findsNWidgets(5));
        expect(find.byType(Image), findsNothing);

        // Exercita shouldRepaint em PintorBandeiraIdioma (mesmos parametros vs idioma/raio diferentes)
        const p1 = PintorBandeiraIdioma(
          idioma: IdiomaApp.portugues,
          raioBorda: 4.0,
        );
        const pIgual = PintorBandeiraIdioma(
          idioma: IdiomaApp.portugues,
          raioBorda: 4.0,
        );
        const pOutroIdioma = PintorBandeiraIdioma(
          idioma: IdiomaApp.ingles,
          raioBorda: 4.0,
        );
        const pOutroRaio = PintorBandeiraIdioma(
          idioma: IdiomaApp.portugues,
          raioBorda: 6.0,
        );

        expect(p1.shouldRepaint(pIgual), isFalse);
        expect(p1.shouldRepaint(pOutroIdioma), isTrue);
        expect(p1.shouldRepaint(pOutroRaio), isTrue);
      },
    );
  });
}
