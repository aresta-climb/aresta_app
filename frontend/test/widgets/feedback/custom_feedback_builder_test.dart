import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/feedback/custom_feedback_builder.dart';
import 'package:frontend/theme/app_colors.dart';

void main() {
  Widget buildTestWidget({required OnSubmit onSubmit}) {
    return MaterialApp(
      theme: ThemeData(
        extensions: const [AppColors.dark],
      ),
      home: Scaffold(
        body: BetterFeedback(
          child: Builder(
            builder: (context) {
              return customFeedbackBuilder(context, onSubmit, null);
            },
          ),
        ),
      ),
    );
  }

  testWidgets('customFeedbackBuilder renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget(onSubmit: (String text, {Map<String, dynamic>? extras}) async {}));

    expect(find.text('Qual o problema?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Enviar'), findsOneWidget);
  });

  testWidgets('Enviar button is disabled when text is empty', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget(onSubmit: (String text, {Map<String, dynamic>? extras}) async {}));

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.enabled, isFalse);
  });

  testWidgets('Enviar button is enabled when text is not empty and calls onSubmit', (WidgetTester tester) async {
    String? submittedText;
    await tester.pumpWidget(buildTestWidget(onSubmit: (String text, {Map<String, dynamic>? extras}) async {
      submittedText = text;
    }));

    await tester.enterText(find.byType(TextField), 'Test feedback');
    await tester.pumpAndSettle();

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.enabled, isTrue);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(submittedText, 'Test feedback');
  });
}
