import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/view_functions/via_functions.dart';

void main() {
  group('via_functions _buildTopBadges (Map Buttons)', () {
    testWidgets('nao deve exibir botao se escalada nao tiver referencia', (WidgetTester tester) async {
      final mapa = Mapa(pontosDeInteresse: []);
      final setor = Setor(nome: 'Setor A', mapas: [mapa]);
      final escalada = Escalada()..viaEsportiva = (ViaEsportiva()..nome = 'Via Teste');
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return buildViaBody(context, escalada, 'cragId', setor: setor);
            },
          ),
        ),
      ));
      
      expect(find.text('Ver no mapa'), findsNothing);
    });

    testWidgets('deve exibir botoes individuais para cada mapa que contem a referencia', (WidgetTester tester) async {
      final mapa1 = Mapa(
        referencias: [Mapa_Referencia(escalada: 'Via Dupla', ids: ['p1'])]
      );
      final mapa2 = Mapa(
        referencias: [Mapa_Referencia(escalada: 'Via Dupla', ids: ['p2'])]
      );
      final mapa3 = Mapa(
        referencias: []
      );
      final setor = Setor(nome: 'Setor B', mapas: [mapa1, mapa2, mapa3]);
      final escalada = Escalada()..viaEsportiva = (ViaEsportiva()..nome = 'Via Dupla');
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return buildViaBody(context, escalada, 'cragId', setor: setor);
            },
          ),
        ),
      ));
      
      expect(find.text('Ver no mapa 1'), findsOneWidget);
      expect(find.text('Ver no mapa 2'), findsOneWidget);
      expect(find.text('Ver no mapa 3'), findsNothing);
      expect(find.text('Ver no mapa'), findsNothing);
    });
  });
}
