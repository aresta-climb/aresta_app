import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/pages/terms_of_use.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter/services.dart';
import '../mocks/mock_telemetry_service.dart';

class MockAssetBundle extends Fake implements AssetBundle {
  final Map<String, String> mockFiles;

  MockAssetBundle(this.mockFiles);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (mockFiles.containsKey(key)) {
      return mockFiles[key]!;
    }
    throw FlutterError('Unable to load asset: $key');
  }
}

void main() {
  setUp(() {
    TelemetryService.instance = MockTelemetryService();
  });

  Widget createTestWidget({
    required bool isUpdatingTerms,
    required Map<String, String> files,
  }) {
    return MaterialApp(
      home: TermsOfUsePage(
        onAccepted: () {},
        isUpdatingTerms: isUpdatingTerms,
        assetBundle: MockAssetBundle(files),
      ),
    );
  }

  final defaultFiles = {
    'legal/repo/TERMOS_DE_USO_ARESTA_CLIMB.md': 'Mocked Terms',
    'legal/repo/POLITICA_DE_PRIVACIDADE_ARESTA_CLIMB.md': 'Mocked Privacy',
  };

  testWidgets(
    'TermsOfUsePage displays terms and requires checkbox to enable accept button',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(isUpdatingTerms: false, files: defaultFiles),
      );
      await tester.pumpAndSettle(); // Wait for async load

      expect(find.text('Termos e Privacidade'), findsOneWidget);
      expect(
        find.byType(MarkdownBody),
        findsOneWidget,
      ); // Finds the terms markdown

      final acceptButtonFinder = find.widgetWithText(ElevatedButton, 'Aceitar');
      expect(acceptButtonFinder, findsOneWidget);

      final ElevatedButton acceptButton = tester.widget(acceptButtonFinder);
      expect(acceptButton.enabled, isFalse);

      // No banner should be displayed because isUpdatingTerms is false
      expect(
        find.textContaining('Atualizamos nossos documentos legais'),
        findsNothing,
      );

      // Tap checkbox
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();

      final ElevatedButton acceptButtonEnabled = tester.widget(
        acceptButtonFinder,
      );
      expect(acceptButtonEnabled.enabled, isTrue);
    },
  );

  testWidgets('TermsOfUsePage shows generic banner for any updates', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      createTestWidget(isUpdatingTerms: true, files: defaultFiles),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Atualizamos nossos documentos legais'),
      findsOneWidget,
    );
  });
}
