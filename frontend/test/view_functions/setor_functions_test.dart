// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/view_functions/setor_functions.dart';

void main() {
  group('resolveRouteLabels e RotulosVia', () {
    test('retorna rótulos vazios quando não há mapas no setor', () {
      final rotulos = resolveRouteLabels(Escalada(), Setor());
      expect(rotulos.mapIndicator, isEmpty);
      expect(rotulos.resolvedLabel, isEmpty);
    });

    test('instancia RotulosVia corretamente com valores tipados', () {
      const rotulos = RotulosVia(
        mapIndicator: 'M1',
        resolvedLabel: '1-A',
      );
      expect(rotulos.mapIndicator, 'M1');
      expect(rotulos.resolvedLabel, '1-A');
    });

    test('resolve rótulos e indicador do mapa quando há mapas e pontos', () {
      final mapa1 = Mapa(
        referencias: [
          Mapa_Referencia(
            escalada: 'Via dos Sonhos',
            ids: ['p1', 'p2'],
          ),
        ],
        pontosDeInteresse: [
          Mapa_PontoDeInteresse(id: 'p1', label: '1'),
          Mapa_PontoDeInteresse(id: 'p2', label: ''),
        ],
      );
      final mapa2 = Mapa();
      final setor = Setor(mapas: [mapa1, mapa2]);
      final escalada = Escalada(
        viaEsportiva: ViaEsportiva(
          nome: 'Via dos Sonhos',
          indiceMapaPadrao: 0,
        ),
      );

      final rotulos = resolveRouteLabels(escalada, setor);
      expect(rotulos.mapIndicator, 'M1');
      expect(rotulos.resolvedLabel, '1-p2');
    });
  });

  group('buildEscaladaSortGrid', () {
    testWidgets('renderiza botões e chama onSortChanged', (WidgetTester tester) async {
      EscaladaSortMode? selectedMode;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => buildEscaladaSortGrid(
              context,
              EscaladaSortMode.original,
              (mode) {
                selectedMode = mode;
              },
            ),
          ),
        ),
      ));

      expect(find.text('PADRÃO'), findsOneWidget);
      expect(find.text('ALFABÉTICO'), findsOneWidget);
      expect(find.text('DIFICULDADE'), findsOneWidget);

      await tester.tap(find.text('ALFABÉTICO'));
      await tester.pump();
      expect(selectedMode, EscaladaSortMode.alphaAsc);
      
      await tester.tap(find.text('DIFICULDADE'));
      await tester.pump();
      expect(selectedMode, EscaladaSortMode.gradeAsc);
    });
  });

  group('buildSetorBody', () {
    testWidgets('renderiza vias e destaca via alvo', (WidgetTester tester) async {
      final via = Escalada(
        viaEsportiva: ViaEsportiva(
          nome: 'Via Teste',
          destaque: true,
        ),
      );
      final setor = Setor(nome: 'Setor Principal');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => buildSetorBody(
              context,
              setor,
              'crag_1',
              [via],
              via,
              GlobalKey(),
            ),
          ),
        ),
      ));

      expect(find.text('Via Teste'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });
}
