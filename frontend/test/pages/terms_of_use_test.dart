import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/pages/terms_of_use.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../mocks/mock_telemetry_service.dart';

void main() {
  setUp(() {
    TelemetryService.instance = MockTelemetryService();
  });

  testWidgets('TermsOfUsePage displays terms and requires checkbox to enable accept button', (WidgetTester tester) async {
    bool accepted = false;

    await tester.pumpWidget(MaterialApp(
      home: TermsOfUsePage(
        onAccepted: () {
          accepted = true;
        },
      ),
    ));

    // Verify title and terms exist
    expect(find.text('Termos de Uso'), findsOneWidget); // AppBar title
    expect(find.byType(MarkdownBody), findsOneWidget);

    // Find the accept button
    final acceptButtonFinder = find.widgetWithText(ElevatedButton, 'Aceitar');
    expect(acceptButtonFinder, findsOneWidget);

    // The button should be disabled initially (onPressed is null)
    final ElevatedButton acceptButton = tester.widget(acceptButtonFinder);
    expect(acceptButton.enabled, isFalse);

    // Find the checkbox and tap it
    final checkboxFinder = find.byType(Checkbox);
    expect(checkboxFinder, findsOneWidget);
    
    // Let's tap the checkbox list tile. Ensure it's visible first since it's inside a ScrollView.
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    // Now the button should be enabled
    final ElevatedButton acceptButtonEnabled = tester.widget(acceptButtonFinder);
    expect(acceptButtonEnabled.enabled, isTrue);

    // Tap the accept button. Ensure it is visible first.
    await tester.ensureVisible(acceptButtonFinder);
    await tester.tap(acceptButtonFinder);
    await tester.pumpAndSettle();

    // Verify callback was called
    expect(accepted, isTrue);
  });
}
