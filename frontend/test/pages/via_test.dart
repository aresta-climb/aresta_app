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

  testWidgets('ViaPage should correctly receive and expose pico, setor, and grupo parameters', (tester) async {
    final pico = Pico()..nome = 'Pico Teste';
    final setor = Setor()..nome = 'Setor Teste';
    final grupo = Grupo()..nome = 'Grupo Teste';
    final escalada = Escalada()..viaEsportiva = (ViaEsportiva()..nome = 'Via Teste');

    await tester.pumpWidget(MaterialApp(
      home: ViaPage(
        escalada: escalada,
        cragId: 'crag1',
        pico: pico,
        setor: setor,
        grupo: grupo,
      ),
    ));

    final scaffoldFinder = find.byType(Scaffold);
    expect(scaffoldFinder, findsOneWidget);

    final viaPageFinder = find.byType(ViaPage);
    expect(viaPageFinder, findsOneWidget);
    
    final ViaPage page = tester.widget(viaPageFinder);
    expect(page.pico?.nome, 'Pico Teste');
    expect(page.setor?.nome, 'Setor Teste');
    expect(page.grupo?.nome, 'Grupo Teste');
  });
}
