import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:frontend/pages/setor.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';

void main() {
  testWidgets('SetorPage should wrap body in SafeArea', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SetorPage(
        setor: Setor()..nome = 'Setor Teste',
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
