import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:frontend/pages/setor.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';

void main() {
  testWidgets('SetorPage should wrap body in SafeArea', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SetorPage(setor: Setor()..nome = 'Setor Teste', cragId: 'crag1'),
      ),
    );

    final scaffoldFinder = find.byType(Scaffold);
    expect(scaffoldFinder, findsOneWidget);

    expect(find.byType(SafeArea), findsWidgets);
    final safeAreas = tester.widgetList<SafeArea>(find.byType(SafeArea));
    expect(safeAreas.any((sa) => sa.bottom == true), isTrue);
  });

  testWidgets('SetorPage should handle scrollToEscalada gracefully without crashing', (tester) async {
    final via1 = Escalada(viaEsportiva: ViaEsportiva(nome: 'Via 1'));
    final via2 = Escalada(viaEsportiva: ViaEsportiva(nome: 'Via 2'));
    final setor = Setor()
      ..nome = 'Setor Teste'
      ..escaladas.addAll([via1, via2]);

    await tester.pumpWidget(
      MaterialApp(
        home: SetorPage(
          setor: setor,
          cragId: 'crag1',
          scrollToEscalada: via2,
        ),
      ),
    );

    // Avança o timer de 400ms do delay do scroll e processa o post-frame callback
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Via 2'), findsOneWidget);

    // Atualiza o widget com outra via para exercitar o didUpdateWidget
    await tester.pumpWidget(
      MaterialApp(
        home: SetorPage(
          setor: setor,
          cragId: 'crag1',
          scrollToEscalada: via1,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Via 1'), findsOneWidget);
  });
}
