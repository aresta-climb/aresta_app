// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/clima/grafico_distribuicao_z_clima.dart';

void main() {
  group('GraficoDistribuicaoZClima', () {
    testWidgets(
      'renderiza curva normal padrão H0, região crítica na cauda direita e marcadores de Z',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  child: GraficoDistribuicaoZClima(
                    rotuloH0: 'Distribuição Nula (H₀)',
                    rotuloCaudaDireita: 'Cauda direita (+27,7σ)',
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(GraficoDistribuicaoZClima), findsOneWidget);
        expect(find.text('Distribuição Nula (H₀)'), findsOneWidget);
        expect(find.text('Cauda direita (+27,7σ)'), findsOneWidget);

        // Exercita shouldRepaint ao atualizar rótulos/cores
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  child: GraficoDistribuicaoZClima(
                    rotuloH0: 'Null Distribution (H₀)',
                    rotuloCaudaDireita: 'Right tail (+27.7σ)',
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.text('Null Distribution (H₀)'), findsOneWidget);
      },
    );
  });
}
