import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:frontend/pages/via.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';

void main() {
  testWidgets('ViaPage should wrap body in SafeArea', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ViaPage(
        escalada: Escalada()..viaEsportiva = (ViaEsportiva()..nome = 'Via Teste'),
        cragId: 'crag1',
      ),
    ));

    final scaffoldFinder = find.byType(Scaffold);
    expect(scaffoldFinder, findsOneWidget);

    final Scaffold scaffold = tester.widget(scaffoldFinder);
    expect(scaffold.body, isA<SafeArea>());
    
    final SafeArea safeArea = scaffold.body as SafeArea;
    expect(safeArea.bottom, isTrue);
  });
}
