import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/pages/mapa_geral_pico.dart';

void main() {
  testWidgets('MapaGeralPicoPage renders back button if canGoBack is true', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => MapaGeralPicoPage(
                      pico: Pico()..nome = 'Pico Teste',
                      croqui: Croqui(),
                      cragId: '1',
                    ),
                  ));
                },
                child: const Text('Push'),
              ),
            ),
          );
        },
      ),
    ));

    await tester.tap(find.text('Push'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });
  
  testWidgets('MapaGeralPicoPage does NOT render back button if canGoBack is false', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: MapaGeralPicoPage(
        pico: Pico()..nome = 'Pico Teste',
        croqui: Croqui(),
        cragId: '1',
      ),
    ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });
}
