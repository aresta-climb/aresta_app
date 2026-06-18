import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:frontend/pages/login_page.dart';

void main() {
  testWidgets('LoginPage renders email field and login buttons', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: LoginPage(),
    ));

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Enviar Link Mágico'), findsOneWidget);
    expect(find.text('Entrar com Google'), findsOneWidget);
    expect(find.text('Entrar com Apple'), findsOneWidget);
  });
}
