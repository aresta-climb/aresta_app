import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/feedback/custom_feedback_builder.dart';

void main() {
  group('CustomStringFeedback Widget Tests', () {
    testWidgets('renders correctly and contains expected elements', (WidgetTester tester) async {
      // Arrange
      String submittedText = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return customFeedbackBuilder(
                  context,
                  (text, {extras}) async {
                    submittedText = text;
                  },
                  null, // scrollController
                );
              },
            ),
          ),
        ),
      );

      // Act & Assert
      // Verify Title text is present
      expect(find.text('Qual o problema?'), findsOneWidget);

      // Verify TextField is present and has the correct hint
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      
      final TextField textField = tester.widget(textFieldFinder);
      expect(textField.decoration?.hintText, 'Descreva o problema ou sugestão...');

      // Verify submit button is present
      final buttonFinder = find.byKey(const Key('submit_feedback_button'));
      expect(buttonFinder, findsOneWidget);
      expect(find.descendant(of: buttonFinder, matching: find.text('Enviar')), findsOneWidget);

      // Simulate typing feedback
      await tester.enterText(textFieldFinder, 'Tive um problema no mapa');
      await tester.pump();

      // Tap the submit button
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      // Verify onSubmit callback was called with correct text
      expect(submittedText, 'Tive um problema no mapa');
    });

    testWidgets('adapts to dark mode styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          themeMode: ThemeMode.dark,
          theme: ThemeData(brightness: Brightness.light), // We set the opposite to ensure we're testing dark mode override
          darkTheme: ThemeData(brightness: Brightness.dark),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return customFeedbackBuilder(
                  context,
                  (text, {extras}) async {},
                  null,
                );
              },
            ),
          ),
        ),
      );

      // Verify it renders without errors in dark mode
      expect(find.text('Qual o problema?'), findsOneWidget);
    });
    testWidgets('adapts text field lines and padding based on keyboard visibility', (WidgetTester tester) async {
      // Helper function to build with specific MediaQuery
      Widget buildWithKeyboard(bool isVisible) {
        return MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(
                size: const Size(400, 800),
                viewInsets: isVisible ? const EdgeInsets.only(bottom: 300) : EdgeInsets.zero,
                viewPadding: const EdgeInsets.only(bottom: 34), // simulate safe area
              ),
              child: Builder(
                builder: (context) {
                  return customFeedbackBuilder(
                    context,
                    (text, {extras}) async {},
                    null,
                  );
                },
              ),
            ),
          ),
        );
      }

      // Test with keyboard closed
      await tester.pumpWidget(buildWithKeyboard(false));
      TextField textFieldClosed = tester.widget(find.byType(TextField));
      expect(textFieldClosed.minLines, 1);
      expect(textFieldClosed.maxLines, 2);

      SingleChildScrollView scrollClosed = tester.widget(find.byType(SingleChildScrollView));
      expect(scrollClosed.padding, const EdgeInsets.fromLTRB(16, 12, 16, 12));

      // Test with keyboard open
      await tester.pumpWidget(buildWithKeyboard(true));
      TextField textFieldOpen = tester.widget(find.byType(TextField));
      expect(textFieldOpen.minLines, 2);
      expect(textFieldOpen.maxLines, 3);

      SingleChildScrollView scrollOpen = tester.widget(find.byType(SingleChildScrollView));
      expect(scrollOpen.padding, const EdgeInsets.fromLTRB(16, 12, 16, 12));
    });
  });
}
