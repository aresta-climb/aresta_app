import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/feedback/custom_feedback_builder.dart';

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
  });
}
