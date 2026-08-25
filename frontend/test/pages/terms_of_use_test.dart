// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/pages/terms_of_use.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    'legal/repo/public/docs/termos-de-uso.md':
        '### TERMOS DE USO E ACEITAÇÃO DE RISCOS\nConteúdo mockado dos termos.',
    'legal/repo/public/docs/politica-de-privacidade.md': 'Mocked Privacy',
  };

  testWidgets(
    'TermsOfUsePage displays terms and requires checkbox to enable accept button',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(isUpdatingTerms: false, files: defaultFiles),
      );
      await tester.pumpAndSettle(); // Wait for async load

      expect(
        find.byType(MarkdownBody),
        findsOneWidget,
      ); // Finds the terms markdown

      final acceptButtonFinder = find.widgetWithText(
        FilledButton,
        'Aceitar Termos e Continuar',
      );
      expect(acceptButtonFinder, findsOneWidget);

      final FilledButton acceptButton = tester.widget(acceptButtonFinder);
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

      final FilledButton acceptButtonEnabled = tester.widget(
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

  testWidgets('TermsOfUsePage displays last updated date in the banner', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      createTestWidget(isUpdatingTerms: true, files: defaultFiles),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Data da atualização:'), findsOneWidget);
  });

  testWidgets(
    'TermsOfUsePage logs telemetry and opens modal on privacy policy link tap',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(isUpdatingTerms: false, files: defaultFiles),
      );
      await tester.pumpAndSettle();

      final telemetry = TelemetryService.instance as MockTelemetryService;
      telemetry.clear();

      final markdownWidget = tester.widget<MarkdownBody>(
        find.byType(MarkdownBody).first,
      );

      // Simula o clique no link da política de privacidade no Markdown
      markdownWidget.onTapLink!(
        'Política de Privacidade',
        '/politica-de-privacidade',
        'title',
      );
      await tester.pumpAndSettle();

      // Verifica se o modal abriu
      expect(
        find.text('Política de Privacidade', skipOffstage: false),
        findsWidgets,
      );

      // Verifica se a telemetria foi logada corretamente
      expect(telemetry.recordedEvents.contains('acao_configuracoes'), isTrue);
      expect(
        telemetry.recordedParams['acao_configuracoes']?['acao'],
        'abrir_politica_privacidade',
      );
    },
  );

  test('formatLegalDate correctly formats ISO dates', () {
    expect(formatLegalDate('2026-06-04'), '04 de Junho de 2026');
    expect(formatLegalDate('2025-12-31'), '31 de Dezembro de 2025');
    expect(formatLegalDate('invalid-date'), 'invalid-date'); // fallback
  });

  testWidgets(
    'TermsOfUsePage displays accepted timestamp banner when in read-only mode',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'accepted_legal_timestamp': '2026-06-07T21:50:00.000',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: TermsOfUsePage(
            onAccepted: () {},
            showAcceptButton: false, // Read-only mode
            assetBundle: MockAssetBundle(defaultFiles),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Aceito em 07 de Junho de 2026 às 21:50'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'TermsOfUsePage displays feedback button in the AppBar when in read-only mode',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TermsOfUsePage(
            onAccepted: () {},
            showAcceptButton: false, // AppBar só aparece no modo read-only
            assetBundle: MockAssetBundle(defaultFiles),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica se o ícone do botão de feedback existe na tela
      expect(find.byIcon(Icons.bug_report), findsOneWidget);
    },
  );

  testWidgets(
    'TermsOfUsePage displays feedback button in the Privacy Policy bottom sheet',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(isUpdatingTerms: false, files: defaultFiles),
      );
      await tester.pumpAndSettle();

      final markdownWidget = tester.widget<MarkdownBody>(
        find.byType(MarkdownBody).first,
      );
      markdownWidget.onTapLink!(
        'Política de Privacidade',
        '/politica-de-privacidade',
        'title',
      );
      await tester.pumpAndSettle();

      // Verifica se o modal abriu
      expect(
        find.text('Política de Privacidade', skipOffstage: false),
        findsWidgets,
      );

      // Verifica se o ícone do botão de feedback existe na AppBar do modal
      expect(find.byIcon(Icons.bug_report), findsOneWidget);
    },
  );
}
