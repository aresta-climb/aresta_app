import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/pages/mapas_carrossel.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';

// Dummy widget to inject as MapasCarrosselPage's mapBuilder to avoid complex MapHelper dependencies in tests.
class DummyMapaInterativo extends StatelessWidget {
  final int index;
  const DummyMapaInterativo(this.index, {super.key});
  
  @override
  Widget build(BuildContext context) {
    return Text('MapaInterativo $index');
  }
}

void main() {
  group('MapasCarrosselPage Tests', () {
    testWidgets('Renders properly with multiple maps', (tester) async {
      final pico = Pico()..nome = 'Pico Teste';
      
      final mapas = [
        const CarrosselItemData(mapaCaminhoImagem: 'map1.png'),
        const CarrosselItemData(mapaCaminhoImagem: 'map2.png'),
        const CarrosselItemData(mapaCaminhoImagem: 'map3.png'),
      ];

      await tester.pumpWidget(MaterialApp(
        home: MapasCarrosselPage(
          pico: pico,
          cragId: '1',
          mapas: mapas,
          initialIndex: 0,
          mapBuilder: (context, index, item) => DummyMapaInterativo(index),
        ),
      ));

      // Should render the first map
      expect(find.text('MapaInterativo 0'), findsOneWidget);
      expect(find.text('MapaInterativo 1'), findsNothing);

      // Should render the pagination text
      expect(find.text('01 de 03'), findsOneWidget);

      // Verify that the new AppBar is present instead of just a floating widget
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('Navigation arrows work correctly', (tester) async {
      final pico = Pico()..nome = 'Pico Teste';
      final mapas = [
        const CarrosselItemData(mapaCaminhoImagem: 'map1.png'),
        const CarrosselItemData(mapaCaminhoImagem: 'map2.png'),
        const CarrosselItemData(mapaCaminhoImagem: 'map3.png'),
      ];

      await tester.pumpWidget(MaterialApp(
        home: MapasCarrosselPage(
          pico: pico,
          cragId: '1',
          mapas: mapas,
          initialIndex: 1, // Start in the middle
          mapBuilder: (context, index, item) => DummyMapaInterativo(index),
        ),
      ));

      expect(find.text('02 de 03'), findsOneWidget);
      expect(find.text('MapaInterativo 1'), findsOneWidget);

      // Click Right
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(find.text('03 de 03'), findsOneWidget);
      expect(find.text('MapaInterativo 2'), findsOneWidget);
      
      // Click Right again (should do nothing because we are at the end)
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.text('03 de 03'), findsOneWidget);

      // Click Left x 2
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(find.text('01 de 03'), findsOneWidget);
      expect(find.text('MapaInterativo 0'), findsOneWidget);
      
      // Click Left again (should do nothing because we are at the beginning)
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      expect(find.text('01 de 03'), findsOneWidget);
    });

    testWidgets('Updates page when initialIndex changes in didUpdateWidget', (tester) async {
      final pico = Pico()..nome = 'Pico Teste';
      final mapas = [
        const CarrosselItemData(mapaCaminhoImagem: 'map1.png'),
        const CarrosselItemData(mapaCaminhoImagem: 'map2.png'),
        const CarrosselItemData(mapaCaminhoImagem: 'map3.png'),
      ];

      Widget buildCarousel(int initialIndex) {
        return MaterialApp(
          home: MapasCarrosselPage(
            pico: pico,
            cragId: '1',
            mapas: mapas,
            initialIndex: initialIndex,
            mapBuilder: (context, index, item) => DummyMapaInterativo(index),
          ),
        );
      }

      await tester.pumpWidget(buildCarousel(0));
      expect(find.text('01 de 03'), findsOneWidget);
      expect(find.text('MapaInterativo 0'), findsOneWidget);

      // Update widget with new initialIndex (simulating clicking "Ver mapas (N)" again)
      await tester.pumpWidget(buildCarousel(2));
      await tester.pumpAndSettle();

      expect(find.text('03 de 03'), findsOneWidget);
      expect(find.text('MapaInterativo 2'), findsOneWidget);
    });
  });
}
